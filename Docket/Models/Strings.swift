// Strings.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import Foundation

/// Centralized localizable strings for the app.
enum L10n {
    // MARK: - General
    static let appName = NSLocalizedString("app.name", value: "Docket", comment: "App name")
    static let save = NSLocalizedString("action.save", value: "Save", comment: "Save button")
    static let back = NSLocalizedString("action.back", value: "Back", comment: "Back button")
    static let delete = NSLocalizedString("action.delete", value: "Delete Task", comment: "Delete task button")
    static let restore = NSLocalizedString("action.restore", value: "Restore", comment: "Restore completed task")

    // MARK: - Task List
    static let allClear = NSLocalizedString("list.empty", value: "All clear!", comment: "Empty task list")
    static let noResults = NSLocalizedString("list.noResults", value: "No results", comment: "Empty search results")
    static let searchPlaceholder = NSLocalizedString("list.search", value: "Search tasks...", comment: "Search placeholder")
    static func taskCount(_ count: Int) -> String {
        String(format: NSLocalizedString("list.taskCount", value: "%d tasks", comment: "Task count"), count)
    }
    static let oneTask = NSLocalizedString("list.oneTask", value: "1 task", comment: "Single task count")

    // MARK: - Create/Edit
    static let newTask = NSLocalizedString("create.title", value: "New Task", comment: "Create task title")
    static let editTask = NSLocalizedString("edit.title", value: "Edit Task", comment: "Edit task title")
    static let titlePlaceholder = NSLocalizedString("field.title", value: "What needs to be done?", comment: "Title placeholder")
    static let notesPlaceholder = NSLocalizedString("field.notes", value: "Details...", comment: "Notes placeholder")
    static let priority = NSLocalizedString("field.priority", value: "Priority", comment: "Priority label")
    static let dueDate = NSLocalizedString("field.dueDate", value: "Due date", comment: "Due date toggle")
    static let remindMe = NSLocalizedString("field.remindMe", value: "Remind me", comment: "Reminder picker label")
    static let time = NSLocalizedString("field.time", value: "Time", comment: "Time picker label")
    static let smartDatePlaceholder = NSLocalizedString("field.smartDate", value: "e.g. tomorrow 3pm, next friday", comment: "Natural date placeholder")

    // MARK: - Completed
    static let completed = NSLocalizedString("completed.title", value: "Completed", comment: "Completed view title")
    static let nothingHere = NSLocalizedString("completed.empty", value: "Nothing here yet", comment: "Empty completed list")

    // MARK: - Settings
    static let settings = NSLocalizedString("settings.title", value: "Settings", comment: "Settings title")
    static let defaultReminder = NSLocalizedString("settings.defaultReminder", value: "Default reminder", comment: "Default reminder setting")
    static let launchAtLogin = NSLocalizedString("settings.launchAtLogin", value: "Launch at login", comment: "Launch at login toggle")
    static let globalShortcut = NSLocalizedString("settings.globalShortcut", value: "Global shortcut", comment: "Hotkey toggle")
    static let shortcut = NSLocalizedString("settings.shortcut", value: "Shortcut", comment: "Shortcut picker label")
    static let clearCompleted = NSLocalizedString("settings.clearCompleted", value: "Clear completed", comment: "Clear completed button")
    static let theme = NSLocalizedString("settings.theme", value: "Theme", comment: "Theme section")
    static let color = NSLocalizedString("settings.color", value: "Color", comment: "Custom color label")
    static let intensity = NSLocalizedString("settings.intensity", value: "Intensity", comment: "Custom intensity label")
    static let exportTasks = NSLocalizedString("settings.export", value: "Export tasks", comment: "Export button")
    static let importTasks = NSLocalizedString("settings.import", value: "Import tasks", comment: "Import button")

    // MARK: - Sort
    static let custom = NSLocalizedString("sort.custom", value: "Custom", comment: "Custom sort mode")
    static let byDueDate = NSLocalizedString("sort.byDueDate", value: "By Due Date", comment: "Due date sort mode")
    static let overdue = NSLocalizedString("sort.overdue", value: "Overdue", comment: "Overdue section")
    static let today = NSLocalizedString("sort.today", value: "Today", comment: "Today section")
    static let upcoming = NSLocalizedString("sort.upcoming", value: "Upcoming", comment: "Upcoming section")
    static let noDate = NSLocalizedString("sort.noDate", value: "No date", comment: "No date section")

    // MARK: - Undo
    static let taskCompleted = NSLocalizedString("undo.completed", value: "Task completed", comment: "Undo toast for complete")
    static let taskDeleted = NSLocalizedString("undo.deleted", value: "Task deleted", comment: "Undo toast for delete")
    static let undo = NSLocalizedString("undo.action", value: "Undo", comment: "Undo button")

    // MARK: - Onboarding
    static let welcome = NSLocalizedString("onboarding.welcome", value: "Welcome to Docket", comment: "Onboarding title")
    static let subtitle = NSLocalizedString("onboarding.subtitle", value: "Your tasks, one click away", comment: "Onboarding subtitle")
    static let getStarted = NSLocalizedString("onboarding.getStarted", value: "Get Started", comment: "Onboarding button")

    // MARK: - Due Date Formatting
    static func todayAt(_ time: String) -> String {
        String(format: NSLocalizedString("due.today", value: "Today %@", comment: "Due today with time"), time)
    }
    static func tomorrowAt(_ time: String) -> String {
        String(format: NSLocalizedString("due.tomorrow", value: "Tomorrow %@", comment: "Due tomorrow with time"), time)
    }
    static func yesterdayAt(_ time: String) -> String {
        String(format: NSLocalizedString("due.yesterday", value: "Yesterday %@", comment: "Due yesterday"), time)
    }
}
