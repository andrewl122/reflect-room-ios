//
//  MoodInsightsView.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 10/31/25.
//

import SwiftUI
import Charts
import CoreData

// MARK: - Support Models & Helpers
struct MoodTrend: Identifiable {
    let id = UUID()
    let date: Date
    let averageScore: Double
}

extension ReflectionEntry {
    static func moodScore(for mood: String) -> Double {
        switch mood.lowercased() {
        case "happy":  return 5
        case "okay":   return 4
        case "sad":    return 3
        case "anxious":return 2
        case "angry":  return 1
        default:       return 3
        }
    }
}

// MARK: - Time Range Options
enum TimeRange: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case sixMonths = "6M"
    case year = "Year"
}

struct MoodInsightsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var reflections: FetchedResults<ReflectionEntry>

    @State private var selectedRange: TimeRange = .month
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            ReflectRoomBackground()

            ScrollView {
                VStack(spacing: 28) {
                    Text("Your Insights")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                        .padding(.top)

                    // MARK: - Average Mood Score
                    VStack(spacing: 10) {
                        Text("Average Mood Score")
                            .font(.headline)
                            .foregroundColor(.primary)

                        let avg = calculateAverage(for: selectedRange)
                        Text(String(format: "%.1f / 5", avg))
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.black)
                            .animation(.easeInOut, value: avg)
                    }
                    .padding(.horizontal)

                    // MARK: - Reflection Streak
                    VStack(spacing: 10) {
                        Text("Reflection Streak")
                            .font(.headline)
                            .foregroundColor(.primary)

                        let streak = calculateReflectionStreak()
                        Text("\(streak) day\(streak == 1 ? "" : "s")")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal)

                    // MARK: - Insight Summary
                    insightSummary

                    // MARK: - Range Selector (chips)
                    HStack {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button(action: { withAnimation { selectedRange = range } }) {
                                Text(range.rawValue)
                                    .fontWeight(selectedRange == range ? .bold : .regular)
                                    .foregroundColor(selectedRange == range ? .white : .primary)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(
                                        Capsule()
                                            .fill(selectedRange == range ? Color.purple : Color.gray.opacity(0.2))
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)

                    // MARK: - Mood Distribution Chart
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Mood Distribution")
                            .font(.headline)
                            .foregroundColor(.purple)
                            .padding(.leading, 8)

                        let distro = moodDistribution(for: selectedRange)
                        if distro.isEmpty {
                            Text("No data available for this period.")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Chart(distro, id: \.mood) { stat in
                                BarMark(
                                    x: .value("Mood", stat.mood),
                                    y: .value("Count", stat.count)
                                )
                                .foregroundStyle(colorForMood(stat.mood))
                                .cornerRadius(6)
                            }
                            .frame(height: 180)
                            .padding(.horizontal)
                            .chartYAxis(.hidden)
                            .animation(.easeInOut, value: selectedRange)
                        }
                    }

                    // MARK: - Mood Over Time Chart
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Mood Over Time")
                            .font(.headline)
                            .foregroundColor(.purple)
                            .padding(.leading, 8)

                        let trends = filteredMoodTrends(for: selectedRange)
                        if trends.isEmpty {
                            Text("No reflections recorded in this range.")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Chart(trends) { trend in
                                LineMark(
                                    x: .value("Date", trend.date),
                                    y: .value("Average Score", trend.averageScore)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Color.purple)
                                .lineStyle(StrokeStyle(lineWidth: 3))
                                .symbol(Circle().strokeBorder(lineWidth: 1.5))
                            }
                            .frame(height: 200)
                            .padding(.horizontal)
                            .chartYScale(domain: 1...5)
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                                    AxisGridLine()
                                    AxisValueLabel {
                                        if let date = value.as(Date.self) {
                                            switch selectedRange {
                                            case .day:
                                                Text(date.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated))))
                                            case .week:
                                                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                            case .month:
                                                Text(date.formatted(.dateTime.day()))
                                            case .sixMonths:
                                                Text(date.formatted(.dateTime.month(.abbreviated)))
                                            case .year:
                                                Text(date.formatted(.dateTime.month(.abbreviated)))
                                            }
                                        }
                                    }
                                }
                            }
                            .animation(.easeInOut(duration: 0.5), value: selectedRange)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
        .navigationTitle("Mood Insights")
    }

    // MARK: - Average Mood Calculation
    private func calculateAverage(for range: TimeRange) -> Double {
        let filtered = filteredMoodTrends(for: range)
        let total = filtered.reduce(0.0) { $0 + $1.averageScore }
        return filtered.isEmpty ? 0 : total / Double(filtered.count)
    }

    // MARK: - Reflection Streak
    private func calculateReflectionStreak() -> Int {
        let sorted = reflections.compactMap { $0.timestamp }.sorted(by: >)
        guard let latest = sorted.first else { return 0 }

        var streak = 1
        var previousDate = latest

        for date in sorted.dropFirst() {
            if Calendar.current.isDate(date, inSameDayAs: previousDate) { continue }
            if let diff = Calendar.current.dateComponents([.day], from: date, to: previousDate).day, diff == 1 {
                streak += 1
                previousDate = date
            } else {
                break
            }
        }
        return streak
    }

    // MARK: - Mood Distribution (tuple to avoid MoodStat redeclaration)
    private func moodDistribution(for range: TimeRange) -> [(mood: String, count: Int)] {
        let moods = ["Happy", "Okay", "Sad", "Anxious", "Angry"]
        let (start, end) = dateRange(for: range)

        let inRange = reflections.filter { entry in
            guard let d = entry.timestamp else { return false }
            return d >= start && d <= end
        }

        return moods.compactMap { mood in
            let c = inRange.filter { $0.mood == mood }.count
            return c > 0 ? (mood, c) : nil
        }
    }

    // MARK: - Mood Trends
    private func filteredMoodTrends(for range: TimeRange) -> [MoodTrend] {
        let (start, end) = dateRange(for: range)
        let filtered = reflections.filter {
            if let date = $0.timestamp { return date >= start && date <= end }
            return false
        }

        // Group by start-of-day
        let grouped = Dictionary(grouping: filtered) {
            Calendar.current.startOfDay(for: $0.timestamp ?? Date())
        }

        return grouped.map { (date, entries) in
            let scores = entries.map { ReflectionEntry.moodScore(for: $0.mood ?? "") }
            let avg = scores.reduce(0, +) / Double(scores.count)
            return MoodTrend(date: date, averageScore: avg)
        }
        .sorted { $0.date < $1.date }
    }

    // MARK: - Date Range Calculation
    private func dateRange(for range: TimeRange) -> (start: Date, end: Date) {
        let now = Date()
        switch range {
        case .day:       return (Calendar.current.date(byAdding: .day, value: -1, to: now)!, now)
        case .week:      return (Calendar.current.date(byAdding: .day, value: -7, to: now)!, now)
        case .month:     return (Calendar.current.date(byAdding: .month, value: -1, to: now)!, now)
        case .sixMonths: return (Calendar.current.date(byAdding: .month, value: -6, to: now)!, now)
        case .year:      return (Calendar.current.date(byAdding: .year, value: -1, to: now)!, now)
        }
    }

    // MARK: - Insight Summary
    private var insightSummary: some View {
        VStack(spacing: 8) {
            let currentAverage  = calculateAverage(for: selectedRange)
            let previousAverage = calculatePreviousAverage(for: selectedRange)
            let difference      = currentAverage - previousAverage

            if difference > 0.2 {
                InsightCardView(
                    title: "Great Progress 🎉",
                    message: "Your average mood improved by \(String(format: "%.1f", difference)) points since last \(selectedRange.rawValue.lowercased()). Keep it up!"
                )
            } else if difference < -0.2 {
                InsightCardView(
                    title: "Tough Week 💭",
                    message: "Your average mood dropped by \(String(format: "%.1f", abs(difference))) points compared to last \(selectedRange.rawValue.lowercased()). Take a moment to reflect on what changed."
                )
            } else {
                InsightCardView(
                    title: "Steady Flow 🌿",
                    message: "Your mood has stayed balanced compared to last \(selectedRange.rawValue.lowercased()). Consistency is key!"
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedRange)
    }

    // MARK: - Previous Average
    private func calculatePreviousAverage(for range: TimeRange) -> Double {
        let now = Date()
        let length: TimeInterval
        switch range {
        case .day:       length = 86400
        case .week:      length = 7 * 86400
        case .month:     length = 30 * 86400
        case .sixMonths: length = 182 * 86400
        case .year:      length = 365 * 86400
        }

        let start = now.addingTimeInterval(-2 * length)
        let end   = now.addingTimeInterval(-length)

        let previousData = reflections.filter {
            if let d = $0.timestamp { return d >= start && d < end }
            return false
        }

        let scores = previousData.map { ReflectionEntry.moodScore(for: $0.mood ?? "") }
        let total  = scores.reduce(0.0, +)
        return scores.isEmpty ? 0 : total / Double(scores.count)
    }

    // MARK: - Helpers
    private func avgColor(for score: Double) -> Color {
        switch score {
        case 4.5...5:     return .green
        case 3.5..<4.5:   return .yellow
        case 2.5..<3.5:   return .orange
        default:          return .red
        }
    }

    private func colorForMood(_ mood: String) -> Color {
        switch mood.lowercased() {
        case "happy":  return .yellow
        case "okay":   return .gray
        case "sad":    return .blue
        case "anxious":return .orange
        case "angry":  return .red
        default:       return .purple
        }
    }
}

// MARK: - Insight Card Component
struct InsightCardView: View {
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundColor(.purple)

            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.9))
                .shadow(radius: 3)
        )
        .padding(.horizontal)
    }
}

// MARK: - Preview (works with FetchedResults)
#Preview {
    struct PreviewWrapper: View {
        @FetchRequest(sortDescriptors: [])
        private var reflections: FetchedResults<ReflectionEntry>

        var body: some View {
            MoodInsightsView(reflections: reflections)
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
    }
    return PreviewWrapper()
}
