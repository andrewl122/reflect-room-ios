//
//  HomeView.swift
//  ReflectRoom
//
//  Created by Andrew Lawrence on 10/30/25.
//



import SwiftUI

struct HomeView: View {
    @State private var selectedMood: String? = nil
    @State private var navigateToCheckIn = false
    @State private var selectedTab: Tab = .home

    var body: some View {
        VStack(spacing: 0) {
            // Switch views based on the selected tab
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

                            // 🔜 Future graph or analytics section can go here

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

            // Always show the Custom Tab Bar
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

// MARK: - Preview
#Preview {
    HomeView()
}
