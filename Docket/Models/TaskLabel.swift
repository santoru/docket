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

    init(name: String, colorHex: String = ColorPalette.defaultHex, icon: String = "tag", listId: UUID) {
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
    /// Sourced from the shared `ColorPalette` so Labels and Lists use the same
    /// curated set.
    static var presetColors: [(name: String, hex: String)] { ColorPalette.presets }

    /// Preset icons for the label icon picker.
    static let presetIcons = [
        "tag", "briefcase", "person", "bolt", "star",
        "heart", "house", "book", "cart", "gamecontroller",
        "airplane", "leaf", "music.note", "camera", "gift",
    ]
}

// MARK: - Color Hex Extension

extension Color {
    /// Initialize from a hex string. Accepts `#RGB`, `#RGBA`, `#RRGGBB`, and
    /// `#RRGGBBAA` (the leading `#` is optional). On malformed input it falls
    /// back to a neutral gray rather than silently producing black.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            .uppercased()

        // Reject anything that isn't valid hex of a supported length.
        let isHex = cleaned.allSatisfy { $0.isHexDigit }
        guard isHex, [3, 4, 6, 8].contains(cleaned.count) else {
            self = Color(red: 0.6, green: 0.6, blue: 0.6) // fallback gray
            return
        }

        // Expand shorthand (#RGB / #RGBA) to full form.
        let full: String
        if cleaned.count == 3 || cleaned.count == 4 {
            full = cleaned.map { "\($0)\($0)" }.joined()
        } else {
            full = cleaned
        }

        var value: UInt64 = 0
        guard Scanner(string: full).scanHexInt64(&value) else {
            self = Color(red: 0.6, green: 0.6, blue: 0.6)
            return
        }

        let r, g, b, a: Double
        if full.count == 8 {
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        } else {
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1.0
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
