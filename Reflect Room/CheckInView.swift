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
    @Environment(\.dismiss) private var dismiss   // 👈 Added for navigation
    @Environment(\.colorScheme) var colorScheme

    var selectedMood: String

    @State private var showVideoRecorder = false
    @State private var videoURL: URL?
    @State private var reflectionText = ""

    var body: some View {
        ZStack {
            ReflectRoomBackground()  // 🌈 Animated gradient

            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    Text("Check-In")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding(.top, 10)

                    // Keep your selected mood display
                    Text("Today you’re feeling \(selectedMood)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 10)

                    // Video Section
                    VStack(spacing: 15) {
                        if let videoURL = videoURL {
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

                    // Reflection Text
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Write Your Reflection")
                            .font(.headline)
                        TextEditor(text: $reflectionText)
                            .frame(height: 150)
                            .padding(8)
                            .background(Color(UIColor.secondarySystemBackground).opacity(0.8))
                            .cornerRadius(12)
                            .shadow(radius: 1)
                    }

                    // Save Button
                    Button(action: {
                        saveReflection()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()   // 👈 Return to Home
                        }
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
            }
        }

        let newEntry = ReflectionEntry(context: viewContext)
        newEntry.id = UUID()
        newEntry.timestamp = Date()
        newEntry.text = reflectionText
        newEntry.videoPath = savedVideoPath
        newEntry.mood = selectedMood

        do {
            try viewContext.save()
            print("✅ Reflection saved to Core Data")
            reflectionText = ""
            videoURL = nil
        } catch {
            print("❌ Error saving reflection: \(error.localizedDescription)")
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
