// TaskLabel.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

/// A colored label that can be attached to tasks.
struct TaskLabel: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var colorHex: String
    var icon: String
    var listId: UUID

    init(name: String,
         colorHex: String = ColorPalette.defaultHex,
         icon: String = IconPalette.defaultIcon,
         listId: UUID) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.listId = listId
    }

    var color: Color {
        Color(hex: colorHex)
    }

    /// Preset colors for the label color picker.
    /// Sourced from the shared `ColorPalette` so Labels and Lists use the
    /// same curated set.
    static var presetColors: [(name: String, hex: String)] { ColorPalette.presets }

    /// Preset icons available in the icon picker. Forwards to `IconPalette`
    /// so existing call sites keep working without coupling them to the
    /// palette type directly.
    static var presetIcons: [String] { IconPalette.presets }

    /// Default icon assigned to a fresh label.
    static var defaultIcon: String { IconPalette.defaultIcon }
}
