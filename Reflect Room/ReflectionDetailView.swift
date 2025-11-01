//
//  ReflectionDetailView.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 10/30/25.
//

import SwiftUI
import AVKit
import CoreData

struct ReflectionDetailView: View {
    var entry: ReflectionEntry
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme

    @State private var player: AVPlayer? = nil
    @State private var isPlayerReady = false

    var body: some View {
        ZStack {
            ReflectRoomBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    Text("Reflection")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)

                    // Mood + Date
                    HStack(spacing: 10) {
                        Text(moodEmoji(for: entry.mood ?? ""))
                            .font(.largeTitle)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.mood ?? "Unknown Mood")
                                .font(.headline)
                                .foregroundColor(.primary)
                            if let date = entry.timestamp {
                                Text(date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // 🎥 Video Preview (PAUSED by default)
                    if let videoPath = entry.videoPath,
                       let url = getVideoURL(from: videoPath) {
                        VideoPlayer(player: player)
                            .frame(height: 250)
                            .cornerRadius(12)
                            .onAppear {
                                // Initialize player only once
                                if player == nil {
                                    let newPlayer = AVPlayer(url: url)
                                    newPlayer.pause() // 👈 ensure it starts paused
                                    player = newPlayer
                                    isPlayerReady = true
                                }
                            }
                            .onDisappear {
                                player?.pause()
                            }
                    } else {
                        Rectangle()
                            .fill(Color(UIColor.tertiarySystemFill))
                            .frame(height: 250)
                            .cornerRadius(12)
                            .overlay(
                                Text("No video recorded")
                                    .foregroundColor(.secondary)
                            )
                    }

                    // 📝 Reflection Text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reflection Notes")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(entry.text ?? "No written reflection.")
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemBackground).opacity(0.8))
                            )
                    }

                    Spacer()
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers
    private func moodEmoji(for mood: String) -> String {
        switch mood.lowercased() {
        case "happy": return "😊"
        case "sad": return "😢"
        case "okay": return "😐"
        case "angry": return "😠"
        case "anxious": return "😰"
        default: return "🪞"
        }
    }

    private func getVideoURL(from path: String) -> URL? {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents?.appendingPathComponent(path)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sample = ReflectionEntry(context: context)
    sample.mood = "Happy"
    sample.text = "Today was great! Practiced gratitude and took a long walk."
    sample.timestamp = Date()
    return ReflectionDetailView(entry: sample)
        .environment(\.managedObjectContext, context)
}
