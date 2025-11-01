//
//  HomeView.swift
//  Reflect Room
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
    @State private var showInsightsView = false
    @Environment(\.colorScheme) var colorScheme

    // Fetch reflection entries from Core Data
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ReflectionEntry.timestamp, ascending: false)],
        animation: .default
    )
    private var reflections: FetchedResults<ReflectionEntry>

    // Compute mood statistics for chart (last 30 days)
    private var moodData: [MoodStat] {
        let moods = ["Happy", "Okay", "Sad", "Anxious", "Angry"]
        let emojis = ["😊", "😐", "😢", "😰", "😠"]
        var stats: [MoodStat] = []

        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let recentReflections = reflections.filter { entry in
            if let timestamp = entry.timestamp {
                return timestamp >= startDate
            }
            return false
        }

        for (index, mood) in moods.enumerated() {
            let count = recentReflections.filter { $0.mood == mood }.count
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
                        ReflectRoomBackground() // 🌈 animated gradient background

                        VStack(spacing: 30) {
                            Spacer()

                            // Greeting
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
                            .padding(.bottom, 10)

                            // Hidden Navigation Trigger
                            NavigationLink(
                                destination: CheckInView(selectedMood: selectedMood ?? "Unknown"),
                                isActive: $navigateToCheckIn
                            ) { EmptyView() }

                            // 🔮 Mood Overview Section
                            VStack(spacing: 16) {
                                Text("Your Mood Overview")
                                    .font(.headline)
                                    .foregroundColor(.purple)
                                    .padding(.top, 4)

                                if moodData.isEmpty {
                                    Text("No reflections yet. Start your first check-in today!")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                        .multilineTextAlignment(.center)
                                } else {
                                    // Chart and legend wrapped in tappable container
                                    Button(action: { showInsightsView = true }) {
                                        ZStack {
                                            LinearGradient(
                                                gradient: Gradient(colors: colorScheme == .dark
                                                                    ? [Color.purple.opacity(0.25), Color.black.opacity(0.4)]
                                                                    : [Color.purple.opacity(0.15), Color.blue.opacity(0.1)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            .cornerRadius(16)
                                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                                            VStack(spacing: 12) {
                                                // Chart
                                                Chart {
                                                    ForEach(moodData) { stat in
                                                        BarMark(
                                                            x: .value("Mood", stat.emoji),
                                                            y: .value("Count", stat.count)
                                                        )
                                                        .foregroundStyle(colorForMood(stat.mood))
                                                        .cornerRadius(6)
                                                        .annotation {
                                                            Text("\(stat.count)")
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                        }
                                                    }
                                                }
                                                .frame(height: 180)
                                                .padding(.horizontal)
                                                .chartLegend(.hidden) // ❌ remove default legend
                                                .chartYAxis(.hidden)
                                                .chartXAxis {
                                                    AxisMarks(preset: .aligned, values: moodData.map { $0.emoji })
                                                }
                                                .animation(.easeInOut(duration: 0.4), value: moodData)

                                                // 👇 Custom centered legend
                                                HStack(spacing: 14) {
                                                    ForEach(moodData, id: \.mood) { stat in
                                                        HStack(spacing: 6) {
                                                            Circle()
                                                                .fill(colorForMood(stat.mood))
                                                                .frame(width: 10, height: 10)
                                                            Text(stat.mood)
                                                                .font(.caption)
                                                                .foregroundColor(.primary)
                                                        }
                                                    }
                                                }
                                                .padding(.bottom, 6)
                                                .padding(.top, 4)
                                            }
                                            .padding(.vertical, 10)
                                        }
                                        .padding(.horizontal)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .sheet(isPresented: $showInsightsView) {
                                        MoodInsightsView(reflections: reflections)
                                    }
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

            // Custom Tab Bar
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
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.2))
                    .shadow(radius: 1)
            )
        }
    }

    // MARK: - Mood Color Mapping
    private func colorForMood(_ mood: String) -> Color {
        switch mood.lowercased() {
        case "happy": return .yellow
        case "okay": return .gray
        case "sad": return .blue
        case "anxious": return .orange
        case "angry": return .red
        default: return .purple
        }
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
