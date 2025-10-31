//
//  TimelineView.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 10/30/25.
//


import SwiftUI
import CoreData
import AVKit

struct TimelineView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ReflectionEntry.timestamp, ascending: false)],
        animation: .default
    )
    private var reflections: FetchedResults<ReflectionEntry>

    var body: some View {
        NavigationStack {
            List {
                ForEach(reflections) { entry in
                    NavigationLink(destination: ReflectionDetailView(entry: entry)) {
                        HStack(spacing: 15) {
                            Text(moodEmoji(for: entry.mood ?? ""))
                                .font(.largeTitle)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.mood ?? "Unknown Mood")
                                    .font(.headline)
                                Text(entry.timestamp ?? Date(), style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Reflections") // ✅ Clean top title
            .navigationBarTitleDisplayMode(.large)
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

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let entry = reflections[index]
            viewContext.delete(entry)
        }
        try? viewContext.save()
    }
}
