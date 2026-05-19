//
//  NewReflectionView.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 11/09/25.
//

import SwiftUI
import CoreData

struct NewReflectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var scheme

    @State private var isPremiumUser: Bool = false

    // MARK: - Fetch Reflections (for prompt engine context)
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ReflectionEntry.timestamp, ascending: false)],
        animation: .default
    )
    private var reflections: FetchedResults<ReflectionEntry>

    // MARK: - UI State
    @State private var selectedMood: MoodType? = nil
    @State private var reflectionText: String = ""
    @State private var showPrompts: Bool = false

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {

                // MARK: Title
                Text("New Reflection")
                    .appHeadline()
                    .foregroundColor(AppTheme.Colors.accent)
                    .padding(.top)

                // MARK: Mood Selector
                VStack(alignment: .leading, spacing: 10) {
                    Text("How are you feeling?")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    // 3 columns mood grid
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 3),
                        spacing: 14
                    ) {
                        ForEach(MoodType.allCases, id: \.self) { mood in
                            moodButton(for: mood)
                        }
                    }
                    .padding(.top, 4)
                }

                // MARK: Reflection Text
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Thoughts")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $reflectionText)
                            .frame(minHeight: 160)
                            .padding(10)
                            .background(AppTheme.Colors.cardBg(scheme))
                            .cornerRadius(AppTheme.Radii.lg)
                            .shadow(color: .black.opacity(scheme == .dark ? 0.4 : 0.08),
                                    radius: 4, x: 0, y: 3)

                        if reflectionText.isEmpty {
                            Text("Write what’s on your mind...")
                                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.6))
                                .padding(14)
                        }
                    }
                }

                // MARK: Need Inspiration?
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        Haptics.tap()
                        withAnimation(.easeInOut) {
                            showPrompts.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                            Text("Need Inspiration?")
                            Spacer()
                            Image(systemName: showPrompts ? "chevron.up" : "chevron.down")
                        }
                        .font(.subheadline.bold())
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.Colors.accent.opacity(0.1))
                        .foregroundColor(AppTheme.Colors.accent)
                        .cornerRadius(AppTheme.Radii.lg)
                    }

                    if showPrompts {
                        ReflectionPromptView(
                            reflections: Array(reflections),
                            isPremium: isPremiumUser,
                            reflectionText: $reflectionText
                        )
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .padding(.top, 4)
                    }
                }

                // MARK: Save Button
                Button(action: saveReflection) {
                    Text("Save Reflection")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.Colors.accent)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.Radii.lg)
                        .shadow(color: .black.opacity(0.2),
                                radius: 4, x: 0, y: 3)
                }
                .padding(.top)
            }
            .padding()
        }
        .background(ReflectRoomBackground())
        .navigationTitle("Reflect")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Mood Button Builder (Hybrid Emoji)
    private func moodButton(for mood: MoodType) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedMood = mood
            }
        } label: {
            VStack(spacing: 4) {
                Text(mood.icon)
                    .font(.system(size: 40))
                    .padding(12)
                    .background(mood.color.opacity(0.35))
                    .clipShape(Circle())
                    .opacity(selectedMood == mood ? 1.0 : 0.5)
                    .scaleEffect(selectedMood == mood ? 1.12 : 1.0)

                Text(mood.title)
                    .font(.caption)
                    .foregroundColor(.black)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save Reflection
    private func saveReflection() {
        let trimmed = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let entry = ReflectionEntry(context: viewContext)
        entry.id = UUID()
        entry.timestamp = Date()
        entry.text = trimmed

        // Save using MoodType rawValue
        entry.mood = selectedMood?.storageValue ?? MoodType.neutral.storageValue

        do {
            try viewContext.save()
            Haptics.success()
            reflectionText = ""
            selectedMood = nil
        } catch {
            print("❌ Failed to save reflection: \(error.localizedDescription)")
        }
    }
}

#Preview {
    NewReflectionView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
