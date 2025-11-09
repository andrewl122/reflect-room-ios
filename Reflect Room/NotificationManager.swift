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
                content.body = moodBasedMessage(for: lastMood, atHour: hour)
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

    // MARK: - Dynamic message generator
    private func moodBasedMessage(for mood: String?, atHour hour: Int) -> String {
        guard let mood = mood?.lowercased() else {
            return hour < 12
                ? "Good morning ☀️ Take a moment to set your intention for the day."
                : "How did today make you feel? Take a moment to reflect 🌙"
        }

        let morningPrompts: [String]
        let eveningPrompts: [String]

        switch mood {
        case "happy":
            morningPrompts = [
                "You’ve been radiating joy lately — let’s keep that energy alive today.",
                "Start your day with gratitude — you’re carrying light energy ☀️",
                "Your last reflection was bright — what’s one thing you’re excited for today?"
            ]
            eveningPrompts = [
                "You’ve been glowing with positivity — what made you smile today?",
                "End your day with gratitude — joy thrives when noticed 🌙",
                "Happiness leaves clues — reflect on what fueled yours today."
            ]

        case "sad":
            morningPrompts = [
                "Gentle start today. It’s okay to take things slow ☁️",
                "Be kind to yourself this morning — healing isn’t linear.",
                "Try journaling one comforting thought to start your day."
            ]
            eveningPrompts = [
                "You’ve been carrying some weight — let reflection lighten it tonight.",
                "Sadness is a teacher too — what did it try to show you today?",
                "You’ve shown up again. That’s strength, not weakness 💙"
            ]

        case "anxious":
            morningPrompts = [
                "Take a grounding breath. You’ve got this 🌿",
                "Start your day calm — a small reflection can steady your thoughts.",
                "Anxiety fades when you name what you feel. Try it this morning."
            ]
            eveningPrompts = [
                "Let go of the ‘what ifs’ before bed — you did enough today 🌙",
                "Breathe out tension and acknowledge your effort today.",
                "Peace begins in awareness — reflect gently tonight."
            ]

        case "okay":
            morningPrompts = [
                "You’ve been steady lately — that’s quiet strength.",
                "Start today balanced — what would make it feel just a bit better?",
                "Even small wins matter — what’s one thing you’re looking forward to?"
            ]
            eveningPrompts = [
                "You’ve had a grounded day — celebrate that calm.",
                "Balance is powerful. Reflect on what helped you stay centered.",
                "Not every day needs highs or lows — peace counts too 🌙"
            ]

        case "angry":
            morningPrompts = [
                "Anger is energy — channel it into clarity today 🔥",
                "Start your morning with a deep breath — peace is power.",
                "You’ve been feeling intense emotions — write before they write you."
            ]
            eveningPrompts = [
                "Let go of what burned you today — tomorrow is a reset.",
                "Anger held too long becomes heavy. Reflect and release tonight.",
                "You’ve made space for big feelings — that’s emotional courage 🌙"
            ]

        default:
            morningPrompts = [
                "Take a breath and center yourself before the day begins.",
                "Good morning ☀️ — what intention will you carry today?",
                "Every day is a blank page — write gently."
            ]
            eveningPrompts = [
                "Pause and notice your day before it fades into tomorrow.",
                "You showed up — that’s worth reflecting on.",
                "End your day with compassion — you’ve done your best 🌙"
            ]
        }

        return hour < 12
            ? (morningPrompts.randomElement() ?? "")
            : (eveningPrompts.randomElement() ?? "")
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

            if let latest = try? context.fetch(fetchRequest).first,
               let mood = latest.mood?.lowercased() {

                switch mood {
                case "happy":
                    bodyText = [
                        "You’ve been glowing lately ✨ — what brought you joy today?",
                        "Keep nurturing that light energy ☀️ — gratitude fuels your happiness.",
                        "Take a second to celebrate the little wins that made you smile."
                    ].randomElement() ?? bodyText

                case "sad":
                    bodyText = [
                        "Be gentle with yourself 💙 — reflection can help lighten the load.",
                        "You’ve been processing a lot. Write what your heart wants to say.",
                        "Even quiet sadness deserves space. Breathe, then write softly."
                    ].randomElement() ?? bodyText

                case "anxious":
                    bodyText = [
                        "Take a deep breath 🌿 — reflection can help calm the storm.",
                        "You’ve been in your thoughts lately. Let writing bring you peace.",
                        "Anxiety fades when named — what’s weighing on your mind today?"
                    ].randomElement() ?? bodyText

                case "okay":
                    bodyText = [
                        "Steady energy is strength 🌤️ — reflect on what’s keeping you grounded.",
                        "You’ve been balanced lately — what small thing added peace today?",
                        "Even calm days deserve attention. Take a moment to capture it."
                    ].randomElement() ?? bodyText

                case "angry":
                    bodyText = [
                        "Big feelings mean big growth 🔥 — reflection helps you release them.",
                        "Turn frustration into focus — write to find clarity.",
                        "Anger carries truth. What is it trying to teach you today?"
                    ].randomElement() ?? bodyText

                default:
                    bodyText = [
                        "Take a mindful moment to reflect on your day.",
                        "How are you feeling right now? Write it out, no filter.",
                        "Your thoughts matter — take a moment to check in with yourself 🪞"
                    ].randomElement() ?? bodyText
                }
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
