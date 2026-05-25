// TaskList.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import Foundation

/// A named list/project that groups tasks.
struct TaskList: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var createdAt: Date
    var isDefault: Bool
    var remindersCalendarId: String?

    init(name: String, isDefault: Bool = false, remindersCalendarId: String? = nil) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.isDefault = isDefault
        self.remindersCalendarId = remindersCalendarId
    }
}

/// Export format containing all lists, labels, and tasks.
struct DocketExport: Codable {
    let lists: [TaskList]
    let labels: [TaskLabel]
    let tasks: [TodoItem]
}
