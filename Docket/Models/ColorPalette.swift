// ColorPalette.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI
import AppKit

/// A curated, accessibility-tuned palette shared by Labels and Lists.
///
/// Each entry is a single mid-tone hue (Tailwind 500-tier) chosen to remain
/// readable both as a solid foreground (text/icon) and as a low-opacity fill
/// (chip background) on every app theme — including the pale Lavender / Rose /
/// Peach / Lemon / Mint / Sky / Periwinkle backgrounds and the Midnight dark
/// theme.
///
/// 5 columns × 4 rows = 20 colors. Two neutrals (Slate, Stone) cover
/// "low priority" categories; one anchor dark (Graphite) gives high contrast
/// for important labels.
enum ColorPalette {
    /// Display-ordered preset list. The grid in `ColorPickerGrid` lays these
    /// out as 5 columns × 4 rows, so the order here drives visual grouping.
    static let presets: [(name: String, hex: String)] = [
        // Row 1 — warm reds & oranges
        ("Rose",     "#F43F5E"),
        ("Red",      "#EF4444"),
        ("Orange",   "#F97316"),
        ("Amber",    "#F59E0B"),
        ("Yellow",   "#EAB308"),

        // Row 2 — greens
        ("Lime",     "#84CC16"),
        ("Green",    "#22C55E"),
        ("Emerald",  "#10B981"),
        ("Teal",     "#14B8A6"),
        ("Cyan",     "#06B6D4"),

        // Row 3 — blues & purples
        ("Sky",      "#0EA5E9"),
        ("Blue",     "#3B82F6"),
        ("Indigo",   "#6366F1"),
        ("Violet",   "#8B5CF6"),
        ("Purple",   "#A855F7"),

        // Row 4 — pinks & neutrals
        ("Fuchsia",  "#D946EF"),
        ("Pink",     "#EC4899"),
        ("Slate",    "#64748B"),
        ("Stone",    "#78716C"),
        ("Graphite", "#374151"),
    ]

    /// Default starting color for a new label / list (Indigo — middle of the palette).
    static let defaultHex = "#6366F1"

    /// Returns a deterministic palette color derived from a string key. Used as
    /// a fallback for legacy `TaskList` records that have no stored color, so
    /// no list ever appears "uncolored" in the UI.
    static func deterministic(for key: String) -> String {
        // `String.hashValue` is unstable across launches in Swift, so we use a
        // small custom FNV-1a hash to keep the same list mapped to the same color.
        var h: UInt64 = 1469598103934665603 // FNV-1a offset basis
        for byte in key.utf8 {
            h ^= UInt64(byte)
            h = h &* 1099511628211 // FNV-1a prime
        }
        let idx = Int(h % UInt64(presets.count))
        return presets[idx].hex
    }
}

// MARK: - Color ↔ hex

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

    /// "#RRGGBB" sRGB representation. Returns nil if conversion fails (e.g.
    /// when the underlying NSColor cannot be expressed in sRGB).
    func toHex() -> String? {
        guard let ns = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        let r = Int((max(0, min(1, Double(ns.redComponent))) * 255).rounded())
        let g = Int((max(0, min(1, Double(ns.greenComponent))) * 255).rounded())
        let b = Int((max(0, min(1, Double(ns.blueComponent))) * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    /// Returns a lightened variant of this color when the current theme is dark,
    /// ensuring label pills remain readable against dark backgrounds.
    func adaptedForCurrentScheme(themeRaw: Int) -> Color {
        let isDark = ThemeManager.resolvedIsDark(themeRaw: themeRaw)
        guard isDark, let ns = NSColor(self).usingColorSpace(.sRGB) else { return self }
        let r = Double(ns.redComponent)
        let g = Double(ns.greenComponent)
        let b = Double(ns.blueComponent)
        // Perceived luminance (ITU-R BT.601)
        let lum = 0.299 * r + 0.587 * g + 0.114 * b
        // If already bright enough, keep as-is
        if lum > 0.45 { return self }
        // Lighten by mixing toward white
        let factor = 0.55
        return Color(
            red: r + (1 - r) * factor,
            green: g + (1 - g) * factor,
            blue: b + (1 - b) * factor
        )
    }
}
