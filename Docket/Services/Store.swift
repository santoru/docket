// Store.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import Foundation
import SwiftUI
import os

/// Persistent task store backed by JSON files in Application Support.
@Observable
final class Store {
    static let shared = Store()

    /// Current on-disk data schema version. Bump when the persisted shape
    /// changes and add a corresponding migration step in `migrateIfNeeded()`.
    static let currentSchemaVersion = 1

    @ObservationIgnored private let logger = Logger(subsystem: "blog.insecurity.docket", category: "store")

    var items: [TodoItem] = []
    var lists: [TaskList] = []
    var labels: [TaskLabel] = []
    var activeListId: UUID
    var activeLabelFilter: UUID?

    private let dir: URL = {
        let d = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Docket", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }()

    private var tasksURL: URL { dir.appendingPathComponent("tasks.json") }
    private var listsURL: URL { dir.appendingPathComponent("lists.json") }
    private var labelsURL: URL { dir.appendingPathComponent("labels.json") }

    init() {
        activeListId = UUID()
        loadLists()
        loadLabels()
        loadTasks()
        // Invariant: there is always at least one list, and exactly one default.
        if lists.isEmpty {
            lists = [TaskList(name: "Default", isDefault: true)]
            saveLists()
        }
        let defaultId = lists.first(where: { $0.isDefault })?.id ?? lists[0].id
        // Reassign any task pointing at a nil or non-existent list.
        reassignOrphans()
        activeListId = UUID(uuidString: UserDefaults.standard.string(forKey: "activeListId") ?? "") ?? defaultId
        migrateIfNeeded()
    }

    // MARK: - Schema Migration

    /// Runs any pending data migrations and records the current schema version.
    /// Currently a no-op scaffold (we're at v1); future schema changes add
    /// sequential migration steps here.
    private func migrateIfNeeded() {
        let stored = UserDefaults.standard.object(forKey: "dataSchemaVersion") as? Int ?? 0
        guard stored < Store.currentSchemaVersion else { return }
        // switch stored {
        // case 0: migrateV0toV1(); fallthrough
        // default: break
        // }
        UserDefaults.standard.set(Store.currentSchemaVersion, forKey: "dataSchemaVersion")
        logger.info("Migrated data schema \(stored) → \(Store.currentSchemaVersion)")
    }

    // MARK: - Computed Views

    var activeList: TaskList {
        lists.first(where: { $0.id == activeListId })
            ?? lists.first
            ?? TaskList(name: "Default", isDefault: true)
    }

    var activeTasks: [TodoItem] {
        var tasks = items.filter { !$0.isCompleted && $0.listId == activeListId }
        if let labelId = activeLabelFilter {
            tasks = tasks.filter { $0.labelIds.contains(labelId) }
        }
        return tasks.sorted { $0.sortOrder < $1.sortOrder }
    }

    var completedTasks: [TodoItem] {
        items.filter { $0.isCompleted && $0.listId == activeListId }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    /// Number of tasks due today or overdue.
    var badgeCount: Int {
        let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!
        let allLists = UserDefaults.standard.bool(forKey: "badgeAllLists")
        return items.filter {
            !$0.isCompleted &&
            (allLists || $0.listId == activeListId) &&
            $0.dueDate != nil && $0.dueDate! <= endOfToday
        }.count
    }

    /// Tasks grouped by due date category for "By Due Date" sort mode.
    var groupedByDueDate: [(title: String, color: String, tasks: [TodoItem])] {
        var active = items.filter { !$0.isCompleted && $0.listId == activeListId }
        if let labelId = activeLabelFilter {
            active = active.filter { $0.labelIds.contains(labelId) }
        }
        let calendar = Calendar.current
        let now = Date()
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!

        let overdue = active.filter { $0.dueDate != nil && $0.dueDate! < now }.sorted { $0.dueDate! < $1.dueDate! }
        let today = active.filter { $0.dueDate != nil && $0.dueDate! >= now && $0.dueDate! < endOfToday }.sorted { $0.dueDate! < $1.dueDate! }
        let upcoming = active.filter { $0.dueDate != nil && $0.dueDate! >= endOfToday }.sorted { $0.dueDate! < $1.dueDate! }
        let noDate = active.filter { $0.dueDate == nil }.sorted { $0.sortOrder < $1.sortOrder }

        var groups: [(title: String, color: String, tasks: [TodoItem])] = []
        if !overdue.isEmpty { groups.append(("Overdue", "red", overdue)) }
        if !today.isEmpty { groups.append(("Today", "orange", today)) }
        if !upcoming.isEmpty { groups.append(("Upcoming", "blue", upcoming)) }
        if !noDate.isEmpty { groups.append(("No date", "gray", noDate)) }
        return groups
    }

    // MARK: - List Management

    func switchList(_ list: TaskList) {
        activeListId = list.id
        activeLabelFilter = nil
        UserDefaults.standard.set(list.id.uuidString, forKey: "activeListId")
    }

    // MARK: - Labels

    var labelsForActiveList: [TaskLabel] {
        labels.filter { $0.listId == activeListId }
    }

    func addLabel(name: String, colorHex: String, icon: String) {
        let label = TaskLabel(name: name, colorHex: colorHex, icon: icon, listId: activeListId)
        labels.append(label)
        saveLabels()
    }

    func updateLabel(_ label: TaskLabel) {
        guard let i = labels.firstIndex(where: { $0.id == label.id }) else { return }
        labels[i] = label
        saveLabels()
    }

    func deleteLabel(_ label: TaskLabel) {
        // Remove from all tasks
        for i in items.indices {
            items[i].labelIds.removeAll { $0 == label.id }
        }
        labels.removeAll { $0.id == label.id }
        if activeLabelFilter == label.id { activeLabelFilter = nil }
        saveLabels()
        saveTasks()
    }

    func addList(name: String) {
        let list = TaskList(name: name)
        lists.append(list)
        saveLists()
    }

    func renameList(_ list: TaskList, to name: String) {
        guard let i = lists.firstIndex(where: { $0.id == list.id }) else { return }
        lists[i].name = name
        saveLists()
    }

    func deleteList(_ list: TaskList) {
        guard !list.isDefault else { return }
        guard let defaultId = lists.first(where: { $0.isDefault })?.id else { return }
        // Move tasks to default
        for i in items.indices where items[i].listId == list.id {
            items[i].listId = defaultId
        }
        lists.removeAll { $0.id == list.id }
        if activeListId == list.id,
           let fallback = lists.first(where: { $0.isDefault }) ?? lists.first {
            switchList(fallback)
        }
        saveLists()
        saveTasks()
    }

    // MARK: - CRUD

    func add(_ item: TodoItem) {
        var newItem = item
        newItem.listId = activeListId
        newItem.sortOrder = (activeTasks.map(\.sortOrder).max() ?? -1) + 1
        items.append(newItem)
        saveTasks()
        NotificationManager.shared.scheduleReminder(for: newItem)
        syncPush(newItem)
    }

    func complete(_ item: TodoItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[i].completedAt = Date()
        NotificationManager.shared.cancelReminder(for: items[i])

        // Spawn next instance for recurring tasks
        if let recurrence = items[i].recurrence, let dueDate = items[i].dueDate,
           let nextDate = recurrence.nextDueDate(from: dueDate) {
            var next = items[i]
            next.id = UUID()
            next.createdAt = Date()
            next.completedAt = nil
            next.dueDate = nextDate
            next.reminderId = nil
            // Order the new instance at the end of *its own* list (which may
            // differ from the currently active list), not the active list.
            let siblings = items.filter { !$0.isCompleted && $0.listId == next.listId }
            next.sortOrder = (siblings.map(\.sortOrder).max() ?? -1) + 1
            items.append(next)
            NotificationManager.shared.scheduleReminder(for: next)
            syncPush(next)
        }

        syncPush(items[i])
        saveTasks()
    }

    func restore(_ item: TodoItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[i].completedAt = nil
        items[i].sortOrder = (activeTasks.map(\.sortOrder).max() ?? -1) + 1
        saveTasks()
        NotificationManager.shared.scheduleReminder(for: items[i])
        syncPush(items[i])
    }

    func update(_ item: TodoItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[i] = item
        saveTasks()
        NotificationManager.shared.scheduleReminder(for: item)
        syncPush(item)
    }

    func delete(_ item: TodoItem) {
        RemindersSync.shared.deleteReminder(for: item)
        items.removeAll { $0.id == item.id }
        saveTasks()
        NotificationManager.shared.cancelReminder(for: item)
    }

    // MARK: - Reorder

    func move(from source: IndexSet, to destination: Int) {
        var active = activeTasks
        active.move(fromOffsets: source, toOffset: destination)
        for (idx, task) in active.enumerated() {
            if let i = items.firstIndex(where: { $0.id == task.id }) {
                items[i].sortOrder = idx
            }
        }
        saveTasks()
    }

    func clearCompleted() {
        items.removeAll { $0.isCompleted && $0.listId == activeListId }
        saveTasks()
    }

    // MARK: - Persistence

    private func loadTasks() {
        guard FileManager.default.fileExists(atPath: tasksURL.path) else { return }
        do {
            let data = try Data(contentsOf: tasksURL)
            items = try JSONDecoder().decode([TodoItem].self, from: data)
        } catch {
            logger.error("Failed to load tasks: \(error.localizedDescription)")
        }
    }

    private func saveTasks() {
        do {
            try JSONEncoder().encode(items).write(to: tasksURL, options: .atomic)
        } catch {
            logger.error("Failed to save tasks: \(error.localizedDescription)")
        }
    }

    private func loadLists() {
        guard FileManager.default.fileExists(atPath: listsURL.path) else {
            lists = [TaskList(name: "Default", isDefault: true)]
            saveLists()
            return
        }
        do {
            let data = try Data(contentsOf: listsURL)
            let decoded = try JSONDecoder().decode([TaskList].self, from: data)
            if !decoded.isEmpty { lists = decoded }
        } catch {
            // Don't clobber the file — init() will recreate a default list if
            // this left `lists` empty, and the next successful save will persist.
            logger.error("Failed to load lists: \(error.localizedDescription)")
        }
    }

    private func saveLists() {
        do {
            try JSONEncoder().encode(lists).write(to: listsURL, options: .atomic)
        } catch {
            logger.error("Failed to save lists: \(error.localizedDescription)")
        }
    }

    /// Persist all data (tasks + lists). Call after direct item mutations.
    func persist() {
        saveTasks()
        saveLists()
    }

    /// Persist tasks, lists, and labels together. Use after bulk mutations
    /// such as import where all three collections may have changed.
    func persistAll() {
        saveTasks()
        saveLists()
        saveLabels()
    }

    /// Re-run the orphan-assignment pass: any task whose listId is nil or
    /// points to a list that no longer exists is moved to the default list.
    /// Mirrors the logic in `init()` but is safe to call at runtime (e.g.
    /// after an import). Returns true if any task was changed.
    @discardableResult
    func reassignOrphans() -> Bool {
        let validIds = Set(lists.map(\.id))
        let defaultId = lists.first(where: { $0.isDefault })?.id ?? lists[0].id
        var changed = false
        for i in items.indices where items[i].listId == nil || !validIds.contains(items[i].listId!) {
            items[i].listId = defaultId
            changed = true
        }
        return changed
    }

    /// Atomically mutate a single item by id and persist. Centralises the
    /// "find index → mutate → persist" pattern used by drag-driven views.
    /// No-op if the id isn't found.
    @discardableResult
    func mutate(_ id: UUID, _ mutator: (inout TodoItem) -> Void) -> Bool {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return false }
        mutator(&items[i])
        saveTasks()
        return true
    }

    private func loadLabels() {
        guard FileManager.default.fileExists(atPath: labelsURL.path) else { return }
        do {
            let data = try Data(contentsOf: labelsURL)
            labels = try JSONDecoder().decode([TaskLabel].self, from: data)
        } catch {
            logger.error("Failed to load labels: \(error.localizedDescription)")
        }
    }

    private func saveLabels() {
        do {
            try JSONEncoder().encode(labels).write(to: labelsURL, options: .atomic)
        } catch {
            logger.error("Failed to save labels: \(error.localizedDescription)")
        }
    }

    // MARK: - Reminders Sync

    private func syncPush(_ item: TodoItem) {
        guard UserDefaults.standard.bool(forKey: "remindersSyncEnabled") else { return }
        let list = lists.first(where: { $0.id == item.listId })
        RemindersSync.shared.pushTask(item, calendarId: list?.remindersCalendarId)
    }
}
