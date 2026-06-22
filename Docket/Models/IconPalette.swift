// IconPalette.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import Foundation

/// The curated set of SF Symbols available in the label icon picker.
///
/// Mirrors `ColorPalette` so the icon picker has a single source of truth and
/// the two pickers stay symmetric. Adding/removing icons is a one-line change
/// here.
enum IconPalette {
    /// Display-ordered preset list. `IconPickerGrid` lays these out as 5
    /// columns × 3 rows.
    static let presets: [String] = [
        "tag", "briefcase", "person", "bolt", "star",
        "heart", "house", "book", "cart", "gamecontroller",
        "airplane", "leaf", "music.note", "camera", "gift",
    ]

    /// Default icon assigned to a new label.
    static let defaultIcon = "tag"

    /// Localized human-friendly display name for an SF Symbol in our preset
    /// list. Used by tooltips, popover headers, and VoiceOver. Falls back to
    /// the raw symbol name for any value not in `presets` (defensive — the
    /// picker only renders preset symbols, so this is hit only if a stored
    /// icon falls outside the curated set).
    static func displayName(_ icon: String) -> String {
        switch icon {
        case "tag":             return L10n.iconTag
        case "briefcase":       return L10n.iconBriefcase
        case "person":          return L10n.iconPerson
        case "bolt":            return L10n.iconBolt
        case "star":            return L10n.iconStar
        case "heart":           return L10n.iconHeart
        case "house":           return L10n.iconHouse
        case "book":            return L10n.iconBook
        case "cart":            return L10n.iconCart
        case "gamecontroller":  return L10n.iconGameController
        case "airplane":        return L10n.iconAirplane
        case "leaf":            return L10n.iconLeaf
        case "music.note":      return L10n.iconMusicNote
        case "camera":          return L10n.iconCamera
        case "gift":            return L10n.iconGift
        default:                return icon
        }
    }
}
