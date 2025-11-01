//
//  HomeView.swift
//  ReflectRoom
//
//  Created by Andrew Lawrence on 10/30/25.
//

import SwiftUI
import Charts
import CoreData

// MARK: - MoodStat Model for Chart
struct MoodStat: Identifiable, Equatable {
    var id = UUID()
    var mood: String
    var count: Int
    var emoji: String

    static func == (lhs: MoodStat, rhs: MoodStat) -> Bool {
        lhs.id == rhs.id &&
        lhs.mood == rhs.mood &&
        lhs.count == rhs.count &&
        lhs.emoji == rhs.emoji
    }
}

struct HomeView: View {
    @State private var selectedMood: String? = nil
    @State private var navigateToCheckIn = false
    @State private var selectedTab: Tab = .home

    // Fetch reflection entries from Core Data
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ReflectionEntry.timestamp, ascending: false)],
        animation: .default
    )
    private var reflections: FetchedResults<ReflectionEntry>

    // Compute mood statistics for chart
    private var moodData: [MoodStat] {
        let moods = ["Happy", "Okay", "Sad", "Anxious", "Angry"]
        let emojis = ["😊", "😐", "😢", "😰", "😠"]
        var stats: [MoodStat] = []

        for (index, mood) in moods.enumerated() {
            let count = reflections.filter { $0.mood == mood }.count
            if count > 0 {
                stats.append(MoodStat(mood: mood, count: count, emoji: emojis[index]))
            }
        }

        return stats
    }

    var body: some View {
        VStack(spacing: 0) {
            if selectedTab == .home {
                NavigationView {
                    ZStack {
                        // Background gradient
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 216/255, green: 190/255, blue: 255/255),
                                Color.white
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()

                        VStack(spacing: 40) {
                            Spacer()

                            // Greeting / Instruction
                            Text("Hi Andrew,\nTap your mood to begin.")
                                .font(.system(size: 30, weight: .semibold))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                                .padding(.horizontal)

                            // Mood Buttons
                            HStack(spacing: 20) {
                                moodButton("😊", mood: "Happy")
                                moodButton("😐", mood: "Okay")
                                moodButton("😢", mood: "Sad")
                                moodButton("😰", mood: "Anxious")
                                moodButton("😠", mood: "Angry")
                            }

                            // Hidden Navigation Trigger
                            NavigationLink(
                                destination: CheckInView(selectedMood: selectedMood ?? "Unknown"),
                                isActive: $navigateToCheckIn
                            ) { EmptyView() }

                            Spacer()

                            // 🔮 Mood Overview Chart
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Mood Overview")
                                    .font(.headline)
                                    .foregroundColor(.purple)
                                    .padding(.leading, 8)

                                if moodData.isEmpty {
                                    Text("No reflections yet. Start your first check-in today!")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                        .multilineTextAlignment(.center)
                                } else {
                                    Chart(moodData) { stat in
                                        BarMark(
                                            x: .value("Mood", stat.emoji),
                                            y: .value("Count", stat.count)
                                        )
                                        .foregroundStyle(by: .value("Mood", stat.mood))
                                        .annotation {
                                            Text("\(stat.count)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .cornerRadius(6)
                                    }
                                    .frame(height: 180)
                                    .padding(.horizontal)
                                    .chartYAxis(.hidden)
                                    .chartXAxis {
                                        AxisMarks(preset: .aligned, values: moodData.map { $0.emoji })
                                    }
                                    // ✨ Smooth Bounce Animation
                                    .animation(
                                        .interpolatingSpring(stiffness: 80, damping: 8)
                                        .delay(0.05)
                                        .speed(0.9),
                                        value: moodData
                                    )
                                }
                            }

                            Spacer(minLength: 40)
                        }
                        .padding()
                    }
                }
            } else if selectedTab == .timeline {
                TimelineView()
            } else if selectedTab == .settings {
                SettingsView()
            }

            // Always show Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
    }

    // MARK: - Mood Button Builder
    private func moodButton(_ emoji: String, mood: String) -> some View {
        Button(action: {
            selectedMood = mood
            navigateToCheckIn = true
        }) {
            VStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 44))
                Text(mood)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.2))
                    .shadow(radius: 1)
            )
        }
    }
}

// MARK: - Placeholder SettingsView
struct SettingsView: View {
    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            Text("This screen will hold privacy options, app lock, and preferences soon.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            Spacer()
        }
    }
}

#Preview {
    HomeView()
}
