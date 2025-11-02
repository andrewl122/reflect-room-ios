//
//  CheckInView.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 10/30/25.
//

import SwiftUI
import AVKit
import CoreData
import AVFoundation

struct CheckInView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    var selectedMood: String

    // MARK: - Video
    @State private var showVideoRecorder = false
    @State private var videoURL: URL?

    // MARK: - Audio
    @State private var showAudioRecorder = false
    @State private var tempAudioURL: URL?
    @State private var pendingAudioURL: URL?
    @State private var audioFilenameSaved: String?

    // MARK: - Text
    @State private var reflectionText = ""

    // MARK: - Mode
    @State private var reflectionType: String = "video"

    var body: some View {
        ZStack {
            ReflectRoomBackground()

            ScrollView {
                VStack(spacing: 30) {
                    Text("Check-In")
                        .font(.largeTitle).fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding(.top, 10)

                    Text("Today you’re feeling \(selectedMood)")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Picker("Reflection Type", selection: $reflectionType) {
                        Text("Video").tag("video")
                        Text("Voice").tag("audio")
                        Text("Text").tag("text")
                    }
                    .pickerStyle(.segmented)

                    if reflectionType == "video" {
                        videoSection
                    } else if reflectionType == "audio" {
                        AudioCaptureStrip(
                            tempAudioURL: $tempAudioURL,
                            audioFilenameSaved: $audioFilenameSaved,
                            onRecord: { showAudioRecorder = true }
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Write Your Reflection").font(.headline)
                        TextEditor(text: $reflectionText)
                            .frame(height: 150)
                            .padding(8)
                            .background(Color(UIColor.secondarySystemBackground).opacity(0.8))
                            .cornerRadius(12)
                            .shadow(radius: 1)
                    }

                    Button(action: {
                        saveReflection()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { dismiss() }
                    }) {
                        Text("Save Entry")
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.25))
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
        .onTapGesture { dismissKeyboard() }

        // MARK: - Sheets
        .sheet(isPresented: $showVideoRecorder) {
            VideoRecorder(videoURL: $videoURL)
        }
        .sheet(isPresented: $showAudioRecorder, onDismiss: {
            if let url = pendingAudioURL {
                tempAudioURL = url
                pendingAudioURL = nil
                print("✅ Audio ready for preview: \(url.lastPathComponent)")
            }
        }) {
            AudioRecorderView(tempAudioURL: $pendingAudioURL) { savedURL in
                pendingAudioURL = savedURL
            }
        }
    }

    // MARK: - Video
    private var videoSection: some View {
        VStack(spacing: 15) {
            if let videoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 250)
                    .cornerRadius(12)
                    .shadow(radius: 4)
            } else {
                Rectangle()
                    .fill(Color(UIColor.tertiarySystemFill))
                    .frame(height: 250)
                    .cornerRadius(12)
                    .overlay(Text("No video recorded").foregroundColor(.secondary))
            }

            Button(action: { showVideoRecorder = true }) {
                Text("Record Video")
                    .fontWeight(.medium)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(12)
                    .foregroundColor(.primary)
            }
        }
    }

    // MARK: - Save
    private func saveReflection() {
        var savedVideoPath: String?
        var savedAudioPath: String?

        if let url = videoURL,
           let path = VideoFileManager.shared.saveVideoToDocuments(videoURL: url) {
            savedVideoPath = path
        }

        if let url = tempAudioURL,
           let path = AudioFileManager.shared.saveAudioToDocuments(audioURL: url) {
            savedAudioPath = path
            audioFilenameSaved = path
            try? FileManager.default.removeItem(at: url)
            tempAudioURL = nil
        }

        let newEntry = ReflectionEntry(context: viewContext)
        newEntry.id = UUID()
        newEntry.timestamp = Date()
        newEntry.text = reflectionText
        newEntry.videoPath = savedVideoPath
        newEntry.audioPath = savedAudioPath
        newEntry.mood = selectedMood

        do {
            try viewContext.save()
            print("✅ Reflection saved.")
            reflectionText = ""
            videoURL = nil
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

#Preview {
    CheckInView(selectedMood: "Happy")
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

// MARK: - Audio Capture Strip
private struct AudioCaptureStrip: View {
    @Binding var tempAudioURL: URL?
    @Binding var audioFilenameSaved: String?
    var onRecord: () -> Void

    var body: some View {
        VStack(spacing: 15) {
            if let filename = audioFilenameSaved, !filename.isEmpty {
                AudioPlayerView(audioFilename: filename)
            } else if let url = tempAudioURL {
                InlineAudioPlayer(audioURL: url)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.tertiarySystemFill))
                    .frame(height: 80)
                    .overlay(Text("No voice note recorded").foregroundColor(.secondary))
            }

            Button(action: onRecord) {
                Text("Record Voice Note")
                    .fontWeight(.medium)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(12)
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Inline Audio Player for temp recordings
private struct InlineAudioPlayer: View {
    let audioURL: URL
    @State private var isPlaying = false
    @State private var player: AVAudioPlayer?

    var body: some View {
        HStack {
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.purple)
            }
            Text(isPlaying ? "Playing..." : "Voice note ready")
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground).opacity(0.8))
        .cornerRadius(12)
        .onDisappear {
            player?.stop()
        }
    }

    private func togglePlayback() {
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            if player == nil {
                do {
                    player = try AVAudioPlayer(contentsOf: audioURL)
                    player?.prepareToPlay()
                } catch {
                    print("❌ Audio load error: \(error.localizedDescription)")
                }
            }
            player?.play()
            isPlaying = true
        }
    }
}
