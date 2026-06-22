// Strings.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import Foundation

/// Centralized localizable strings for the app. Every user-facing string flows
/// through here so it can be translated via the `en`/`it` Localizable.strings
/// tables bundled in Contents/Resources.
enum L10n {
    private static func s(_ key: String, _ value: String) -> String {
        NSLocalizedString(key, value: value, comment: "")
    }

    // MARK: - General
    static let appName = s("app.name", "Docket")
    static let save = s("action.save", "Save")
    static let cancel = s("action.cancel", "Cancel")
    static let done = s("action.done", "Done")
    static let back = s("action.back", "Back")
    static let delete = s("action.delete", "Delete")
    static let edit = s("action.edit", "Edit")
    static let rename = s("action.rename", "Rename")
    static let deleteTask = s("action.deleteTask", "Delete Task")
    static let restore = s("action.restore", "Restore")

    // MARK: - Task List
    static let allClear = s("list.empty", "All clear!")
    static let addFirstTask = s("list.addFirst", "Add your first task")
    static let noResults = s("list.noResults", "No results")
    static func noResultsDetail(_ query: String) -> String {
        String(format: s("list.noResultsDetail", "No tasks match “%@”"), query)
    }
    static let searchPlaceholder = s("list.search", "Search tasks...")
    static func taskCount(_ count: Int) -> String {
        String(format: s("list.taskCount", "%d tasks"), count)
    }
    static let oneTask = s("list.oneTask", "1 task")
    static let switchedToCustom = s("list.switchedToCustom", "Switched to Custom order")

    // MARK: - Sort & Groups
    static let sortCustom = s("sort.custom", "Custom")
    static let sortByDueDate = s("sort.byDueDate", "By Due Date")
    static let sortByPriority = s("sort.byPriority", "By Priority")
    static let overdue = s("group.overdue", "Overdue")
    static let today = s("group.today", "Today")
    static let upcoming = s("group.upcoming", "Upcoming")
    static let noDate = s("group.noDate", "No date")
    static let priorityHigh = s("priority.high", "High")
    static let priorityMedium = s("priority.medium", "Medium")
    static let priorityLow = s("priority.low", "Low")

    // MARK: - Create / Edit
    static let newTask = s("create.title", "New Task")
    static let editTask = s("edit.title", "Edit Task")
    static let addTask = s("create.add", "Add Task")
    static let titlePlaceholder = s("field.title", "What needs to be done?")
    static let titleFieldPlaceholder = s("field.titleEdit", "Title")
    static let notesPlaceholder = s("field.notes", "Add notes...")
    static let priority = s("field.priority", "Priority")
    static let labels = s("field.labels", "Labels")
    static let noLabels = s("field.noLabels", "No labels yet")
    static let matrix = s("field.matrix", "Matrix")
    static let dueDate = s("field.dueDate", "Due date")
    static let remindMe = s("field.remindMe", "Remind me")
    static let time = s("field.time", "Time")
    static let repeatLabel = s("field.repeat", "Repeat")
    static let every = s("field.every", "Every")
    static let smartDatePlaceholder = s("field.smartDate", "tomorrow 3pm, next friday...")
    static let list = s("field.list", "List")
    static let created = s("field.created", "Created")

    // MARK: - Completed
    static let completed = s("completed.title", "Completed")
    static let nothingHere = s("completed.empty", "Nothing here yet")

    // MARK: - Settings (group headers)
    static let groupGeneral = s("settings.group.general", "GENERAL")
    static let groupAppearance = s("settings.group.appearance", "APPEARANCE")
    static let groupNotifications = s("settings.group.notifications", "NOTIFICATIONS")
    static let groupOrganize = s("settings.group.organize", "ORGANIZE")
    static let groupSyncData = s("settings.group.syncData", "SYNC & DATA")

    // MARK: - Settings (rows)
    static let settings = s("settings.title", "Settings")
    static let launchAtLogin = s("settings.launchAtLogin", "Launch at login")
    static let multiLineTasks = s("settings.multiLine", "Multi-line tasks")
    static let keyboard = s("settings.keyboard", "Keyboard")
    static let globalShortcut = s("settings.globalShortcut", "Global shortcut")
    static let shortcut = s("settings.shortcut", "Shortcut")
    static let theme = s("settings.theme", "Theme")
    static let color = s("settings.color", "Color")
    static let colorCustom = s("settings.color.custom", "Custom…")
    static let intensity = s("settings.intensity", "Intensity")
    static let display = s("settings.display", "Display")
    static let liquidGlass = s("settings.liquidGlass", "Liquid Glass")
    static let completionConfetti = s("settings.confetti", "Completion confetti")
    static let showInToolbar = s("settings.showInToolbar", "Show in toolbar")
    static let matrixButton = s("settings.matrixButton", "Matrix button")
    static let completedButton = s("settings.completedButton", "Completed button")
    static let defaultReminder = s("settings.defaultReminder", "Default reminder")
    static let sound = s("settings.sound", "Sound")
    static let soundDefault = s("settings.sound.default", "Default")
    static let soundNone = s("settings.sound.none", "None")
    static let badgeCounts = s("settings.badgeCounts", "Badge counts")
    static let currentList = s("settings.currentList", "Current list")
    static let allLists = s("settings.allLists", "All lists")
    static let remindersSync = s("settings.remindersSync", "Reminders Sync")
    static let syncWithReminders = s("settings.syncWithReminders", "Sync with Reminders")
    static let noRemindersAccess = s("settings.noRemindersAccess", "No access to Reminders")
    static let listsToSync = s("settings.listsToSync", "Lists to sync")
    static let syncNow = s("settings.syncNow", "Sync Now")
    static let lastSync = s("settings.lastSync", "Last sync:")
    static let lists = s("settings.lists", "Lists")
    static let namePlaceholder = s("field.name", "Name")
    static let newList = s("lists.new", "New List")
    static let newLabel = s("labels.new", "New Label")
    static let data = s("settings.data", "Data")
    static let exportButton = s("settings.export", "Export")
    static let importButton = s("settings.import", "Import")
    static let clearCompleted = s("settings.clearCompleted", "Clear completed")
    static let eisenhowerMatrix = s("settings.eisenhower", "Eisenhower Matrix")
    static let labelLength = s("settings.labelLength", "Label length")
    static let labelLines = s("settings.labelLines", "Label lines")
    static let showAxisLabels = s("settings.showAxisLabels", "Show axis labels")
    static let showCountBadges = s("settings.showCountBadges", "Show count badges")
    static func charsCount(_ n: Int) -> String {
        String(format: s("settings.chars", "%d chars"), n)
    }

    // MARK: - Alerts
    static let deleteListTitle = s("alert.deleteList.title", "Delete List")
    static func deleteListMessage(_ name: String, _ count: Int) -> String {
        let fmt = count == 1
            ? s("alert.deleteList.messageOne", "“%@” has %d task. It will be moved to the default list.")
            : s("alert.deleteList.messageMany", "“%@” has %d tasks. They will be moved to the default list.")
        return String(format: fmt, name, count)
    }
    static let deleteLabelTitle = s("alert.deleteLabel.title", "Delete Label")
    static func deleteLabelMessage(_ name: String, _ count: Int) -> String {
        let fmt = count == 1
            ? s("alert.deleteLabel.messageOne", "“%@” is used by %d task. The label will be removed from it.")
            : count == 0
                ? s("alert.deleteLabel.messageZero", "Delete the label “%@”? This cannot be undone.")
                : s("alert.deleteLabel.messageMany", "“%@” is used by %d tasks. The label will be removed from them.")
        return String(format: fmt, name, count)
    }
    static let clearCompletedTitle = s("alert.clearCompleted.title", "Clear Completed")
    static let clearCompletedMessage = s("alert.clearCompleted.message", "This will permanently delete all completed tasks.")
    static func clearNTasks(_ n: Int) -> String {
        String(format: s("alert.clearN", "Clear %d tasks"), n)
    }

    // MARK: - Undo
    static let taskCompleted = s("undo.completed", "Task completed")
    static let taskDeleted = s("undo.deleted", "Task deleted")
    static let undo = s("undo.action", "Undo")

    // MARK: - Swipe / Reorder / Accessibility
    static let swipeDone = s("swipe.done", "Done")
    static let swipeDelete = s("swipe.delete", "Delete")
    static let moveUp = s("a11y.moveUp", "Move up")
    static let moveDown = s("a11y.moveDown", "Move down")
    static func completeTask(_ title: String) -> String {
        String(format: s("a11y.complete", "Complete %@"), title)
    }
    static let a11ySortOptions = s("a11y.sortOptions", "Sort options")
    static let a11yHideSortOptions = s("a11y.hideSortOptions", "Hide sort options")
    static let a11ySearch = s("a11y.search", "Search")
    static let a11yCompletedTasks = s("a11y.completedTasks", "Completed tasks")
    static let a11yNewTask = s("a11y.newTask", "New task")

    // MARK: - Matrix
    static let axisUrgent = s("matrix.urgent", "URGENT")
    static let axisNotUrgent = s("matrix.notUrgent", "NOT URGENT")
    static let axisImportant = s("matrix.important", "IMPORTANT")
    static let axisNot = s("matrix.not", "NOT")
    static let unassigned = s("matrix.unassigned", "UNASSIGNED")
    static let dropTasksHere = s("matrix.dropHere", "Drop tasks here")
    static let dropToRemove = s("matrix.dropToRemove", "Drop here to remove from the matrix")

    // MARK: - Onboarding
    static let welcome = s("onboarding.welcome", "Welcome to Docket")
    static let subtitle = s("onboarding.subtitle", "Your tasks, one click away")
    static let getStarted = s("onboarding.getStarted", "Get Started")
    static let tipSwipe = s("onboarding.tip.swipe", "Swipe")
    static let tipSwipeDesc = s("onboarding.tip.swipeDesc", "Right to complete, left to delete")
    static let tipReorder = s("onboarding.tip.reorder", "Reorder")
    static let tipReorderDesc = s("onboarding.tip.reorderDesc", "Press and hold a task, then drag it")
    static let tipShortcut = s("onboarding.tip.shortcut", "Shortcut")
    static let tipShortcutDesc = s("onboarding.tip.shortcutDesc", "⌘⇧D opens Docket from anywhere")
    static let tipSmartDates = s("onboarding.tip.smartDates", "Smart Dates")
    static let tipSmartDatesDesc = s("onboarding.tip.smartDatesDesc", "Type “tomorrow 3pm” for due dates")
    static let tipLabels = s("onboarding.tip.labels", "Labels")
    static let tipLabelsDesc = s("onboarding.tip.labelsDesc", "Color-coded labels to organize tasks")
    static let tipLists = s("onboarding.tip.lists", "Lists")
    static let tipListsDesc = s("onboarding.tip.listsDesc", "Separate projects in Settings")

    // MARK: - Models (display names)
    static let reminderNone = s("reminder.none", "No reminder")
    static let reminderAtTime = s("reminder.atTime", "At due time")
    static let reminder5 = s("reminder.5min", "5 minutes before")
    static let reminder10 = s("reminder.10min", "10 minutes before")
    static let reminder30 = s("reminder.30min", "30 minutes before")
    static let reminder1Hour = s("reminder.1hour", "1 hour before")
    static let reminder1Day = s("reminder.1day", "1 day before")

    static let freqDaily = s("freq.daily", "Daily")
    static let freqWeekly = s("freq.weekly", "Weekly")
    static let freqMonthly = s("freq.monthly", "Monthly")
    static let unitDay = s("unit.day", "day")
    static let unitWeek = s("unit.week", "week")
    static let unitMonth = s("unit.month", "month")
    static let unitDays = s("unit.days", "days")
    static let unitWeeks = s("unit.weeks", "weeks")
    static let unitMonths = s("unit.months", "months")
    /// "Every N days/weeks/months" shown on recurring task cards.
    static func everyInterval(_ n: Int, _ unitPlural: String) -> String {
        String(format: s("recurrence.everyN", "Every %d %@"), n, unitPlural)
    }

    static let themeWhite = s("theme.white", "White")
    static let themeLavender = s("theme.lavender", "Lavender")
    static let themeRose = s("theme.rose", "Rose")
    static let themePeach = s("theme.peach", "Peach")
    static let themeLemon = s("theme.lemon", "Lemon")
    static let themeMint = s("theme.mint", "Mint")
    static let themeSky = s("theme.sky", "Sky")
    static let themePeriwinkle = s("theme.periwinkle", "Periwinkle")
    static let themeNight = s("theme.night", "Night")
    static let themeCustom = s("theme.custom", "Custom")

    // MARK: - Menu Bar & Notifications
    static func menuOverdue(_ n: Int) -> String {
        String(format: s("menu.overdue", "⚠️ %d Overdue"), n)
    }
    static func menuDueToday(_ n: Int) -> String {
        String(format: s("menu.dueToday", "%d due today"), n)
    }
    static let menuQuit = s("menu.quit", "Quit Docket")
    static func notifDueNow(_ title: String) -> String {
        String(format: s("notif.dueNow", "%@ — due now"), title)
    }
    static func notifReminder(_ title: String, _ offset: String) -> String {
        String(format: s("notif.reminder", "%@ — %@"), title, offset)
    }

    // MARK: - Due Date Formatting
    static func todayAt(_ time: String) -> String {
        String(format: s("due.today", "Today %@"), time)
    }
    static func tomorrowAt(_ time: String) -> String {
        String(format: s("due.tomorrow", "Tomorrow %@"), time)
    }
    static func yesterdayAt(_ time: String) -> String {
        String(format: s("due.yesterday", "Yesterday %@"), time)
    }
}
