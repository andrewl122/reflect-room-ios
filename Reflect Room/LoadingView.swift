//
//  LoadingView.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 11/1/25.
//

import SwiftUI

struct LoadingView: View {
    @State private var hueRotate = false
    @State private var navigateToHome = false
    @Environment(\.colorScheme) var colorScheme

    private let quotes = [
        "Healing starts when honesty meets reflection.",
        "You grow through what you go through.",
        "Your emotions are valid, always.",
        "Peace begins the moment you choose yourself.",
        "Be patient with your becoming.",
        "Feel it. Name it. Release it.",
        "Awareness is the first step to change.",
        "Progress, not perfection.",
        "Every thought is a doorway to understanding.",
        "Even silence is part of reflection.",
        "You can’t heal what you don’t reveal.",
        "Stillness speaks louder than chaos.",
        "You don’t have to rush your healing.",
        "Your feelings are feedback, not failure.",
        "Be gentle with the parts of you still learning.",
        "Growth is quieter than people think.",
        "You are allowed to start over at any time.",
        "Clarity comes when you stop running from yourself.",
        "Your story is still being written—grace belongs in every chapter.",
        "Reflection is not looking back—it’s looking within."
    ]

    var body: some View {
        ZStack {
            // 🌈 Animated hue-rotating gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 216/255, green: 190/255, blue: 255/255),
                    Color(red: 170/255, green: 210/255, blue: 255/255),
                    Color(red: 255/255, green: 240/255, blue: 255/255)
                    
//                    Color(red: 215/255, green: 201/255, blue: 255/255), // Lavender
//                    Color(red: 182/255, green: 212/255, blue: 255/255), // Blue
//                    Color(red: 189/255, green: 244/255, blue: 216/255), // Mint
//                    Color(red: 255/255, green: 213/255, blue: 184/255), // Peach
//                    Color(red: 255/255, green: 199/255, blue: 214/255)  // Pink
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .hueRotation(.degrees(hueRotate ? 360 : 0))
            .animation(
                .linear(duration: 8).repeatForever(autoreverses: false), // ⏱ now 3s instead of 10
                value: hueRotate
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // App title
                Text("Reflect Room")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(sharedColor)
                    .transition(.opacity)

                // One random quote
                Text(quotes.randomElement() ?? "Your reflection starts here.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(sharedColor)
                    .padding(.horizontal)
                    .frame(maxWidth: 320)

                Spacer()

                // Footer line
                Text("Loading your reflection space...")
                    .font(.footnote)
                    .foregroundColor(sharedColor)
                    .padding(.bottom, 30)
            }

            // Fade to HomeView after delay
            if navigateToHome {
                HomeView()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 1.5), value: navigateToHome)
            }
        }
        .onAppear {
            hueRotate = true
            // ⏳ Match timing to animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                withAnimation {
                    navigateToHome = true
                }
            }
        }
    }

    private var sharedColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.9) : Color.black.opacity(0.9)
    }
}

#Preview {
    Group {
        LoadingView().preferredColorScheme(.light)
        LoadingView().preferredColorScheme(.dark)
    }
}
