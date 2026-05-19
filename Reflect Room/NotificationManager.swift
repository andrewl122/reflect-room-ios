//
//  NotificationManager.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 11/9/25.
//

import Foundation
import UserNotifications
import CoreData

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: - Request permission and schedule
    func requestPermissionAndScheduleDefaults(context: NSManagedObjectContext) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("❌ Notification permission error: \(error.localizedDescription)")
                }
                if granted {
                    print("✅ Permission granted — scheduling mood-based reminders.")
                    self.scheduleMoodBasedReminders(context: context)
                } else {
                    print("🚫 User denied notifications.")
                }
            }
    }

    func scheduleMoodBasedReminders(context: NSManagedObjectContext) {
        cancelReminders()

        let times = [
            (hour: 9, minute: 0, title: "Morning Reflection ☀️"),
            (hour: 20, minute: 0, title: "Evening Wind-Down 🌙")
        ]

        // Fetch most recent mood and timestamp
        let fetchRequest: NSFetchRequest<ReflectionEntry> = ReflectionEntry.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ReflectionEntry.timestamp, ascending: false)]
        fetchRequest.fetchLimit = 1

        var lastMood: String? = nil
        var daysSinceLast: Int = 0

        do {
            if let latest = try context.fetch(fetchRequest).first,
               let date = latest.timestamp {
                lastMood = latest.mood
                let diff = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
                daysSinceLast = diff
            }
        } catch {
            print("⚠️ Could not fetch last mood: \(error.localizedDescription)")
        }

        for (hour, minute, title) in times {
            let content = UNMutableNotificationContent()
            content.title = title

            // 🧠 Choose message based on both mood and inactivity
            if daysSinceLast >= 3 {
                content.body = hour < 12
                    ? "It’s been a few days since your last check-in ☀️ Take a mindful minute today."
                    : "We haven’t seen a reflection in a bit 🌙. How are you holding up tonight?"
            } else {
                content.body = MoodType.notificationMessage(storedValue: lastMood, isMorning: hour < 12)
            }

            content.sound = .default
            content.badge = NSNumber(value: 1)

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "reflect_room_\(hour)_\(minute)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule reminder at \(hour):\(minute): \(error.localizedDescription)")
                } else {
                    print("✅ Scheduled reminder at \(hour):\(minute) — mood: \(lastMood ?? "None"), days since: \(daysSinceLast)")
                }
            }
        }
    }


    // MARK: - Cancel reminders
    func cancelReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("🧹 Cleared all scheduled reminders.")
    }

    // MARK: - Custom Reminder Scheduler (Mood-Aware)
    func scheduleCustomReminder(at date: Date,
                                title: String = "Reflect Room Reminder 🪞",
                                context: NSManagedObjectContext? = nil) {
        cancelReminders()

        let content = UNMutableNotificationContent()
        content.title = title
        content.sound = .default

        // 🧩 Try to personalize message based on last recorded mood
        var bodyText = "Take a mindful moment to reflect on your day."

        if let context = context {
            let fetchRequest: NSFetchRequest<ReflectionEntry> = ReflectionEntry.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ReflectionEntry.timestamp, ascending: false)]
            fetchRequest.fetchLimit = 1

            if let latest = try? context.fetch(fetchRequest).first {
                let hour = Calendar.current.component(.hour, from: date)
                bodyText = MoodType.notificationMessage(storedValue: latest.mood, isMorning: hour < 12)
            }
        }

        content.body = bodyText

        // ⏰ Build trigger
        let triggerDate = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)

        let request = UNNotificationRequest(
            identifier: "reflect_room_custom_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling custom reminder: \(error.localizedDescription)")
            } else {
                print("✅ Custom mood-based reminder scheduled for \(triggerDate.hour ?? 0):\(triggerDate.minute ?? 0)")
            }
        }
    }



}
