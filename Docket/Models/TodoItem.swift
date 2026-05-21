// TodoItem.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import Foundation

// MARK: - Priority

enum Priority: Int, Codable, CaseIterable, Identifiable {
    case low = 0, medium = 1, high = 2

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }
}

// MARK: - TodoItem

struct TodoItem: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var notes: String
    var createdAt: Date
    var completedAt: Date?
    var priorityRaw: Int
    var dueDate: Date?
    var reminderOffsetRaw: Int
    var sortOrder: Int
    var listId: UUID?
    var labelIds: [UUID]
    var recurrence: Recurrence?

    // MARK: Computed Properties

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    var reminderOffset: ReminderOffset {
        get { ReminderOffset(rawValue: reminderOffsetRaw) ?? .tenMinutes }
        set { reminderOffsetRaw = newValue.rawValue }
    }

    var isCompleted: Bool { completedAt != nil }

    var isOverdue: Bool {
        guard let due = dueDate, completedAt == nil else { return false }
        return due < Date()
    }

    // MARK: Codable (backward-compatible)

    enum CodingKeys: String, CodingKey {
        case id, title, notes, createdAt, completedAt
        case priorityRaw, dueDate, reminderOffsetRaw, sortOrder, listId, labelIds, recurrence
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        notes = try c.decode(String.self, forKey: .notes)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        completedAt = try c.decodeIfPresent(Date.self, forKey: .completedAt)
        priorityRaw = try c.decode(Int.self, forKey: .priorityRaw)
        dueDate = try c.decodeIfPresent(Date.self, forKey: .dueDate)
        reminderOffsetRaw = try c.decode(Int.self, forKey: .reminderOffsetRaw)
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        listId = try c.decodeIfPresent(UUID.self, forKey: .listId)
        labelIds = try c.decodeIfPresent([UUID].self, forKey: .labelIds) ?? []
        recurrence = try c.decodeIfPresent(Recurrence.self, forKey: .recurrence)
    }

    // MARK: Init

    init(
        title: String,
        notes: String = "",
        priority: Priority = .medium,
        dueDate: Date? = nil,
        reminderOffset: ReminderOffset = .tenMinutes,
        listId: UUID? = nil,
        labelIds: [UUID] = [],
        recurrence: Recurrence? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.createdAt = Date()
        self.completedAt = nil
        self.priorityRaw = priority.rawValue
        self.dueDate = dueDate
        self.reminderOffsetRaw = reminderOffset.rawValue
        self.sortOrder = 0
        self.listId = listId
        self.labelIds = labelIds
        self.recurrence = recurrence
    }
}
