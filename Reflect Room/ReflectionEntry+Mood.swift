//
//  ReflectionEntry+Mood.swift
//  Reflect Room
//
//  Bridges Core Data mood strings to MoodType.
//

import Foundation
import CoreData

extension ReflectionEntry {

    /// Typed mood for this entry, including legacy stored values.
    var moodType: MoodType? {
        MoodType(storedValue: mood)
    }

    /// Display label for UI (title when known, otherwise stored string).
    var moodDisplayTitle: String {
        moodType?.title ?? mood ?? "Unknown Mood"
    }

    /// Emoji for UI lists and detail headers.
    var moodDisplayIcon: String {
        moodType?.icon ?? "🪞"
    }
}
