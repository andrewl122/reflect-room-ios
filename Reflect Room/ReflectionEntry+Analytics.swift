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
    static func moodScore(for mood: String) -> Double {
        switch mood.lowercased() {
        case "happy": return 5
        case "okay": return 4
        case "sad": return 3
        case "anxious": return 2
        case "angry": return 1
        default: return 3 // neutral fallback
        }
    }

    // MARK: Current Streak
    /// Calculates the number of consecutive days with reflections, only counting if the latest is recent.
    static func currentStreak(from entries: [ReflectionEntry]) -> Int {
        let sorted = entries.compactMap { $0.timestamp }.sorted(by: >)
        guard let latest = sorted.first else { return 0 }

        // If last reflection wasn’t today or yesterday, streak is 0
        let daysSinceLast = Calendar.current.dateComponents([.day], from: latest, to: Date()).day ?? 0
        guard daysSinceLast <= 1 else { return 0 }

        // Count backwards through consecutive days
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


    // MARK: Longest Streak
    /// Finds the longest chain of consecutive reflection days (ignores multiple reflections per day).
    static func longestStreak(from entries: [ReflectionEntry]) -> Int {
        // Get unique reflection days only
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

    // MARK: Weekly Grouping
    /// Groups reflections by week (Sunday–Saturday) for trend calculations.
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

    // MARK: Weekly Average
    /// Calculates the current week’s average mood score.
    static func weeklyAverage(for entries: [ReflectionEntry]) -> Double {
        let calendar = Calendar.current
        guard let start = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }

        let thisWeek = entries.filter { entry in
            guard let date = entry.timestamp else { return false }
            return date >= start
        }

        let scores = thisWeek.map { moodScore(for: $0.mood ?? "") }
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / Double(scores.count)
    }

    // MARK: Week-to-Week Comparison
    /// Compares this week's average mood score to the previous week's.
    /// Returns percentage change (e.g. +12.5 means improvement).
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

        let thisAvg = thisWeek.map { moodScore(for: $0.mood ?? "") }.average
        let lastAvg = lastWeek.map { moodScore(for: $0.mood ?? "") }.average

        guard lastAvg > 0 else { return 0 }
        return ((thisAvg - lastAvg) / lastAvg) * 100
    }

    // MARK: Insights Summary (for future ReflectionPromptEngine)
    /// Returns high-level summary data for reflection analysis or AI prompt generation.
    static func insightsSummary(from entries: [ReflectionEntry]) -> [String: Any] {
        let sorted = entries.sorted(by: { ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast) })
        guard !sorted.isEmpty else { return [:] }

        let latest = sorted.first
        let scores = sorted.map { moodScore(for: $0.mood ?? "") }
        let avg = scores.average

        // Find dominant mood
        let moods = sorted.map { $0.mood ?? "unknown" }
        let dominantMood = moods.mostFrequent() ?? "unknown"

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

fileprivate extension Array where Element == String {
    func mostFrequent() -> String? {
        guard !isEmpty else { return nil }
        let counts = Dictionary(grouping: self, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
