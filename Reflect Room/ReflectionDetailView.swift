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
    @Environment(\.colorScheme) private var scheme

    @State private var player: AVPlayer? = nil
    @State private var isPlayerReady = false
    @State private var isPlaying = false
    @State private var showOverlay = true
    @State private var thumbnailImage: UIImage? = nil
    @State private var playerObserver: Any?

    var body: some View {
        ZStack {
            ReflectRoomBackground().ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // MARK: - Header
                    Text("Reflection")
                        .appTitle()
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    // MARK: - Mood + Date
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text(entry.moodDisplayIcon)
                            .font(.largeTitle)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.moodDisplayTitle)
                                .appHeadline()
                            if let date = entry.timestamp {
                                Text(date.formatted(date: .abbreviated, time: .shortened))
                                    .subtleLabel()
                            }
                        }
                    }

                    // MARK: - 🎥 Video Section
                    if let videoPath = entry.videoPath,
                       let url = getVideoURL(from: videoPath) {
                        ZStack {
                            if let thumbnail = thumbnailImage {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 250)
                                    .clipped()
                                    .cornerRadius(AppTheme.Radii.lg)
                                    .opacity(isPlaying ? 0 : 1)
                                    .animation(.easeInOut(duration: 0.3), value: isPlaying)
                            } else {
                                Rectangle()
                                    .fill(Color(UIColor.tertiarySystemFill))
                                    .frame(height: 250)
                                    .cornerRadius(AppTheme.Radii.lg)
                                    .onAppear { generateThumbnail(for: url) }
                            }

                            if player != nil {
                                VideoPlayer(player: player)
                                    .frame(height: 250)
                                    .cornerRadius(AppTheme.Radii.lg)
                                    .opacity(isPlaying ? 1 : 0)
                                    .onAppear {
                                        if let current = player {
                                            observePlayback(for: current)
                                        }
                                    }
                                    .onDisappear {
                                        player?.pause()
                                        removeObserver()
                                    }
                            }

                            if showOverlay {
                                Rectangle()
                                    .fill(Color.black.opacity(0.35))
                                    .cornerRadius(AppTheme.Radii.lg)
                                    .frame(height: 250)
                                    .overlay(
                                        Button(action: {
                                            Haptics.tap()
                                            togglePlayback()
                                        }) {
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

                    // MARK: - 🎙 Audio Section
                    if let audioPath = entry.audioPath, !audioPath.isEmpty {
                        AudioPlayerView(audioFilename: audioPath)
                            .cardBackground(scheme)
                    } else if entry.videoPath == nil {
                        RoundedRectangle(cornerRadius: AppTheme.Radii.lg)
                            .fill(Color(UIColor.tertiarySystemFill))
                            .frame(height: 80)
                            .overlay(Text("No media attached").subtleLabel())
                    }

                    // MARK: - 📝 Reflection Text
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Reflection Notes")
                            .appHeadline()
                        Text(entry.text ?? "No written reflection.")
                            .appBody()
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Radii.lg)
                                    .fill(AppTheme.Colors.cardBg(scheme))
                            )
                    }

                    Spacer()
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Video Setup
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
            Haptics.tap()
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
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0.1, preferredTimescale: 600)
            do {
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                let uiImage = UIImage(cgImage: cgImage)
                DispatchQueue.main.async { thumbnailImage = uiImage }
            } catch {
                print("❌ Thumbnail generation failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Helpers
    private func getVideoURL(from path: String) -> URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return docs?.appendingPathComponent(path)
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
