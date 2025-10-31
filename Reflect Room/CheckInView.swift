//
//  CheckInView.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 10/30/25.
//

import SwiftUI
import AVKit
import CoreData

struct CheckInView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var selectedMood: String   // ← new property

    @State private var showVideoRecorder = false
    @State private var videoURL: URL?
    @State private var reflectionText = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("Check-In")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Video Preview Section
                VStack(spacing: 15) {
                    if let videoURL = videoURL {
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .frame(height: 250)
                            .cornerRadius(12)
                    } else {
                        Rectangle()
                            .fill(Color(UIColor.tertiarySystemFill))
                            .frame(height: 250)
                            .overlay(Text("No video recorded"))
                            .cornerRadius(12)
                    }

                    Button(action: {
                        showVideoRecorder = true
                    }) {
                        Text("Record Video")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(12)
                    }
                }

                // Text Reflection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Write Your Reflection")
                        .font(.headline)
                    TextEditor(text: $reflectionText)
                        .frame(height: 150)
                        .padding(8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 1)
                }

                // Save Button
                Button(action: {
                    saveReflection()
                }) {
                    Text("Save Entry")
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .onTapGesture {
            dismissKeyboard()
        }
        .sheet(isPresented: $showVideoRecorder) {
            VideoRecorder(videoURL: $videoURL)
        }
    }

    // MARK: - Save Logic
    private func saveReflection() {
        var savedVideoPath: String?

        if let url = videoURL {
            if let path = VideoFileManager.shared.saveVideoToDocuments(videoURL: url) {
                savedVideoPath = path
                print("✅ Video saved at path: \(path)")
            } else {
                print("❌ Failed to save video")
            }
        }

        // Core Data Save
        let newEntry = ReflectionEntry(context: viewContext)
        newEntry.id = UUID()
        newEntry.timestamp = Date()
        newEntry.text = reflectionText
        newEntry.videoPath = savedVideoPath // Optional, can be nil
        newEntry.mood = selectedMood

        do {
            try viewContext.save()
            print("✅ Reflection saved to Core Data")
            // Reset state
            reflectionText = ""
            videoURL = nil
        } catch {
            print("❌ Error saving reflection: \(error.localizedDescription)")
        }
    }

    // MARK: - Dismiss Keyboard
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
