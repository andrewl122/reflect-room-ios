//
//  CheckInView.swift
//  Reflect Room
//
//  Updated by Ace (ChatGPT) — MoodType Edition + UI Polishes
//

import SwiftUI
import AVKit
import CoreData
import AVFoundation
import Combine

struct CheckInView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Binding var isTabBarHidden: Bool

    let mood: MoodType   // ⭐️ Updated — now strongly typed!

    // MARK: - AppStorage banner
    @AppStorage("lastMoodBannerMessage") private var lastMoodBannerMessage: String = ""
    @AppStorage("lastMoodType") private var lastMoodTypeRaw: String = ""

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

    // MARK: - Prompts
    @State private var showPrompts = false
    @State private var isPremiumUser = false

    // MARK: - Keyboard Handling
    @State private var keyboardHeight: CGFloat = 0
    private var keyboardPublisher: AnyPublisher<CGFloat, Never> {
        Publishers.Merge(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
                .map { $0.height },
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in CGFloat(0) }
        )
        .eraseToAnyPublisher()
    }

    // MARK: - Mood Caption (recommended option)
    private var moodCaption: String {
        switch mood {
        case .happy:
            return "Tap to capture what’s bringing you joy today."
        case .peaceful:
            return "Tap to ground your calm and ease."
        case .grateful:
            return "Tap to explore gratitude and appreciation."
        case .neutral:
            return "Tap to reflect on simple, steady moments."
        case .reflective:
            return "Tap to explore your thoughts more deeply."
        case .sad:
            return "Tap for gentle prompts to help you process your feelings."
        case .stressed:
            return "Tap for grounding prompts to reduce tension."
        case .anxious:
            return "Tap for calming questions to ease your thoughts."
        case .tired:
            return "Tap to recharge your mental and emotional energy."
        }
    }

    // MARK: - Body
    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                ReflectRoomBackground().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {

                        // MARK: Header
                        VStack(spacing: AppTheme.Spacing.sm) {
                            Text("Check-In")
                                .appTitle()
                            Text("Take a moment to express how you're feeling.")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        .padding(.top, 10)

                        // MARK: Reflection Type Picker
                        VStack(spacing: AppTheme.Spacing.sm) {
                            Text("Reflection Type")
                                .appHeadline()
                                .padding(.top, AppTheme.Spacing.md)

                            Picker("Reflection Type", selection: $reflectionType) {
                                Text("Video").tag("video")
                                Text("Voice").tag("audio")
                                Text("Text").tag("text")
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: reflectionType) { _ in Haptics.tap() }
                        }
                        .cardBackground(scheme)

                        // MARK: Inspiration Card
                        VStack(spacing: 6) {
                            Button {
                                Haptics.tap()
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                    showPrompts.toggle()
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.title3)
                                        .foregroundColor(AppTheme.Colors.accent)
                                    Text("Need Inspiration?")
                                        .font(.headline)
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.Colors.accent)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.Radii.lg)
                                        .fill(AppTheme.Colors.cardBg(scheme))
                                )
                            }

                            Text(moodCaption)
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 10)
                        }
                        .padding(.horizontal)

                        // MARK: Reflection Type Sections
                        Group {
                            if reflectionType == "video" {
                                videoSection
                            } else if reflectionType == "audio" {
                                AudioCaptureStrip(
                                    tempAudioURL: $tempAudioURL,
                                    audioFilenameSaved: $audioFilenameSaved,
                                    onRecord: { showAudioRecorder = true }
                                )
                                .cardBackground(scheme)
                            }
                        }

                        // MARK: Write Reflection
                        VStack(spacing: 0) {
                            HStack {
                                Text("Write Your Reflection")
                                    .appHeadline()
                                Spacer()
                            }
                            .padding(.horizontal)

                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $reflectionText)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 170)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 8)
                                    .background(Color.clear)

                                if reflectionText.isEmpty {
                                    Text("Start typing...")
                                        .foregroundColor(.secondary)
                                        .padding(.top, 12)   // ⭐️ fixes spacing
                                        .padding(.leading, 10)
                                }
                            }
                            .frame(maxHeight: .infinity)
                            .padding(.bottom, AppTheme.Spacing.md)
                        }
                        .cardBackground(scheme)
                        .onTapGesture {
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil,
                                from: nil,
                                for: nil
                            )
                        }

                        // MARK: Prompts Sheet
                        .sheet(isPresented: $showPrompts) {
                            ReflectionPromptView(
                                reflections: fetchReflections(),
                                isPremium: isPremiumUser,
                                reflectionText: $reflectionText,
                                selectedMood: mood
                            )
                        }

                        // MARK: Save Button
                        Button(action: saveReflection) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Entry").bold()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.Colors.successSoft)
                            .cornerRadius(AppTheme.Radii.lg)
                        }
                        .padding(.top)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, keyboardHeight > 0 ? keyboardHeight + 24 : 60)
                }
            }

            // MARK: Keyboard Handling
            .onReceive(keyboardPublisher) { height in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    keyboardHeight = height
                    isTabBarHidden = height > 0
                }
            }

            // MARK: Recording Sheets
            .sheet(isPresented: $showVideoRecorder) {
                VideoRecorder(videoURL: $videoURL)
            }
            .sheet(isPresented: $showAudioRecorder) {
                AudioRecorderView(tempAudioURL: $pendingAudioURL) { savedURL in
                    pendingAudioURL = savedURL
                }
            }
        }
    }

    // MARK: - Fetch Helper
    private func fetchReflections() -> [ReflectionEntry] {
        let fetchRequest: NSFetchRequest<ReflectionEntry> = ReflectionEntry.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ReflectionEntry.timestamp, ascending: false)]
        return (try? viewContext.fetch(fetchRequest)) ?? []
    }

    // MARK: - Video Section
    private var videoSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            if let videoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 250)
                    .cornerRadius(AppTheme.Radii.lg)
            } else {
                RoundedRectangle(cornerRadius: AppTheme.Radii.lg)
                    .fill(Color(UIColor.tertiarySystemFill))
                    .frame(height: 250)
                    .overlay(Text("No video recorded").subtleLabel())
            }

            Button {
                Haptics.tap()
                showVideoRecorder = true
            } label: {
                Text("Record Video")
                    .fontWeight(.medium)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.Colors.accentSoft)
                    .cornerRadius(AppTheme.Radii.lg)
            }
        }
        .cardBackground(scheme)
    }

    // MARK: - Save Reflection
    private func saveReflection() {

        var savedVideoPath: String?
        var savedAudioPath: String?

        // Save video
        if let url = videoURL,
           let path = VideoFileManager.shared.saveVideoToDocuments(videoURL: url) {
            savedVideoPath = path
        }

        // Save audio
        if let url = tempAudioURL,
           let path = AudioFileManager.shared.saveAudioToDocuments(audioURL: url) {
            savedAudioPath = path
            audioFilenameSaved = path
            try? FileManager.default.removeItem(at: url)
            tempAudioURL = nil
        }

        // Save Core Data Entry
        let entry = ReflectionEntry(context: viewContext)
        entry.id = UUID()
        entry.timestamp = Date()
        entry.text = reflectionText
        entry.videoPath = savedVideoPath
        entry.audioPath = savedAudioPath
        entry.mood = mood.storageValue

        do {
            try viewContext.save()
            Haptics.success()

            // 🔥 Send banner to HomeView
            lastMoodTypeRaw = mood.storageValue
            lastMoodBannerMessage = mood.bannerMessage

            // Clear UI
            reflectionText = ""
            videoURL = nil

            dismiss()

        } catch {
            print("❌ Error saving reflection: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview
#Preview {
    CheckInView(isTabBarHidden: .constant(false), mood: .happy)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

// MARK: - Audio Capture Strip (unchanged)
private struct AudioCaptureStrip: View {
    @Binding var tempAudioURL: URL?
    @Binding var audioFilenameSaved: String?
    var onRecord: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            if let filename = audioFilenameSaved {
                AudioPlayerView(audioFilename: filename)
            } else if let url = tempAudioURL {
                InlineAudioPlayer(audioURL: url)
            } else {
                RoundedRectangle(cornerRadius: AppTheme.Radii.lg)
                    .fill(Color(UIColor.tertiarySystemFill))
                    .frame(height: 80)
                    .overlay(Text("No voice note recorded").subtleLabel())
            }

            Button(action: onRecord) {
                HStack {
                    Image(systemName: "mic.circle.fill")
                    Text("Record Voice Note")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppTheme.Colors.accentSoft)
                .cornerRadius(AppTheme.Radii.lg)
            }
        }
    }
}

// MARK: - Inline Audio Player
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
                    .foregroundColor(AppTheme.Colors.accent)
            }
            VStack(alignment: .leading) {
                Text(isPlaying ? "Playing..." : "Voice note ready")
                Text(audioURL.lastPathComponent)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.Colors.cardBg(.light))
        )
        .onDisappear { player?.stop() }
    }

    private func togglePlayback() {
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            if player == nil {
                player = try? AVAudioPlayer(contentsOf: audioURL)
                player?.prepareToPlay()
            }
            player?.play()
            isPlaying = true
        }
    }
}
