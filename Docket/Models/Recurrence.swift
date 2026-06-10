// Recurrence.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import Foundation

/// How often a task repeats.
enum Frequency: Int, Codable, CaseIterable, Identifiable {
    case daily = 0
    case weekly = 1
    case monthly = 2

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .daily: L10n.freqDaily
        case .weekly: L10n.freqWeekly
        case .monthly: L10n.freqMonthly
        }
    }

    var unit: String {
        switch self {
        case .daily: L10n.unitDay
        case .weekly: L10n.unitWeek
        case .monthly: L10n.unitMonth
        }
    }

    var unitPlural: String {
        switch self {
        case .daily: L10n.unitDays
        case .weekly: L10n.unitWeeks
        case .monthly: L10n.unitMonths
        }
    }
}

/// Recurrence configuration for a task.
struct Recurrence: Codable, Hashable {
    var frequency: Frequency
    var interval: Int
    var endDate: Date?

    /// Calculate the next due date from a given date.
    func nextDueDate(from date: Date) -> Date? {
        let calendar = Calendar.current
        let next: Date?
        switch frequency {
        case .daily:   next = calendar.date(byAdding: .day, value: interval, to: date)
        case .weekly:  next = calendar.date(byAdding: .day, value: 7 * interval, to: date)
        case .monthly: next = calendar.date(byAdding: .month, value: interval, to: date)
        }
        if let end = endDate, let n = next, n > end { return nil }
        return next
    }
}
