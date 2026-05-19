//
//  ReflectionEntry+Analytics.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 11/2/25.
//

import Foundation
import CoreData

// MARK: - Reflection Analytics Extension
extension ReflectionEntry {

    // MARK: Mood Score Helper
    static func moodScore(for moodString: String) -> Double {
        MoodType(storedValue: moodString)?.analyticsScore ?? MoodType.neutral.analyticsScore
    }

    static func moodScore(for entry: ReflectionEntry) -> Double {
        entry.moodType?.analyticsScore ?? MoodType.neutral.analyticsScore
    }

    /// Most frequent mood in the dataset (canonical raw values).
    static func dominantMoodType(from entries: [ReflectionEntry]) -> MoodType? {
        let types = entries.compactMap(\.moodType)
        guard !types.isEmpty else { return nil }
        let counts = Dictionary(grouping: types, by: { $0 }).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }

    // MARK: - Current Streak
    static func currentStreak(from entries: [ReflectionEntry]) -> Int {
        let sorted = entries.compactMap { $0.timestamp }.sorted(by: >)
        guard let latest = sorted.first else { return 0 }

        let daysSinceLast = Calendar.current.dateComponents([.day], from: latest, to: Date()).day ?? 0
        guard daysSinceLast <= 1 else { return 0 }

        var streak = 1
        var previous = latest

        for date in sorted.dropFirst() {
            let diff = Calendar.current.dateComponents([.day], from: date, to: previous).day ?? 0
            if diff == 1 {
                streak += 1
                previous = date
            } else if diff > 1 {
                break
            }
        }

        return streak
    }

    // MARK: - Longest Streak
    static func longestStreak(from entries: [ReflectionEntry]) -> Int {
        let calendar = Calendar.current
        let uniqueDays = Set(entries.compactMap {
            calendar.startOfDay(for: $0.timestamp ?? Date.distantPast)
        })

        let sortedDays = uniqueDays.sorted(by: <)
        guard !sortedDays.isEmpty else { return 0 }

        var longest = 1
        var current = 1

        for i in 1..<sortedDays.count {
            let diff = calendar.dateComponents([.day], from: sortedDays[i - 1], to: sortedDays[i]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }

    // MARK: - Weekly Grouping
    static func weeklySummary(from entries: [ReflectionEntry]) -> [Date: [ReflectionEntry]] {
        var summary: [Date: [ReflectionEntry]] = [:]
        let calendar = Calendar.current

        for entry in entries {
            guard let date = entry.timestamp else { continue }
            if let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start {
                summary[weekStart, default: []].append(entry)
            }
        }
        return summary
    }

    // MARK: - Weekly Average Mood Score
    static func weeklyAverage(for entries: [ReflectionEntry]) -> Double {
        let calendar = Calendar.current
        guard let start = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }

        let thisWeek = entries.filter { entry in
            guard let date = entry.timestamp else { return false }
            return date >= start
        }

        let scores = thisWeek.map { moodScore(for: $0) }
        guard !scores.isEmpty else { return 0 }
        return scores.average
    }

    // MARK: - Week-to-Week Comparison
    static func compareWeekToLast(from entries: [ReflectionEntry]) -> Double {
        let calendar = Calendar.current
        guard
            let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start,
            let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart)
        else { return 0 }

        let thisWeek = entries.filter {
            guard let date = $0.timestamp else { return false }
            return date >= thisWeekStart
        }

        let lastWeek = entries.filter {
            guard let date = $0.timestamp else { return false }
            return date >= lastWeekStart && date < thisWeekStart
        }

        let thisAvg = thisWeek.map { moodScore(for: $0) }.average
        let lastAvg = lastWeek.map { moodScore(for: $0) }.average

        guard lastAvg > 0 else { return 0 }
        return ((thisAvg - lastAvg) / lastAvg) * 100
    }

    // MARK: - Insights Summary
    static func insightsSummary(from entries: [ReflectionEntry]) -> [String: Any] {
        let sorted = entries.sorted(by: {
            ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast)
        })

        guard !sorted.isEmpty else { return [:] }

        let latest = sorted.first
        let scores = sorted.map { moodScore(for: $0) }
        let avg = scores.average

        let dominantMood = dominantMoodType(from: entries)?.storageValue ?? "unknown"

        return [
            "dominantMood": dominantMood,
            "averageMoodScore": avg,
            "reflectionCount": sorted.count,
            "currentStreak": currentStreak(from: entries),
            "longestStreak": longestStreak(from: entries),
            "recentReflectionText": latest?.text ?? "",
            "moodTrendPercent": compareWeekToLast(from: entries)
        ]
    }
}

// MARK: - Helper Array Extensions
fileprivate extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}

