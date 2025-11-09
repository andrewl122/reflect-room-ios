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
import Combine

struct CheckInView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Binding var isTabBarHidden: Bool

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

    // MARK: - Prompts
    @State private var showPrompts = false
    @State private var isPremiumUser = false

    // MARK: - Reflections Fetch
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ReflectionEntry.timestamp, ascending: false)])
    private var reflections: FetchedResults<ReflectionEntry>

    // MARK: - Feedback
    @State private var showSuccessBanner = false

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

    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                ReflectRoomBackground().ignoresSafeArea()

                // MAIN CONTENT
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {

                        // MARK: - Header
                        VStack(spacing: AppTheme.Spacing.xs) {
                            Text("Check-In")
                                .appTitle()
                            Text("Today you’re feeling \(selectedMood)")
                                .subtleLabel()
                        }
                        .padding(.top, 10)

                        // MARK: - Reflection Type Picker
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

                        // MARK: - Reflection Type Sections
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
                            } else {
                                EmptyView()
                            }
                        }

                        // MARK: - Write your reflection
                        VStack(spacing: 0) {
                            HStack {
                                Text("Write Your Reflection")
                                    .appHeadline()
                                Spacer()
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.top, AppTheme.Spacing.md)

                            TextEditor(text: $reflectionText)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 170)
                                .padding(.horizontal, AppTheme.Spacing.md)
                                .padding(.top, AppTheme.Spacing.sm)
                                .padding(.bottom, AppTheme.Spacing.md)
                                .id("ReflectionEditor")

                            // MARK: - Need Inspiration Button
                            Button {
                                Haptics.tap()
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                    showPrompts.toggle()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                    Text("Need Inspiration?")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .font(.subheadline.bold())
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(AppTheme.Colors.accent.opacity(0.1))
                                .foregroundColor(AppTheme.Colors.accent)
                                .cornerRadius(AppTheme.Radii.lg)
                                .padding(.horizontal, AppTheme.Spacing.md)
                                .padding(.bottom, AppTheme.Spacing.md)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radii.lg)
                                .fill(AppTheme.Colors.cardBg(scheme))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radii.lg)
                                .stroke(AppTheme.Colors.accent.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(scheme == .dark ? 0.25 : 0.07),
                                radius: 4, x: 0, y: 2)
                        .cardBackground(scheme)
                        .sheet(isPresented: $showPrompts) {
                            // MARK: - Inspiration Modal (Blur + Fade)
                            ZStack {
                                VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                                    .ignoresSafeArea()
                                    .overlay(
                                        Color.black.opacity(0.25)
                                            .ignoresSafeArea()
                                            .transition(.opacity)
                                    )

                                ReflectionPromptView(
                                    reflections: Array(reflections),
                                    isPremium: isPremiumUser,
                                    reflectionText: $reflectionText,
                                    selectedMood: selectedMood   // ✅ Pass current mood to prompt engine
                                )
                                .onDisappear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        proxy.scrollTo("ReflectionEditor", anchor: .bottom)
                                    }
                                }
                                .padding(.top, 20)
                                .padding(.horizontal, 12)
                                .background(.ultraThinMaterial)
                                .cornerRadius(AppTheme.Radii.xl)
                                .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: -4)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showPrompts)
                            }
                        }


                        // MARK: - Save Button
                        Button(action: saveAndNotify) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Entry").bold()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.Colors.successSoft)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .cornerRadius(AppTheme.Radii.lg)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, keyboardHeight > 0 ? keyboardHeight + 24 : 60)
                }
                .scrollIndicators(.hidden)
            }

            // MARK: - Success Banner
            .safeAreaInset(edge: .top) {
                if showSuccessBanner {
                    SuccessBannerView(message: "Reflection Saved — Keep it up!")
                        .padding(.horizontal)
                        .padding(.top, 6)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .animation(.easeInOut(duration: 0.3), value: showSuccessBanner)
                }
            }

            .onTapGesture { dismissKeyboard() }

            // MARK: - Keyboard Behavior
            .onReceive(keyboardPublisher) { height in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    keyboardHeight = height
                    isTabBarHidden = height > 0
                    if height > 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                proxy.scrollTo("ReflectionEditor", anchor: .bottom)
                            }
                        }
                    }
                }
            }

            // MARK: - Sheets for Recording
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
    }

    // MARK: - Video Section
    private var videoSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            if let videoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 250)
                    .cornerRadius(AppTheme.Radii.lg)
                    .shadow(color: .black.opacity(scheme == .dark ? 0.35 : 0.12),
                            radius: 6, x: 0, y: 4)
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
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
        }
        .cardBackground(scheme)
    }

    // MARK: - Save Logic
    private func saveAndNotify() {
        saveReflection()
        Haptics.success()
        withAnimation(.easeInOut(duration: 0.25)) {
            showSuccessBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showSuccessBanner = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                dismiss()
            }
        }
    }

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
    CheckInView(isTabBarHidden: .constant(false), selectedMood: "Happy")
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

// MARK: - Audio Capture Strip
private struct AudioCaptureStrip: View {
    @Binding var tempAudioURL: URL?
    @Binding var audioFilenameSaved: String?
    var onRecord: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            if let filename = audioFilenameSaved, !filename.isEmpty {
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
                HStack(spacing: 8) {
                    Image(systemName: "mic.circle.fill")
                    Text("Record Voice Note").fontWeight(.medium)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppTheme.Colors.accentSoft)
                .cornerRadius(AppTheme.Radii.lg)
                .foregroundColor(AppTheme.Colors.textPrimary)
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
        HStack(spacing: AppTheme.Spacing.md) {
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(AppTheme.Colors.accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(isPlaying ? "Playing..." : "Voice note ready")
                    .appBody()
                Text(audioURL.lastPathComponent)
                    .font(.caption2)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer()
        }
        .padding()
        .modifier(CardBGShim())
        .onDisappear { player?.stop() }
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

// MARK: - Success Banner View
private struct SuccessBannerView: View {
    var message: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)
            Text(message)
                .font(.subheadline).bold()
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(
            Capsule(style: .continuous)
                .fill(AppTheme.Colors.successSoft)
                .shadow(color: .black.opacity(scheme == .dark ? 0.35 : 0.12),
                        radius: 6, x: 0, y: 4)
        )
    }
}

// MARK: - Card Background Shim
private struct CardBGShim: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radii.lg)
                    .fill(AppTheme.Colors.cardBg(scheme))
            )
            .cornerRadius(AppTheme.Radii.lg)
            .shadow(color: .black.opacity(scheme == .dark ? 0.25 : 0.07),
                    radius: 4, x: 0, y: 2)
    }
}

