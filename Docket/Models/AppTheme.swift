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
        case .white: L10n.themeWhite
        case .lavender: L10n.themeLavender
        case .rose: L10n.themeRose
        case .peach: L10n.themePeach
        case .lemon: L10n.themeLemon
        case .mint: L10n.themeMint
        case .sky: L10n.themeSky
        case .periwinkle: L10n.themePeriwinkle
        case .midnight: L10n.themeNight
        case .custom: L10n.themeCustom
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
        default:
            if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return Color(red: 0.16, green: 0.16, blue: 0.18)
            }
            return .white.opacity(0.65)
        }
    }

    var isDark: Bool {
        if self == .midnight { return true }
        // Respect macOS system dark mode for non-midnight themes
        return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

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
        let systemDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        if theme == .custom {
            let brightness: Double = systemDark ? 0.15 : 0.95
            return Color(hue: customHue, saturation: customSat, brightness: brightness)
        }
        if systemDark && theme != .midnight {
            return Color(red: 0.10, green: 0.10, blue: 0.12)
        }
        return theme.background
    }

    static func resolvedCardBackground(themeRaw: Int) -> Color {
        let theme = AppTheme(rawValue: themeRaw) ?? .white
        let systemDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        if theme == .custom {
            return systemDark ? Color(red: 0.16, green: 0.16, blue: 0.18) : .white.opacity(0.65)
        }
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
