//
//  LoadingView.swift
//  ReflectRoom
//
//  Created by Andrew Lawrence on 10/31/25.
//

import SwiftUI

struct LoadingView: View {
    @State private var showHome = false
    @State private var quote = ""
    @State private var fadeIn = false
    @State private var fadeOut = false
    @State private var animateGradient = false
    @State private var breathing = false // 🌬️ breathing pulse

    // 🧠 Motivational / mental health quotes
    let quotes = [
        "Healing doesn’t mean the damage never existed. It means it no longer controls you.",
        "You don’t have to control your thoughts; you just have to stop letting them control you.",
        "Growth is uncomfortable because you’ve never been here before.",
        "Your feelings are valid. Don’t minimize your own emotions.",
        "The way you speak to yourself matters more than you think.",
        "Every day may not be good, but there’s something good in every day.",
        "You are not your mistakes — you are the lesson they taught you.",
        "Peace begins the moment you choose not to allow another person or event to control your emotions.",
        "Sometimes rest is the most productive thing you can do for yourself.",
        "You’re allowed to outgrow people, places, and versions of yourself that no longer fit.",
        "Progress isn’t always visible — healing often happens quietly.",
        "You can’t pour from an empty cup. Take time to refill.",
        "It’s okay to feel lost sometimes — it’s part of finding your way.",
        "What you feel is real. What you do with it is what shapes you.",
        "You are doing better than you think you are.",
        "Be proud of how far you’ve come, even if you’re not where you want to be yet.",
        "You are not behind — you’re on your own timeline.",
        "Let go of the need to be perfect; embrace the effort instead.",
        "Healing takes time. Be patient and gentle with yourself.",
        "Every small act of self-care is a victory worth celebrating.",
        "Sometimes strength looks like saying 'no' and choosing peace.",
        "You’re learning, growing, and becoming — and that’s enough.",
        "Your story isn’t over — you’re still writing the best parts.",
        "Feel your emotions, but don’t let them define you.",
        "It’s okay to take a break. You’re human, not a machine.",
        "Your emotions are valid; your feelings have value.",
        "When you can’t find the sunshine, be the sunshine.",
        "The comeback is always stronger than the setback.",
        "You have survived 100% of your hardest days.",
        "Your peace is worth protecting — even from your own thoughts.",
        "Allow yourself to be a work in progress.",
        "Sometimes, healing looks like rest, not productivity.",
        "You deserve the same compassion you give to others.",
        "It’s okay to not have it all figured out right now.",
        "Even small steps forward count as progress.",
        "Let today be the day you choose yourself.",
        "There is strength in being soft.",
        "You can begin again, as many times as you need.",
        "You are enough, even on your quiet days.",
        "Peace doesn’t mean you have no problems; it means they no longer control you."
    ]

    var body: some View {
        ZStack {
            // 🌈 Animated Gradient Background with Breathing Effect
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 216/255, green: 190/255, blue: 255/255),
                    Color(red: 200/255, green: 220/255, blue: 255/255),
                    Color.white
                ]),
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .animation(
                Animation.linear(duration: 12)
                    .repeatForever(autoreverses: true),
                value: animateGradient
            )
            // 🌬️ Breathing brightness pulse
            .brightness(breathing ? 0.05 : -0.05)
            .animation(
                Animation.easeInOut(duration: 5)
                    .repeatForever(autoreverses: true),
                value: breathing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // 🪞 App Title
                Text("Reflect Room")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.purple.opacity(0.9))
                    .opacity(fadeIn ? 1 : 0)
                    .animation(.easeIn(duration: 1.5), value: fadeIn)

                // 💬 Random Quote
                Text("“\(quote)”")
                    .font(.title3)
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                    .opacity(fadeIn ? 1 : 0)
                    .animation(.easeIn(duration: 2.5).delay(0.5), value: fadeIn)

                Spacer()

                // 🔄 Loading Indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    .scaleEffect(1.5)
                    .opacity(fadeIn ? 1 : 0)
                    .animation(.easeInOut(duration: 2.0).delay(1.0), value: fadeIn)
                    .padding(.bottom, 80)
            }
            .opacity(fadeOut ? 0 : 1)
            .animation(.easeOut(duration: 1.2).delay(6.0), value: fadeOut)
        }
        .onAppear {
            // 🌤️ Setup animations and transitions
            quote = quotes.randomElement() ?? ""
            fadeIn = true
            animateGradient = true
            breathing = true

            // Trigger fade-out and transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                fadeOut = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                showHome = true
            }
        }
        .fullScreenCover(isPresented: $showHome) {
            HomeView()
        }
    }
}

#Preview {
    LoadingView()
}
