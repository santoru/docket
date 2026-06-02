// Store.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import Foundation
import SwiftUI

/// Persistent task store backed by JSON files in Application Support.
@Observable
final class Store {
    static let shared = Store()
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
        // Assign orphan tasks (no listId) to default list
        let defaultId = lists.first(where: { $0.isDefault })?.id ?? lists.first!.id
        for i in items.indices where items[i].listId == nil {
            items[i].listId = defaultId
        }
        activeListId = UUID(uuidString: UserDefaults.standard.string(forKey: "activeListId") ?? "") ?? defaultId
    }

    // MARK: - Computed Views

    var activeList: TaskList { lists.first(where: { $0.id == activeListId }) ?? lists[0] }

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
        let defaultId = lists.first(where: { $0.isDefault })!.id
        // Move tasks to default
        for i in items.indices where items[i].listId == list.id {
            items[i].listId = defaultId
        }
        lists.removeAll { $0.id == list.id }
        if activeListId == list.id { switchList(lists[0]) }
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
            next.sortOrder = (activeTasks.map(\.sortOrder).max() ?? -1) + 1
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
        guard let data = try? Data(contentsOf: tasksURL) else { return }
        items = (try? JSONDecoder().decode([TodoItem].self, from: data)) ?? []
    }

    private func saveTasks() {
        try? JSONEncoder().encode(items).write(to: tasksURL, options: .atomic)
    }

    private func loadLists() {
        if let data = try? Data(contentsOf: listsURL),
           let decoded = try? JSONDecoder().decode([TaskList].self, from: data), !decoded.isEmpty {
            lists = decoded
        } else {
            lists = [TaskList(name: "Default", isDefault: true)]
            saveLists()
        }
    }

    private func saveLists() {
        try? JSONEncoder().encode(lists).write(to: listsURL, options: .atomic)
    }

    /// Persist all data (tasks + lists). Call after direct item mutations.
    func persist() {
        saveTasks()
        saveLists()
    }

    private func loadLabels() {
        guard let data = try? Data(contentsOf: labelsURL) else { return }
        labels = (try? JSONDecoder().decode([TaskLabel].self, from: data)) ?? []
    }

    private func saveLabels() {
        try? JSONEncoder().encode(labels).write(to: labelsURL, options: .atomic)
    }

    // MARK: - Reminders Sync

    private func syncPush(_ item: TodoItem) {
        guard UserDefaults.standard.bool(forKey: "remindersSyncEnabled") else { return }
        let list = lists.first(where: { $0.id == item.listId })
        RemindersSync.shared.pushTask(item, calendarId: list?.remindersCalendarId)
    }
}
