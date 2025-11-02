//
//  AudioPlayerView.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 11/01/25.
//

import SwiftUI
import AVFoundation

struct AudioPlayerView: View {
    /// Provide the filename stored in Core Data (e.g., "ABC123.m4a")
    let audioFilename: String

    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Voice Reflection")
                        .font(.headline)

                    ProgressView(value: duration == 0 ? 0 : currentTime / duration)
                        .progressViewStyle(.linear)

                    HStack {
                        Text(timeString(currentTime)).font(.caption).monospacedDigit()
                        Spacer()
                        Text(timeString(duration)).font(.caption).monospacedDigit()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground).opacity(0.9))
            )
        }
        .onAppear(perform: preparePlayer)
        .onDisappear { stopAndInvalidate() }
    }

    // MARK: - Setup & Controls
    private func preparePlayer() {
        let doc = AudioFileManager.documentsDirectory().appendingPathComponent(audioFilename)
        do {
            player = try AVAudioPlayer(contentsOf: doc)
            duration = player?.duration ?? 0
            player?.prepareToPlay()

            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                currentTime = player?.currentTime ?? 0
                if let p = player, !p.isPlaying, currentTime >= duration, duration > 0 {
                    // finished
                    isPlaying = false
                    currentTime = duration
                }
            }
        } catch {
            print("❌ Audio playback error: \(error.localizedDescription)")
        }
    }

    private func togglePlayback() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    private func stopAndInvalidate() {
        player?.stop()
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }

    private func timeString(_ t: TimeInterval) -> String {
        let total = max(0, Int(t.rounded()))
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
