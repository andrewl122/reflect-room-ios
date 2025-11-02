//
//  ReflectionDetailView.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 10/30/25.
//

import SwiftUI
import AVKit
import CoreData
import AVFoundation
import UIKit

struct ReflectionDetailView: View {
    var entry: ReflectionEntry
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme

    @State private var player: AVPlayer? = nil
    @State private var isPlayerReady = false
    @State private var isPlaying = false
    @State private var showOverlay = true
    @State private var thumbnailImage: UIImage? = nil
    @State private var playerObserver: Any?

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

                    // 🎥 Video Section (thumbnail + overlay)
                    if let videoPath = entry.videoPath,
                       let url = getVideoURL(from: videoPath) {
                        ZStack {
                            // Thumbnail
                            if let thumbnail = thumbnailImage {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 250)
                                    .clipped()
                                    .cornerRadius(12)
                                    .opacity(isPlaying ? 0 : 1)
                                    .animation(.easeInOut(duration: 0.3), value: isPlaying)
                            } else {
                                Rectangle()
                                    .fill(Color(UIColor.tertiarySystemFill))
                                    .frame(height: 250)
                                    .cornerRadius(12)
                                    .onAppear { generateThumbnail(for: url) }
                            }

                            // Player
                            if player != nil {
                                VideoPlayer(player: player)
                                    .frame(height: 250)
                                    .cornerRadius(12)
                                    .opacity(isPlaying ? 1 : 0)
                                    .onAppear {
                                        if let currentPlayer = player {
                                            observePlayback(for: currentPlayer)
                                        }
                                    }
                                    .onDisappear {
                                        player?.pause()
                                        removeObserver()
                                    }
                            }

                            // Overlay button
                            if showOverlay {
                                Rectangle()
                                    .fill(Color.black.opacity(0.35))
                                    .cornerRadius(12)
                                    .frame(height: 250)
                                    .overlay(
                                        Button(action: togglePlayback) {
                                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 70, height: 70)
                                                .foregroundStyle(.white)
                                                .shadow(radius: 6)
                                        }
                                    )
                                    .transition(.opacity)
                                    .animation(.easeInOut(duration: 0.3), value: showOverlay)
                            }
                        }
                        .onAppear { setupPlayer(with: url) }
                        .onDisappear {
                            player?.pause()
                            removeObserver()
                        }
                    }

                    // 🎙 Audio Section (if present)
                    if let audioPath = entry.audioPath, !audioPath.isEmpty {
                        AudioPlayerView(audioFilename: audioPath)
                    } else if entry.videoPath == nil {
                        // Show a friendly empty state if neither video nor audio exists
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.tertiarySystemFill))
                            .frame(height: 80)
                            .overlay(Text("No media attached").foregroundColor(.secondary))
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

    // MARK: - Video Player Setup & Controls
    private func setupPlayer(with url: URL) {
        if player == nil {
            let newPlayer = AVPlayer(url: url)
            newPlayer.pause()
            player = newPlayer
            isPlayerReady = true
        }
    }

    private func togglePlayback() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            withAnimation(.easeInOut(duration: 0.3)) {
                showOverlay = true
                isPlaying = false
            }
        } else {
            player.play()
            withAnimation(.easeInOut(duration: 0.3)) {
                showOverlay = false
                isPlaying = true
            }
        }
    }

    private func observePlayback(for player: AVPlayer) {
        removeObserver()
        playerObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.pause()
            withAnimation(.easeInOut) {
                isPlaying = false
                showOverlay = true
            }
        }
    }

    private func removeObserver() {
        if let observer = playerObserver {
            NotificationCenter.default.removeObserver(observer)
            playerObserver = nil
        }
    }

    // MARK: - Thumbnail
    private func generateThumbnail(for url: URL) {
        DispatchQueue.global(qos: .background).async {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0.1, preferredTimescale: 600)
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let uiImage = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    thumbnailImage = uiImage
                }
            } catch {
                print("❌ Failed to generate thumbnail: \(error.localizedDescription)")
            }
        }
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
