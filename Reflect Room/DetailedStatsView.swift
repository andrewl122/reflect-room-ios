//
//  DetailedStatsView.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 11/02/25.
//

import SwiftUI
import CoreData

struct DetailedStatsView: View {
    var reflections: [ReflectionEntry]
    @Environment(\.colorScheme) private var scheme
    @State private var showInfo = false
    @State private var selectedRange: TimeRange = .month

    // MARK: - Computed Properties

    private var avgMood: Double {
        let scores = reflections.map { ReflectionEntry.moodScore(for: $0) }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }

    private var recentAvgMood: Double {
        let last7 = reflections.filter {
            guard let date = $0.timestamp else { return false }
            return date >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        }
        let scores = last7.map { ReflectionEntry.moodScore(for: $0) }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }

    private var reflectionCount: Int { reflections.count }

    private var dominantMood: MoodType? {
        ReflectionEntry.dominantMoodType(from: reflections)
    }

    private var dominantMoodLabel: String {
        guard let dominantMood else { return "🪞 None" }
        return "\(dominantMood.icon) \(dominantMood.title)"
    }

    private var currentStreak: Int {
        ReflectionEntry.currentStreak(from: reflections)
    }

    private var longestStreak: Int {
        ReflectionEntry.longestStreak(from: reflections)
    }

    /// Reflections per week (human-friendly)
    /// - Uses span from first reflection to **today**
    /// - Treats anything under 1 week as 1 week (so early users don’t get 14/week silliness)
    /// - Caps at 7 for the ring visual + copy
    private var reflectionFrequency: Double {
        guard
            !reflections.isEmpty,
            let first = reflections.compactMap({ $0.timestamp }).min()
        else { return 0 }

        let daysSpan = max(1, Calendar.current.dateComponents([.day], from: first, to: Date()).day ?? 1)

        // Use at least 1 week so very new users don't get inflated numbers.
        let weeksActive = max(Double(daysSpan) / 7.0, 1.0)

        let perWeek = Double(reflectionCount) / weeksActive

        // Cap to 7 for display/visual sanity.
        return min(perWeek, 7.0)
    }

    private var normalizedFrequency: Double {
        // 0.0 - 1.0 for the ring trim
        guard reflectionFrequency > 0 else { return 0 }
        return min(reflectionFrequency / 7.0, 1.0)
    }

    // MARK: - Dynamic Ring Gradient

    private var ringGradient: Gradient {
        switch reflectionFrequency {
        case 0..<1:
            return Gradient(colors: [.red, .orange])
        case 1..<4:
            return Gradient(colors: [.orange, .yellow])
        case 4..<6:
            return Gradient(colors: [.green, .teal])
        default:
            return Gradient(colors: [AppTheme.Colors.accent, .purple])
        }
    }

    // MARK: - Motivational Text

    private var frequencyMessage: String {
        switch reflectionFrequency {
        case 0:
            return "No reflections yet — your first one can start today 🌱"
        case 0..<1:
            return "You’re just getting started — great first steps 🌱"
        case 1..<4:
            return "Building momentum — keep it going 💫"
        case 4..<6:
            return "You’re finding your flow 🌿"
        default:
            return "Daily reflection rhythm unlocked 🔥"
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Title
                    VStack(spacing: 6) {
                        Text(dominantMood?.icon ?? "🪞")
                            .font(.system(size: 56))
                            .shadow(radius: 4)
                        Text("Your Reflection Stats")
                            .font(.title2.bold())
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    .padding(.top, 8)

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
                                        Capsule()
                                            .fill(selectedRange == range
                                                  ? AppTheme.Colors.accent
                                                  : AppTheme.Colors.cardBg(scheme))
                                    )
                            }
                        }
                    }

                    // MARK: - Key Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        statCard(title: "Average Mood",
                                 value: String(format: "%.1f / 5", avgMood))
                        statCard(title: "Last 7 Days",
                                 value: String(format: "%.1f / 5", recentAvgMood))
                        statCard(title: "Reflections",
                                 value: "\(reflectionCount)")
                        statCard(title: "Dominant Mood",
                                 value: dominantMoodLabel)
                        statCard(title: "Current Streak",
                                 value: "\(currentStreak) days")
                        statCard(title: "Longest Streak",
                                 value: "\(longestStreak) days")
                    }

                    // MARK: - Data Coverage Indicator
                    let count = reflectionCount(for: selectedRange)
                    if count > 0 {
                        Text("Based on \(count) reflection\(count == 1 ? "" : "s") this \(selectedRange.labelDescription.lowercased())")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .animation(.easeInOut, value: selectedRange)
                    } else {
                        Text("No reflections recorded this \(selectedRange.labelDescription.lowercased())")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .animation(.easeInOut, value: selectedRange)
                    }

                    // MARK: - Mood Average Info Card
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Text("How Averages Are Calculated")
                                .appHeadline()
                            Button {
                                Haptics.tap()
                                showInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .alert("Mood Score Scale", isPresented: $showInfo) {
                                Button("Got it", role: .cancel) { }
                            } message: {
                                Text(MoodType.analyticsScoreLegend)
                            }
                        }

                        Text("Your mood averages use the 9-mood score scale above.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radii.lg)
                            .fill(AppTheme.Colors.cardBg(scheme))
                            .shadow(color: .black.opacity(scheme == .dark ? 0.4 : 0.08),
                                    radius: 4, x: 0, y: 3)
                    )

                    // MARK: - Reflection Frequency Ring
                    VStack(spacing: 10) {
                        Text("Reflection Frequency")
                            .appHeadline()
                            .foregroundColor(AppTheme.Colors.accent)

                        ZStack {
                            // Background ring
                            Circle()
                                .stroke(lineWidth: 12)
                                .opacity(0.15)
                                .foregroundColor(.gray)

                            // Progress ring
                            Circle()
                                .trim(from: 0.0, to: normalizedFrequency)
                                .stroke(
                                    AngularGradient(gradient: ringGradient, center: .center),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .animation(.easeOut(duration: 1.0), value: normalizedFrequency)

                            // Center label
                            VStack(spacing: 2) {
                                Text(String(format: "%.1f", reflectionFrequency))
                                    .font(.title.bold())
                                Text("per week")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(width: 160, height: 160)

                        Text(frequencyMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                            .transition(.opacity)
                    }
                    .padding(.top, 16)

                    Spacer(minLength: 30)
                }
                .padding()
            }
            .navigationTitle("Detailed Stats")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Helper: Count by Range

    private func reflectionCount(for range: TimeRange) -> Int {
        let (start, end) = dateRange(for: range)
        return reflections.filter {
            if let d = $0.timestamp { return d >= start && d <= end }
            return false
        }.count
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

    // MARK: - Reusable Stat Card

    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radii.lg)
                .fill(AppTheme.Colors.cardBg(scheme))
                .shadow(color: .black.opacity(scheme == .dark ? 0.4 : 0.08),
                        radius: 4, x: 0, y: 3)
        )
    }

}
