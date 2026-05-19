//
//  MoodIcon.swift
//  ReflectRoom
//
//  Created by Andrew Lawrence on 6/15/25.
//

import SwiftUI

/// Core 9 Emotion Set for Reflect Room
enum MoodType: String, CaseIterable {
    case happy
    case peaceful
    case grateful
    case neutral
    case reflective
    case sad
    case stressed
    case anxious
    case tired

    /// Emoji or symbol that represents the emotion (Hybrid System)
    var icon: String {
        switch self {
        case .happy: return "😊"
        case .peaceful: return "😌"
        case .grateful: return "🙏"
        case .neutral: return "😐"
        case .reflective: return "🤔"
        case .sad: return "😔"
        case .stressed: return "😫"
        case .anxious: return "😰"
        case .tired: return "😴"
        }
    }

    /// Human-readable emotion title
    var title: String {
        switch self {
        case .happy: return "Happy"
        case .peaceful: return "Peaceful"
        case .grateful: return "Grateful"
        case .neutral: return "Neutral"
        case .reflective: return "Reflective"
        case .sad: return "Sad"
        case .stressed: return "Stressed"
        case .anxious: return "Anxious"
        case .tired: return "Tired"
        }
    }

    /// Soft emotional colors matching the new palette
    var color: Color {
        switch self {

        // 🌞 Positive
        case .happy:
            return Color(red: 144/255, green: 238/255, blue: 144/255) // light green
        case .peaceful:
            return Color(red: 180/255, green: 248/255, blue: 200/255) // mint
        case .grateful:
            return Color(red: 255/255, green: 233/255, blue: 107/255) // soft yellow

        // 🌤 Neutral
        case .neutral:
            return Color(red: 207/255, green: 207/255, blue: 207/255) // gray
        case .reflective:
            return Color(red: 215/255, green: 201/255, blue: 255/255) // lavender

        // 🌧 Negative
        case .sad:
            return Color(red: 130/255, green: 180/255, blue: 255/255) // light blue
        case .stressed:
            return Color(red: 255/255, green: 154/255, blue: 118/255) // orange-red
        case .anxious:
            return Color(red: 197/255, green: 163/255, blue: 255/255) // soft purple

        // 😴 Low Energy
        case .tired:
            return Color(red: 145/255, green: 158/255, blue: 175/255) // blue-gray
        }
    }
}

/// Reusable mood icon view
struct MoodIcon: View {
    var mood: MoodType

    var body: some View {
        VStack(spacing: 6) {
            Text(mood.icon)
                .font(.system(size: 40))
                .padding(12)
                .background(mood.color.opacity(0.35))
                .clipShape(Circle())

            Text(mood.title)
                .font(.caption)
                .foregroundColor(.black) // always black per your rules
        }
    }
}

struct MoodIcon_Previews: PreviewProvider {
    static var previews: some View {
        MoodIcon(mood: .happy)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

//
// MARK: - MoodType Banner Messages (NEW)
//
extension MoodType {
    var bannerMessage: String {
        switch self {
        case .happy:
            return "You logged a happy moment — keep shining today ✨"
        case .peaceful:
            return "Your spirit feels calm and grounded."
        case .grateful:
            return "A gratitude moment always shifts the energy."
        case .neutral:
            return "A simple check-in helps you stay aware."
        case .reflective:
            return "You took a moment to reflect — that matters."
        case .sad:
            return "You honored a heavy feeling. That takes courage."
        case .stressed:
            return "You recognized stress — that’s where change starts."
        case .anxious:
            return "You named your anxiety. You’re not alone."
        case .tired:
            return "You’re running low — make space to rest soon."
        }
    }
}
