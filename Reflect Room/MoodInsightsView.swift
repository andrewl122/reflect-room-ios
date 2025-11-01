//
//  MoodInsightsView.swift
//  ReflectRoom
//
//  Created by Andrew Lawrence on 11/1/25.
//

import SwiftUI
import CoreData

struct MoodInsightsView: View {
    let reflections: FetchedResults<ReflectionEntry>
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    private var weeks: [WeeklyMoodSummary] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -30, to: Date())!
        let recent = reflections.filter { $0.timestamp ?? .distantPast >= startDate }

        let grouped = Dictionary(grouping: recent) { entry -> Int in
            calendar.component(.weekOfMonth, from: entry.timestamp ?? Date())
        }

        return grouped.keys.sorted().map { week in
            let entries = grouped[week] ?? []
            let moodCounts = Dictionary(grouping: entries, by: { $0.mood ?? "" }).mapValues { $0.count }
            let dominantMood = moodCounts.max(by: { $0.value < $1.value })?.key ?? "Unknown"
            let dominantEmoji = emoji(for: dominantMood)
            return WeeklyMoodSummary(week: week,
                                     averageMood: dominantMood,
                                     emoji: dominantEmoji,
                                     count: entries.count)
        }
    }

    private func emoji(for mood: String) -> String {
        switch mood {
        case "Happy": return "😊"
        case "Okay": return "😐"
        case "Sad": return "😢"
        case "Anxious": return "😰"
        case "Angry": return "😠"
        default: return "🪞"
        }
    }

    private var monthlySummary: String {
        let allMoods = weeks.map { $0.averageMood }
        guard !allMoods.isEmpty else { return "No reflections recorded this month." }
        let moodCounts = Dictionary(grouping: allMoods, by: { $0 }).mapValues { $0.count }
        let dominant = moodCounts.max(by: { $0.value < $1.value })?.key ?? "Balanced"
        return "Overall, you felt mostly \(dominant.lowercased()) this month."
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Adaptive background
                LinearGradient(
                    gradient: Gradient(colors: colorScheme == .dark ?
                                       [Color(red: 48/255, green: 44/255, blue: 68/255), .black] :
                                       [Color(red: 216/255, green: 190/255, blue: 255/255), .white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("This Month's Mood Insights")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                        .padding(.top, 20)

                    ScrollView {
                        ForEach(weeks) { week in
                            HStack {
                                Text("Week \(week.week)")
                                    .font(.headline)
                                    .frame(width: 90, alignment: .leading)
                                Text(week.emoji)
                                    .font(.system(size: 36))
                                Text("\(week.averageMood)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(week.count) reflections")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        colorScheme == .dark ?
                                        Color.white.opacity(0.08) :
                                        Color.white.opacity(0.3)
                                    )
                                    .shadow(radius: 1)
                            )
                            .padding(.horizontal)
                        }

                        VStack(spacing: 8) {
                            Text("🪞 Monthly Reflection")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.top, 10)
                            Text(monthlySummary)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }
            }
        }
    }
}

// MARK: - Supporting Model
struct WeeklyMoodSummary: Identifiable {
    let id = UUID()
    let week: Int
    let averageMood: String
    let emoji: String
    let count: Int
}

#Preview {
    Text("MoodInsightsView Preview")
}
