//
//  AudioRecorderView.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 11/01/25.
//

import SwiftUI
import AVFoundation

struct AudioRecorderView: View {
    @Environment(\.dismiss) private var dismiss

    /// Temporary audio file reference (binding)
    @Binding var tempAudioURL: URL?

    /// Completion handler to persist audio back to CheckInView
    var onSave: ((URL) -> Void)?

    @State private var recorder: AVAudioRecorder?
    @State private var isRecording = false
    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer?
    @State private var permissionDenied = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Button(action: {
                    stopRecording(save: false)
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                Spacer()
                Text("Voice Reflection")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.left")
                    .opacity(0) // invisible spacer
            }

            // Recording Status
            Text(isRecording ? "Recording…" : "Ready to record")
                .foregroundColor(isRecording ? .red : .secondary)

            // Timer
            Text(timeString(elapsed))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()

            // Buttons
            HStack(spacing: 18) {
                Button(action: toggleRecording) {
                    HStack(spacing: 10) {
                        Image(systemName: isRecording ? "stop.circle.fill" : "record.circle.fill")
                            .font(.system(size: 36, weight: .regular))
                        Text(isRecording ? "Stop" : "Record")
                            .font(.headline)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 18)
                    .background(isRecording ? Color.red.opacity(0.15) : Color.purple.opacity(0.15))
                    .cornerRadius(12)
                }

                if !isRecording, let url = tempAudioURL {
                    Button(action: {
                        stopRecording(save: true)
                        onSave?(url)  // 👈 Send URL back to CheckInView
                        dismiss()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "tray.and.arrow.down.fill")
                                .font(.system(size: 24))
                            Text("Save Recording")
                                .font(.headline)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 18)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
            }

            if let msg = errorMessage {
                Text(msg)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Spacer()
        }
        .padding()
        .onAppear(perform: configureSession)
        .onDisappear { stopRecording(save: false) }
        .interactiveDismissDisabled(isRecording)
        .alert("Microphone Access Denied", isPresented: $permissionDenied) {
            Button("OK") {}
        } message: {
            Text("Enable microphone access in Settings to record voice reflections.")
        }
    }

    // MARK: - Permissions
    private func configureSession() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    permissionDenied = true
                }
            }
        }
    }

    // MARK: - Recording Controls
    private func toggleRecording() {
        if isRecording {
            stopRecording(save: true)
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default,
                                    options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)

            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("m4a")

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            recorder = try AVAudioRecorder(url: tempURL, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.record()

            tempAudioURL = tempURL
            isRecording = true
            elapsed = 0

            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                elapsed += 0.1
            }

        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }

    private func stopRecording(save: Bool) {
        recorder?.stop()
        recorder = nil
        isRecording = false
        timer?.invalidate()
        timer = nil

        if !save {
            cleanupTemp()
        }

        do {
            try AVAudioSession.sharedInstance().setActive(false,
                options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ Error deactivating audio session: \(error.localizedDescription)")
        }
    }

    private func cleanupTemp() {
        if let url = tempAudioURL {
            try? FileManager.default.removeItem(at: url)
            tempAudioURL = nil
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let total = Int(t.rounded())
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
