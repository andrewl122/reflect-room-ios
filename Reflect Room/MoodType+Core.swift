//
//  MoodType+Core.swift
//  Reflect Room
//
//  Single source of truth for parsing, scoring, and legacy mood strings.
//

import Foundation

// MARK: - Persistence & legacy parsing

extension MoodType {

    /// Values stored in Core Data before the 9-mood system.
    private static let legacyAliases: [String: MoodType] = [
        "okay": .neutral,
        "angry": .stressed
    ]

    /// Parses a persisted mood string (raw value, title, or legacy alias).
    init?(storedValue: String?) {
        guard let raw = storedValue?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else {
            return nil
        }

        let key = raw.lowercased()

        if let exact = MoodType(rawValue: key) {
            self = exact
            return
        }

        if let legacy = Self.legacyAliases[key] {
            self = legacy
            return
        }

        if let byTitle = MoodType.allCases.first(where: { $0.title.lowercased() == key }) {
            self = byTitle
            return
        }

        return nil
    }

    /// Canonical value written to Core Data (always lowercase rawValue).
    var storageValue: String { rawValue }

    /// Normalizes any stored mood string to the canonical raw value, if recognized.
    static func normalizedStorageValue(_ storedValue: String?) -> String? {
        MoodType(storedValue: storedValue)?.storageValue
    }
}

// MARK: - Analytics

extension MoodType {

    /// Numeric score used for charts and averages (1.5 … 5.0).
    var analyticsScore: Double {
        switch self {
        case .happy: return 5.0
        case .peaceful: return 4.5
        case .grateful: return 4.2
        case .neutral: return 3.0
        case .reflective: return 3.5
        case .sad: return 2.0
        case .stressed: return 1.8
        case .anxious: return 1.5
        case .tired: return 2.5
        }
    }

    /// User-facing explanation for info alerts in insights / stats.
    static var analyticsScoreLegend: String {
        """
        Each mood maps to a numeric score for trends and averages:

        \(MoodType.happy.icon) Happy = 5.0
        \(MoodType.peaceful.icon) Peaceful = 4.5
        \(MoodType.grateful.icon) Grateful = 4.2
        \(MoodType.reflective.icon) Reflective = 3.5
        \(MoodType.neutral.icon) Neutral = 3.0
        \(MoodType.tired.icon) Tired = 2.5
        \(MoodType.sad.icon) Sad = 2.0
        \(MoodType.stressed.icon) Stressed = 1.8
        \(MoodType.anxious.icon) Anxious = 1.5

        Older entries labeled Okay or Angry are counted as Neutral and Stressed.
        """
    }
}

// MARK: - Notifications

extension MoodType {

    /// Body copy for scheduled reminders, based on time of day.
    func notificationMessage(isMorning: Bool) -> String {
        let morning: [String]
        let evening: [String]

        switch self {
        case .happy:
            morning = [
                "You’ve been radiating joy lately — let’s keep that energy alive today.",
                "Start your day with gratitude — you’re carrying light energy ☀️",
                "Your last reflection was bright — what’s one thing you’re excited for today?"
            ]
            evening = [
                "You’ve been glowing with positivity — what made you smile today?",
                "End your day with gratitude — joy thrives when noticed 🌙",
                "Happiness leaves clues — reflect on what fueled yours today."
            ]

        case .peaceful:
            morning = [
                "Carry yesterday’s calm into this morning 🌿",
                "Start softly — what helps you feel grounded today?",
                "Your last check-in was peaceful — notice what’s still working."
            ]
            evening = [
                "What helped you feel calm today?",
                "End the day by naming one quiet moment of peace 🌙",
                "Stillness counts — reflect on what eased your mind."
            ]

        case .grateful:
            morning = [
                "Begin with one thing you’re grateful for ☀️",
                "Gratitude sets the tone — what are you thankful for today?",
                "Your last reflection held appreciation — build on it this morning."
            ]
            evening = [
                "What are you grateful for before the day ends?",
                "Name one person or moment that mattered today 🙏",
                "Gratitude grows when noticed — capture it tonight."
            ]

        case .neutral:
            morning = [
                "You’ve been steady lately — that’s quiet strength.",
                "Start today balanced — what would make it feel just a bit better?",
                "Even small wins matter — what’s one thing you’re looking forward to?"
            ]
            evening = [
                "You’ve had a grounded day — celebrate that calm.",
                "Balance is powerful. Reflect on what helped you stay centered.",
                "Not every day needs highs or lows — peace counts too 🌙"
            ]

        case .reflective:
            morning = [
                "Take a thoughtful pause before the day unfolds 🤔",
                "What question do you want to explore today?",
                "Your last reflection went deep — what thread still feels alive?"
            ]
            evening = [
                "What insight showed up for you today?",
                "Reflect on what you learned about yourself 🌙",
                "Depth over speed — write what’s still on your mind."
            ]

        case .sad:
            morning = [
                "Gentle start today. It’s okay to take things slow ☁️",
                "Be kind to yourself this morning — healing isn’t linear.",
                "Try journaling one comforting thought to start your day."
            ]
            evening = [
                "You’ve been carrying some weight — let reflection lighten it tonight.",
                "Sadness is a teacher too — what did it try to show you today?",
                "You’ve shown up again. That’s strength, not weakness 💙"
            ]

        case .stressed:
            morning = [
                "Stress is energy — channel it into one small clear step today.",
                "Start your morning with a deep breath — peace is power.",
                "You’ve been feeling tension — write before it writes you."
            ]
            evening = [
                "Let go of what burned you today — tomorrow is a reset.",
                "Tension held too long becomes heavy. Reflect and release tonight.",
                "You made space for big feelings — that’s emotional courage 🌙"
            ]

        case .anxious:
            morning = [
                "Take a grounding breath. You’ve got this 🌿",
                "Start your day calm — a small reflection can steady your thoughts.",
                "Anxiety fades when you name what you feel. Try it this morning."
            ]
            evening = [
                "Let go of the ‘what ifs’ before bed — you did enough today 🌙",
                "Breathe out tension and acknowledge your effort today.",
                "Peace begins in awareness — reflect gently tonight."
            ]

        case .tired:
            morning = [
                "You’re low on energy — be gentle with your pace today 😴",
                "Rest is productive too — what would feel nourishing this morning?",
                "Start small — one honest sentence is enough."
            ]
            evening = [
                "Honor your fatigue — what drained you today?",
                "Before sleep, note one thing you can release 🌙",
                "Tired doesn’t mean failing — reflect without judgment."
            ]
        }

        let pool = isMorning ? morning : evening
        return pool.randomElement() ?? MoodType.defaultNotificationMessage(isMorning: isMorning)
    }

    static func defaultNotificationMessage(isMorning: Bool) -> String {
        isMorning
            ? "Good morning ☀️ Take a moment to set your intention for the day."
            : "How did today make you feel? Take a moment to reflect 🌙"
    }

    /// Resolves a stored mood string for notification scheduling.
    static func notificationMessage(storedValue: String?, isMorning: Bool) -> String {
        guard let mood = MoodType(storedValue: storedValue) else {
            return defaultNotificationMessage(isMorning: isMorning)
        }
        return mood.notificationMessage(isMorning: isMorning)
    }
}
