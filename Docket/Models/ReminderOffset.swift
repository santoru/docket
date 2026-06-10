// ReminderOffset.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import Foundation

/// How far in advance to fire a reminder notification.
enum ReminderOffset: Int, Codable, CaseIterable, Identifiable {
    case none = 0
    case atTime = 1
    case fiveMinutes = 2
    case tenMinutes = 3
    case thirtyMinutes = 4
    case oneHour = 5
    case oneDay = 6

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .none: L10n.reminderNone
        case .atTime: L10n.reminderAtTime
        case .fiveMinutes: L10n.reminder5
        case .tenMinutes: L10n.reminder10
        case .thirtyMinutes: L10n.reminder30
        case .oneHour: L10n.reminder1Hour
        case .oneDay: L10n.reminder1Day
        }
    }

    var timeInterval: TimeInterval {
        switch self {
        case .none: 0
        case .atTime: 0
        case .fiveMinutes: 5 * 60
        case .tenMinutes: 10 * 60
        case .thirtyMinutes: 30 * 60
        case .oneHour: 60 * 60
        case .oneDay: 24 * 60 * 60
        }
    }
}
