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
    @Environment(\.colorScheme) var colorScheme

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ReflectionEntry.timestamp, ascending: false)],
        animation: .default
    )
    private var reflections: FetchedResults<ReflectionEntry>

    var body: some View {
        NavigationStack {
            ZStack {
                // 🌈 Animated Reflect Room Background
                ReflectRoomBackground()

                if reflections.isEmpty {
                    VStack(spacing: 20) {
                        Text("No Reflections Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)

                        Text("Your recorded reflections will appear here once you’ve saved a few check-ins.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 40)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(reflections) { entry in
                            NavigationLink(destination: ReflectionDetailView(entry: entry)) {
                                HStack(spacing: 15) {
                                    Text(moodEmoji(for: entry.mood ?? ""))
                                        .font(.largeTitle)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.mood ?? "Unknown Mood")
                                            .font(.headline)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        Text(entry.timestamp ?? Date(), style: .date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    // 🔧 This keeps the gradient visible behind the list
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            }
            .navigationTitle("Reflections")
            .navigationBarTitleDisplayMode(.large)
        }
        .background(ReflectRoomBackground()) // 🔥 fallback to ensure gradient stays active
        .ignoresSafeArea(edges: .bottom)
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

#Preview {
    TimelineView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
