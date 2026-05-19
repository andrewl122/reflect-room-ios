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

enum TimeRange: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case sixMonths = "6M"
    case year = "Year"
}

// MARK: - MoodInsightsView
struct MoodInsightsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var reflections: FetchedResults<ReflectionEntry>
    @State private var selectedRange: TimeRange = .month
    @Environment(\.colorScheme) private var scheme
    @State private var showDetailedStats = false
    @State private var showMoodInfo = false // info alert toggle

    var body: some View {
        ZStack {
            ReflectRoomBackground()

            ScrollView {
                // 🧩 Compute analytics before layout
                let reflectionList = Array(reflections)
                let currentStreak = ReflectionEntry.currentStreak(from: reflectionList)
                let longestStreak = ReflectionEntry.longestStreak(from: reflectionList)
                let weekComparison = ReflectionEntry.compareWeekToLast(from: reflectionList)
                let filteredCount = reflectionCount(for: selectedRange)

                VStack(spacing: AppTheme.Spacing.xl) {
                    // MARK: - Header
                    Text("Your Insights")
                        .appHeadline()
                        .foregroundColor(AppTheme.Colors.accent)
                        .padding(.top, 8)

                    // MARK: - Streak & Comparison Summary
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Current Streak")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(currentStreak) days")
                                    .font(.headline)
                                    .bold()
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Longest Streak")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(longestStreak) days")
                                    .font(.headline)
                                    .bold()
                            }
                        }
                        .padding()
                        .background(AppTheme.Colors.cardBg(scheme))
                        .cornerRadius(AppTheme.Radii.lg)

                        if weekComparison != 0 {
                            Text("Mood change from last week: \(weekComparison > 0 ? "+" : "")\(weekComparison, specifier: "%.1f")%")
                                .font(.subheadline)
                                .foregroundColor(weekComparison >= 0 ? .green : .red)
                                .animation(.easeInOut, value: weekComparison)
                        }

                        // MARK: - View Detailed Stats Button
                        Button {
                            Haptics.tap()
                            showDetailedStats = true
                        } label: {
                            Text("View Detailed Stats")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(AppTheme.Colors.accent)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.Radii.lg)
                        }
                        .sheet(isPresented: $showDetailedStats) {
                            DetailedStatsView(reflections: reflectionList)
                                .presentationDetents([.medium, .large])
                        }
                    }

                    // MARK: - Average Mood Score
                    VStack(spacing: AppTheme.Spacing.xs) {
                        HStack(spacing: 4) {
                            Text("Average Mood Score")
                                .appHeadline()
                            Button {
                                Haptics.tap()
                                showMoodInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .alert("How It's Calculated", isPresented: $showMoodInfo) {
                                Button("Got it", role: .cancel) { }
                            } message: {
                                Text(MoodType.analyticsScoreLegend)
                            }
                        }

                        let avg = calculateAverage(for: selectedRange)
                        Text(String(format: "%.1f / 5", avg))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .animation(.easeInOut, value: avg)

                        // MARK: - Data Coverage Indicator (dynamic by range)
                        if filteredCount > 0 {
                            Text("Based on \(filteredCount) reflection\(filteredCount == 1 ? "" : "s") this \(selectedRange.labelDescription.lowercased())")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .animation(.easeInOut, value: selectedRange)
                        } else {
                            Text("No reflections recorded this \(selectedRange.labelDescription.lowercased())")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .animation(.easeInOut, value: selectedRange)
                        }
                    }

                    // MARK: - Insight Summary
                    insightSummary

                    // MARK: - Range Selector
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Button {
                                Haptics.tap()
                                withAnimation(.easeInOut) { selectedRange = range }
                            } label: {
                                Text(range.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(selectedRange == range ? .bold : .regular)
                                    .foregroundColor(selectedRange == range ? .white : AppTheme.Colors.textPrimary)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(
                                        Capsule().fill(selectedRange == range
                                                       ? AppTheme.Colors.accent
                                                       : AppTheme.Colors.cardBg(scheme))
                                    )
                            }
                        }
                    }

                    // MARK: - Mood Distribution Chart
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Mood Distribution")
                            .appHeadline()
                            .foregroundColor(AppTheme.Colors.accent)
                            .padding(.leading, 8)

                        let distro = moodDistribution(for: selectedRange)
                        if distro.isEmpty {
                            Text("No data available for this period.")
                                .subtleLabel()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Chart(distro, id: \.mood) { stat in
                                BarMark(
                                    x: .value("Mood", stat.mood.title),
                                    y: .value("Count", stat.count)
                                )
                                .foregroundStyle(stat.mood.color)
                                .cornerRadius(6)
                            }
                            .frame(height: 180)
                            .padding(.horizontal)
                            .chartYAxis(.hidden)
                            .animation(.easeInOut, value: selectedRange)
                        }
                    }

                    // MARK: - Mood Over Time Chart
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Mood Over Time")
                            .appHeadline()
                            .foregroundColor(AppTheme.Colors.accent)
                            .padding(.leading, 8)

                        let trends = filteredMoodTrends(for: selectedRange)
                        if trends.isEmpty {
                            Text("No reflections recorded in this range.")
                                .subtleLabel()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Chart(trends) { trend in
                                LineMark(
                                    x: .value("Date", trend.date),
                                    y: .value("Average Score", trend.averageScore)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(AppTheme.Colors.accent)
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
                                            case .day:       Text(date.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated))))
                                            case .week:      Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                            case .month:     Text(date.formatted(.dateTime.day()))
                                            case .sixMonths: Text(date.formatted(.dateTime.month(.abbreviated)))
                                            case .year:      Text(date.formatted(.dateTime.month(.abbreviated)))
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

    // MARK: - Helper: Reflection Count by Range
    private func reflectionCount(for range: TimeRange) -> Int {
        let (start, end) = dateRange(for: range)
        return reflections.filter {
            if let d = $0.timestamp { return d >= start && d <= end }
            return false
        }.count
    }

    // MARK: - Average Mood
    private func calculateAverage(for range: TimeRange) -> Double {
        let filtered = filteredMoodTrends(for: range)
        let total = filtered.reduce(0.0) { $0 + $1.averageScore }
        return filtered.isEmpty ? 0 : total / Double(filtered.count)
    }

    private func moodDistribution(for range: TimeRange) -> [(mood: MoodType, count: Int)] {
        let (start, end) = dateRange(for: range)
        let inRange = reflections.filter { entry in
            guard let d = entry.timestamp else { return false }
            return d >= start && d <= end
        }
        return MoodType.allCases.compactMap { mood in
            let count = inRange.filter { $0.moodType == mood }.count
            return count > 0 ? (mood: mood, count: count) : nil
        }
    }

    private func filteredMoodTrends(for range: TimeRange) -> [MoodTrend] {
        let (start, end) = dateRange(for: range)
        let filtered = reflections.filter {
            if let date = $0.timestamp { return date >= start && date <= end }
            return false
        }
        let grouped = Dictionary(grouping: filtered) {
            Calendar.current.startOfDay(for: $0.timestamp ?? Date())
        }
        return grouped.map { (date, entries) in
            let scores = entries.map { ReflectionEntry.moodScore(for: $0) }
            let avg = scores.reduce(0, +) / Double(scores.count)
            return MoodTrend(date: date, averageScore: avg)
        }
        .sorted { $0.date < $1.date }
    }

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

    private var insightSummary: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
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

    private func calculatePreviousAverage(for range: TimeRange) -> Double {
        let now = Date()
        let length: TimeInterval
        switch range {
        case .day: length = 86400
        case .week: length = 7 * 86400
        case .month: length = 30 * 86400
        case .sixMonths: length = 182 * 86400
        case .year: length = 365 * 86400
        }
        let start = now.addingTimeInterval(-2 * length)
        let end   = now.addingTimeInterval(-length)
        let previousData = reflections.filter {
            if let d = $0.timestamp { return d >= start && d < end }
            return false
        }
        let scores = previousData.map { ReflectionEntry.moodScore(for: $0) }
        let total  = scores.reduce(0.0, +)
        return scores.isEmpty ? 0 : total / Double(scores.count)
    }

}

// MARK: - TimeRange Label Description
extension TimeRange {
    var labelDescription: String {
        switch self {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .sixMonths: return "6 months"
        case .year: return "year"
        }
    }
}

// MARK: - Insight Card
struct InsightCardView: View {
    var title: String
    var message: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(title)
                .appHeadline()
                .foregroundColor(AppTheme.Colors.accent)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radii.lg)
                .fill(AppTheme.Colors.cardBg(scheme))
                .shadow(color: .black.opacity(scheme == .dark ? 0.4 : 0.08), radius: 4, x: 0, y: 3)
        )
        .padding(.horizontal)
    }
}

// MARK: - Preview
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
