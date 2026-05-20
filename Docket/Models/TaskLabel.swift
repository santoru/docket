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

    init(name: String, colorHex: String = "#6B7BFF", icon: String = "tag", listId: UUID) {
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
    static let presetColors: [(name: String, hex: String)] = [
        ("Red", "#FF6B6B"),
        ("Orange", "#FFA94D"),
        ("Yellow", "#FFD43B"),
        ("Green", "#51CF66"),
        ("Teal", "#38D9A9"),
        ("Blue", "#6B7BFF"),
        ("Purple", "#B197FC"),
        ("Pink", "#F06595"),
    ]

    /// Preset icons for the label icon picker.
    static let presetIcons = [
        "tag", "briefcase", "person", "bolt", "star",
        "heart", "house", "book", "cart", "gamecontroller",
        "airplane", "leaf", "music.note", "camera", "gift",
    ]
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
