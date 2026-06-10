// TodoItem.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

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

    /// Pastel color used consistently across task cards, the priority picker,
    /// and the matrix pills. Centralized here so the three call sites can't drift.
    var color: Color {
        switch self {
        case .low:    Color(red: 0.45, green: 0.72, blue: 0.95)
        case .medium: Color(red: 0.95, green: 0.75, blue: 0.40)
        case .high:   Color(red: 0.95, green: 0.50, blue: 0.55)
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
    var reminderId: String?
    var lastSyncedAt: Date?
    var quadrant: Quadrant?
    var matrixX: Double?
    var matrixY: Double?

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
        case reminderId, lastSyncedAt, quadrant, matrixX, matrixY
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
        reminderId = try c.decodeIfPresent(String.self, forKey: .reminderId)
        lastSyncedAt = try c.decodeIfPresent(Date.self, forKey: .lastSyncedAt)
        quadrant = try c.decodeIfPresent(Quadrant.self, forKey: .quadrant)
        matrixX = try c.decodeIfPresent(Double.self, forKey: .matrixX)
        matrixY = try c.decodeIfPresent(Double.self, forKey: .matrixY)
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
        self.reminderId = nil
        self.lastSyncedAt = nil
        self.quadrant = nil
        self.matrixX = nil
        self.matrixY = nil
    }
}
