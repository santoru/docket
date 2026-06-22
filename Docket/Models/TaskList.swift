// TaskList.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import Foundation
import SwiftUI

/// A named list/project that groups tasks.
struct TaskList: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var createdAt: Date
    var isDefault: Bool
    var remindersCalendarId: String?
    /// Optional user-chosen color. Optional so that legacy `lists.json` files
    /// (written before list colors existed) decode without migration.
    /// Use the computed `color` property to render — it falls back to a
    /// deterministic palette color when this is nil.
    var colorHex: String?

    init(name: String,
         isDefault: Bool = false,
         remindersCalendarId: String? = nil,
         colorHex: String? = nil) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.isDefault = isDefault
        self.remindersCalendarId = remindersCalendarId
        self.colorHex = colorHex
    }

    /// Resolved color for rendering. If `colorHex` is set it wins; otherwise we
    /// derive a stable color from the list's id (so the same list always gets
    /// the same fallback) drawing from the shared `ColorPalette`.
    var color: Color {
        Color(hex: resolvedHex)
    }

    /// The hex string used to render `color`. Exposed so callers (e.g. the
    /// color picker) can show the resolved fallback as the current selection
    /// when the user hasn't picked one yet.
    var resolvedHex: String {
        if let stored = colorHex, !stored.isEmpty { return stored }
        return ColorPalette.deterministic(for: id.uuidString)
    }
}

/// Export format containing all lists, labels, and tasks.
struct DocketExport: Codable {
    /// Optional so older exports (without the field) still import cleanly.
    var schemaVersion: Int?
    let lists: [TaskList]
    let labels: [TaskLabel]
    let tasks: [TodoItem]
}
