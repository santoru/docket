// NotificationManager.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import Foundation
import UserNotifications

/// Manages scheduling and cancellation of task reminder notifications.
final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleReminder(for item: TodoItem) {
        cancelReminder(for: item)

        guard let dueDate = item.dueDate,
              item.reminderOffset != .none,
              item.completedAt == nil else { return }

        let fireDate = dueDate.addingTimeInterval(-item.reminderOffset.timeInterval)
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Docket"
        content.body = item.reminderOffset == .atTime
            ? "\(item.title) — due now"
            : "\(item.title) — due in \(item.reminderOffset.displayName.replacingOccurrences(of: " before", with: ""))"
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelReminder(for item: TodoItem) {
        center.removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
    }
}
