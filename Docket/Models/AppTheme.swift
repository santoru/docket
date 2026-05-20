// AppTheme.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import SwiftUI

// MARK: - AppTheme

/// Available color themes for the app UI.
enum AppTheme: Int, CaseIterable, Identifiable {
    case white = 0
    case lavender = 1
    case rose = 4
    case peach = 6
    case lemon = 8
    case mint = 5
    case sky = 10
    case periwinkle = 12
    case midnight = 2
    case custom = 99

    var id: Int { rawValue }

    /// Display order in the theme picker grid.
    static var allCases: [AppTheme] {
        [.white, .lavender, .rose, .peach, .lemon, .mint, .sky, .periwinkle, .midnight, .custom]
    }

    var name: String {
        switch self {
        case .white: "White"
        case .lavender: "Lavender"
        case .rose: "Rose"
        case .peach: "Peach"
        case .lemon: "Lemon"
        case .mint: "Mint"
        case .sky: "Sky"
        case .periwinkle: "Periwinkle"
        case .midnight: "Night"
        case .custom: "Custom"
        }
    }

    var background: Color {
        switch self {
        case .white:      .white
        case .lavender:   Color(red: 0.91, green: 0.87, blue: 1.00)
        case .rose:       Color(red: 1.00, green: 0.89, blue: 0.92)
        case .peach:      Color(red: 1.00, green: 0.91, blue: 0.84)
        case .lemon:      Color(red: 1.00, green: 0.98, blue: 0.84)
        case .mint:       Color(red: 0.86, green: 0.97, blue: 0.93)
        case .sky:        Color(red: 0.87, green: 0.94, blue: 1.00)
        case .periwinkle: Color(red: 0.88, green: 0.89, blue: 1.00)
        case .midnight:   Color(red: 0.08, green: 0.08, blue: 0.14)
        case .custom:     .white
        }
    }

    var cardBackground: Color {
        switch self {
        case .midnight: Color(red: 0.14, green: 0.14, blue: 0.22)
        default:        .white.opacity(0.65)
        }
    }

    var isDark: Bool { self == .midnight }

    var accent: Color {
        switch self {
        case .white:      .blue
        case .lavender:   Color(red: 0.55, green: 0.35, blue: 0.90)
        case .rose:       Color(red: 0.85, green: 0.30, blue: 0.45)
        case .peach:      Color(red: 0.90, green: 0.50, blue: 0.25)
        case .lemon:      Color(red: 0.75, green: 0.60, blue: 0.00)
        case .mint:       Color(red: 0.15, green: 0.65, blue: 0.50)
        case .sky:        Color(red: 0.20, green: 0.55, blue: 0.85)
        case .periwinkle: Color(red: 0.40, green: 0.40, blue: 0.85)
        case .midnight:   Color(red: 0.45, green: 0.65, blue: 1.00)
        case .custom:     .blue
        }
    }

    var swatchColor: Color { background }
}

// MARK: - ThemeManager

/// Resolves theme values accounting for the custom theme's user-defined colors.
struct ThemeManager {
    static func resolvedBackground(themeRaw: Int, customHue: Double, customSat: Double) -> Color {
        let theme = AppTheme(rawValue: themeRaw) ?? .white
        if theme == .custom {
            return Color(hue: customHue, saturation: customSat, brightness: 0.95)
        }
        return theme.background
    }

    static func resolvedCardBackground(themeRaw: Int) -> Color {
        let theme = AppTheme(rawValue: themeRaw) ?? .white
        if theme == .custom { return .white.opacity(0.65) }
        return theme.cardBackground
    }

    static func resolvedIsDark(themeRaw: Int) -> Bool {
        (AppTheme(rawValue: themeRaw) ?? .white).isDark
    }

    static func resolvedAccent(themeRaw: Int, customHue: Double) -> Color {
        let theme = AppTheme(rawValue: themeRaw) ?? .white
        if theme == .custom {
            return Color(hue: customHue, saturation: 0.7, brightness: 0.65)
        }
        return theme.accent
    }
}
