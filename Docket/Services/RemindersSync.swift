// RemindersSync.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import Foundation
import os
import EventKit

/// Two-way sync between Docket and Apple Reminders via EventKit.
@Observable
final class RemindersSync {
    static let shared = RemindersSync()

    let store = EKEventStore()
    private let logger = Logger(subsystem: "blog.insecurity.docket", category: "reminders-sync")
    var isAuthorized = false
    var lastSyncDate: Date?

    private var changeObserver: Any?

    init() {
        checkAccess()
    }

    // MARK: - Access

    func checkAccess() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        isAuthorized = status == .fullAccess || status == .authorized
    }

    func requestAccess() async -> Bool {
        do {
            let granted = try await store.requestFullAccessToReminders()
            isAuthorized = granted
            return granted
        } catch {
            isAuthorized = false
            return false
        }
    }

    // MARK: - Calendars

    func availableCalendars() -> [EKCalendar] {
        guard isAuthorized else { return [] }
        return store.calendars(for: .reminder)
    }

    func findOrCreateDocketCalendar() -> EKCalendar? {
        return findOrCreateCalendar(named: "Docket")
    }

    func findOrCreateCalendar(named name: String) -> EKCalendar? {
        guard isAuthorized else { return nil }
        let calendars = store.calendars(for: .reminder)
        if let existing = calendars.first(where: { $0.title == name }) {
            return existing
        }
        let cal = EKCalendar(for: .reminder, eventStore: store)
        cal.title = name
        cal.source = store.defaultCalendarForNewReminders()?.source
        do {
            try store.saveCalendar(cal, commit: true)
            return cal
        } catch { return nil }
    }

    // MARK: - Push (Docket → Reminders)

    func pushTask(_ item: TodoItem, calendarId: String?) {
        guard isAuthorized, let calId = calendarId,
              let calendar = store.calendar(withIdentifier: calId) else { return }

        let reminder: EKReminder
        if let rid = item.reminderId, let existing = store.calendarItem(withIdentifier: rid) as? EKReminder {
            reminder = existing
        } else {
            reminder = EKReminder(eventStore: store)
            reminder.calendar = calendar
        }

        reminder.title = item.title
        reminder.notes = item.notes.isEmpty ? nil : item.notes
        reminder.priority = priorityToEK(item.priority)
        reminder.isCompleted = item.completedAt != nil
        reminder.completionDate = item.completedAt

        if let due = item.dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
        } else {
            reminder.dueDateComponents = nil
        }

        // Recurrence
        reminder.recurrenceRules?.forEach { reminder.removeRecurrenceRule($0) }
        if let rec = item.recurrence {
            let freq: EKRecurrenceFrequency = switch rec.frequency {
            case .daily: .daily
            case .weekly: .weekly
            case .monthly: .monthly
            }
            let rule = EKRecurrenceRule(recurrenceWith: freq, interval: rec.interval, end: rec.endDate.map { EKRecurrenceEnd(end: $0) })
            reminder.addRecurrenceRule(rule)
        }

        do {
            try store.save(reminder, commit: true)
            // Update Docket item with reminder ID
            if let i = Store.shared.items.firstIndex(where: { $0.id == item.id }) {
                Store.shared.items[i].reminderId = reminder.calendarItemIdentifier
                Store.shared.items[i].lastSyncedAt = Date()
                Store.shared.persist()
            }
        } catch { logger.error("Save reminder failed: \(error.localizedDescription)") }
    }

    func deleteReminder(for item: TodoItem) {
        guard isAuthorized, let rid = item.reminderId,
              let reminder = store.calendarItem(withIdentifier: rid) as? EKReminder else { return }
        try? store.remove(reminder, commit: true)
    }

    // MARK: - Pull (Reminders → Docket)

    func pullChanges(for syncedLists: [TaskList]) {
        guard isAuthorized else { return }

        for list in syncedLists {
            guard let calId = list.remindersCalendarId,
                  let calendar = store.calendar(withIdentifier: calId) else { continue }

            let predicate = store.predicateForReminders(in: [calendar])
            store.fetchReminders(matching: predicate) { reminders in
                DispatchQueue.main.async {
                    self.mergeReminders(reminders ?? [], into: list)
                    self.lastSyncDate = Date()
                }
            }
        }
    }

    private func mergeReminders(_ reminders: [EKReminder], into list: TaskList) {
        let docketStore = Store.shared

        for reminder in reminders {
            let rid = reminder.calendarItemIdentifier

            if let i = docketStore.items.firstIndex(where: { $0.reminderId == rid }) {
                // Existing — update if reminder is newer
                let local = docketStore.items[i]
                let remoteModified = reminder.lastModifiedDate ?? Date.distantPast
                let localSynced = local.lastSyncedAt ?? Date.distantPast

                if remoteModified > localSynced {
                    docketStore.items[i].title = reminder.title ?? local.title
                    docketStore.items[i].notes = reminder.notes ?? ""
                    docketStore.items[i].priority = priorityFromEK(reminder.priority)
                    docketStore.items[i].dueDate = reminder.dueDateComponents?.date
                    docketStore.items[i].completedAt = reminder.isCompleted ? (reminder.completionDate ?? Date()) : nil
                    docketStore.items[i].lastSyncedAt = Date()
                }
            } else {
                // New from Reminders — create in Docket
                var item = TodoItem(
                    title: reminder.title ?? "Untitled",
                    notes: reminder.notes ?? "",
                    priority: priorityFromEK(reminder.priority),
                    dueDate: reminder.dueDateComponents?.date,
                    listId: list.id
                )
                item.reminderId = rid
                item.lastSyncedAt = Date()
                item.completedAt = reminder.isCompleted ? (reminder.completionDate ?? Date()) : nil
                item.sortOrder = (docketStore.activeTasks.map(\.sortOrder).max() ?? -1) + 1
                docketStore.items.append(item)
            }
        }

        // Remove tasks whose reminders were deleted
        let reminderIds = Set(reminders.map(\.calendarItemIdentifier))
        docketStore.items.removeAll { item in
            item.listId == list.id && item.reminderId != nil && !reminderIds.contains(item.reminderId!)
        }

        docketStore.persist()
    }

    // MARK: - Observe Changes

    func startObserving() {
        changeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: store, queue: .main
        ) { [weak self] _ in
            let syncedLists = Store.shared.lists.filter { $0.remindersCalendarId != nil }
            self?.pullChanges(for: syncedLists)
        }
    }

    func stopObserving() {
        if let obs = changeObserver {
            NotificationCenter.default.removeObserver(obs)
            changeObserver = nil
        }
    }

    // MARK: - Full Sync

    func syncAll() {
        let docketStore = Store.shared
        let syncedLists = docketStore.lists.filter { $0.remindersCalendarId != nil }

        // Push all Docket tasks
        for list in syncedLists {
            let tasks = docketStore.items.filter { $0.listId == list.id }
            for task in tasks {
                pushTask(task, calendarId: list.remindersCalendarId)
            }
        }

        // Pull from Reminders
        pullChanges(for: syncedLists)
    }

    // MARK: - Helpers

    private func priorityToEK(_ p: Priority) -> Int {
        switch p { case .high: 1; case .medium: 5; case .low: 9 }
    }

    private func priorityFromEK(_ p: Int) -> Priority {
        switch p { case 1...4: .high; case 5...7: .medium; default: .low }
    }
}
