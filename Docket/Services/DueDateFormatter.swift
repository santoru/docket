// DueDateFormatter.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import Foundation

/// Formats due dates as friendly relative labels: "Today 3pm", "Tomorrow", "Yesterday", etc.
struct DueDateFormatter {
    static func format(_ date: Date) -> String {
        let calendar = Calendar.current
        let timeStr = date.formatted(date: .omitted, time: .shortened)

        if calendar.isDateInToday(date) {
            return L10n.todayAt(timeStr)
        }
        if calendar.isDateInTomorrow(date) {
            return L10n.tomorrowAt(timeStr)
        }
        if calendar.isDateInYesterday(date) {
            return L10n.yesterdayAt(timeStr)
        }

        // Within this week: "Friday 3:00 PM"
        let daysAway = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: date)).day ?? 0
        if daysAway > 0 && daysAway < 7 {
            let dayName = date.formatted(.dateTime.weekday(.wide))
            return "\(dayName) \(timeStr)"
        }

        // Fallback: "May 25, 3:00 PM"
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
