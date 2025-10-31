//
//  HomeView.swift
//  ReflectRoom
//
//  Created by Andrew Lawrence on 6/15/25.
//

import SwiftUI

struct HomeView: View {
    @State private var selectedMood: String? = nil
    @State private var navigateToCheckIn = false

    var body: some View {
        NavigationView {
            ZStack {
                // Lavender-to-white gradient
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

                    // Greeting text
                    Text("Hi Andrew,\nTap your mood to begin.")
                        .font(.system(size: 32, weight: .semibold))
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

                    Spacer()

                    // Custom Tab Bar
                    CustomTabBar()
                }
                .padding()

                // Hidden navigation trigger
                NavigationLink(
                    destination: CheckInView(selectedMood: selectedMood ?? "Unknown"),
                    isActive: $navigateToCheckIn
                ) { EmptyView() }
            }
        }
    }

    // MARK: - Mood Button
    private func moodButton(_ emoji: String, mood: String) -> some View {
        Button(action: {
            selectedMood = mood
            navigateToCheckIn = true
        }) {
            VStack {
                Text(emoji)
                    .font(.system(size: 44))
                Text(mood)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding(8)
        }
    }
}
