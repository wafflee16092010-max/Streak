// Streak/Streak/NotificationManager.swift

import Foundation
import UserNotifications

/// Schedules local reminders for study tasks.
final class NotificationManager {

    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Reminders

    /// Schedules a reminder for the exact time set on the task.
    func scheduleTaskReminder(task: TaskItem, on date: Date) {
        guard let reminderTime = task.reminderTime, reminderTime > Date() else {
            cancelReminder(taskID: task.id)
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Напоминание"
        content.body = task.title
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                          from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: task.id.uuidString,
                                            content: content,
                                            trigger: trigger)
        center.add(request)
    }

    func cancelReminder(taskID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [taskID.uuidString])
    }
}
