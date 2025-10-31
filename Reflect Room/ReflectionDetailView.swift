//
//  ReflectionDetailView.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 10/30/25.
//

import SwiftUI
import AVKit

struct ReflectionDetailView: View {
    var entry: ReflectionEntry

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let path = entry.videoPath,
                   FileManager.default.fileExists(atPath: path) {
                    VideoPlayer(player: AVPlayer(url: URL(fileURLWithPath: path)))
                        .frame(height: 250)
                        .cornerRadius(12)
                }

                Text(entry.text ?? "")
                    .font(.body)
                    .padding()

                if let mood = entry.mood {
                    Text("Mood: \(mood)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }

                Text(entry.timestamp ?? Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .navigationTitle("Reflection Details")
    }
}
