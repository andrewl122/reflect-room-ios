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
    @Environment(\.colorScheme) private var scheme

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ReflectionEntry.timestamp, ascending: false)],
        animation: .default
    )
    private var reflections: FetchedResults<ReflectionEntry>

    @State private var groupingMode: GroupingMode = .month
    @Namespace private var animationNamespace

    enum GroupingMode: String, CaseIterable {
        case week = "Week"
        case month = "Month"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ReflectRoomBackground()

                if reflections.isEmpty {
                    VStack(spacing: AppTheme.Spacing.md) {
                        Text("No Reflections Yet")
                            .appHeadline()
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Your recorded reflections will appear here once you’ve saved a few check-ins.")
                            .subtleLabel()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding()
                } else {
                    VStack(spacing: AppTheme.Spacing.md) {
                        // MARK: - Grouping Toggle Picker
                        Picker("Grouping", selection: $groupingMode) {
                            ForEach(GroupingMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue)
                                    .fontWeight(mode == groupingMode ? .bold : .regular)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .animation(.easeInOut(duration: 0.35), value: groupingMode)

                        // MARK: - Animated Grouped List
                        ScrollViewReader { proxy in
                            List {
                                ForEach(groupedReflections.keys.sorted(by: >), id: \.self) { key in
                                    let entries = groupedReflections[key] ?? []
                                    Section {
                                        ForEach(entries) { entry in
                                            NavigationLink(destination: ReflectionDetailView(entry: entry)) {
                                                ReflectionCard(entry: entry, scheme: scheme)
                                                    .matchedGeometryEffect(id: entry.objectID, in: animationNamespace)
                                            }
                                            .listRowSeparator(.hidden)
                                            .listRowBackground(Color.clear)
                                        }
                                        .onDelete { indexSet in
                                            deleteItems(indexSet, in: key)
                                        }
                                    } header: {
                                        // Sticky section header
                                        HStack {
                                            Text(sectionTitle(for: key))
                                                .font(.headline)
                                            Spacer()
                                            Text("\(entries.count) \(entries.count == 1 ? "Reflection" : "Reflections")")
                                                .font(.caption)
                                                .foregroundColor(AppTheme.Colors.textSecondary)
                                        }
                                        .padding(.vertical, 4)
                                        .background(
                                            VisualEffectBlur(blurStyle: .systemMaterial)
                                                .opacity(0.8)
                                        )
                                    }
                                }
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .id(groupingMode) // triggers transition animation
                            .transition(.opacity.combined(with: .slide))
                            .animation(.easeInOut(duration: 0.35), value: groupingMode)
                        }
                    }
                }
            }
            .navigationTitle("Reflections")
            .navigationBarTitleDisplayMode(.large)
        }
        .background(ReflectRoomBackground())
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Grouping Logic
    private var groupedReflections: [Date: [ReflectionEntry]] {
        let calendar = Calendar.current
        switch groupingMode {
        case .month:
            return Dictionary(grouping: reflections) { entry in
                let date = entry.timestamp ?? Date()
                return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? Date()
            }
        case .week:
            return Dictionary(grouping: reflections) { entry in
                let date = entry.timestamp ?? Date()
                return calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? Date()
            }
        }
    }

    private func sectionTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        switch groupingMode {
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        case .week:
            let calendar = Calendar.current
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: date) ?? date
            formatter.dateFormat = "MMM d"
            let startString = formatter.string(from: date)
            let endString = formatter.string(from: endOfWeek)
            return "\(startString) – \(endString)"
        }
    }

    // MARK: - Delete Logic
    private func deleteItems(_ offsets: IndexSet, in key: Date) {
        guard var entries = groupedReflections[key] else { return }
        offsets.map { entries[$0] }.forEach(viewContext.delete)
        do {
            try viewContext.save()
            Haptics.tap()
        } catch {
            print("❌ Failed to delete reflection: \(error.localizedDescription)")
        }
    }
}

// MARK: - Reflection Card
private struct ReflectionCard: View {
    let entry: ReflectionEntry
    let scheme: ColorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Text(entry.moodDisplayIcon)
                .font(.largeTitle)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.moodDisplayTitle)
                    .appHeadline()
                Text(entry.timestamp ?? Date(), style: .date)
                    .subtleLabel()
            }

            Spacer()
        }
        .padding()
        .background(AppTheme.Colors.cardBg(scheme))
        .cornerRadius(AppTheme.Radii.lg)
        .shadow(
            color: .black.opacity(scheme == .dark ? 0.4 : 0.08),
            radius: 4, x: 0, y: 3
        )
    }

}

// MARK: - Subtle Blur Background for Sticky Headers
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

#Preview {
    TimelineView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
