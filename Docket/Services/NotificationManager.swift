// NotificationManager.swift
// Docket — macOS Menu Bar Task Manager
// Created by @santoru

import Foundation
import UserNotifications

/// Manages scheduling and cancellation of task reminder notifications.
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func requestPermission() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error { print("⚠️ Notification auth error: \(error)") }
                if !granted { print("⚠️ Notification permission denied") }
            }
        }
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

        let soundPref = UserDefaults.standard.string(forKey: "notifSound") ?? "default"
        switch soundPref {
        case "none": content.sound = nil
        case "default": content.sound = .default
        default: content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(soundPref).aiff"))
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)
        center.add(request) { error in
            if let error { print("⚠️ Failed to schedule: \(error)") }
        }
    }

    func cancelReminder(for item: TodoItem) {
        center.removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
    }

    // MARK: - Delegate — show notifications even when app is in foreground

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
