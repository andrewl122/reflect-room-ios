//
//  ReflectionPromptView.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 11/08/25.
//

import SwiftUI

struct ReflectionPromptView: View {
    // MARK: - Properties
    var reflections: [ReflectionEntry]
    var isPremium: Bool
    @Binding var reflectionText: String   // ✅ Autofill selected text
    var selectedMood: String? = nil       // ✅ Mood passed from Check-In
    
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var promptSections: [PromptSection] = []
    @State private var isLoading = false
    @State private var selectedPrompt: String? = nil
    @State private var previousPrompts: Set<String> = []   // prevents repeats
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            
            // MARK: - Header
            HStack {
                Text(isPremium ? "✨ AI Reflection Prompts" : "🪞 Reflection Prompts")
                    .font(.title3.bold())
                    .foregroundColor(AppTheme.Colors.accent)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.accent))
                } else {
                    Button {
                        Haptics.tap()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            fetchPrompts(shuffle: true)
                        }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.Colors.accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Shuffle prompts")
                }
            }
            .padding(.horizontal, 4)
            
            // MARK: - Prompts
            if isLoading {
                loadingSkeleton
            } else if promptSections.isEmpty {
                Text("No prompts available right now. Try refreshing!")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(.vertical, 10)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        ForEach(promptSections) { section in
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                Text(section.title)
                                    .font(.headline)
                                    .foregroundColor(AppTheme.Colors.accent)
                                    .padding(.bottom, 2)
                                
                                ForEach(section.prompts, id: \.self) { prompt in
                                    PromptCard(
                                        prompt: prompt,
                                        isSelected: selectedPrompt == prompt,
                                        onSelect: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                selectedPrompt = prompt
                                                Haptics.tap()
                                                
                                                // ✅ Insert prompt into text box but allow typing over it
                                                if reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                    reflectionText = prompt + "\n\n"
                                                } else {
                                                    reflectionText += "\n\n" + prompt + "\n\n"
                                                }
                                                
                                                // ✅ Auto-dismiss modal when prompt is selected
                                                dismiss()
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.top, AppTheme.Spacing.sm)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radii.lg)
                .fill(AppTheme.Colors.cardBg(scheme))
                .shadow(color: .black.opacity(scheme == .dark ? 0.4 : 0.08),
                        radius: 4, x: 0, y: 3)
        )
        .onAppear { fetchPrompts() }
    }
    
    // MARK: - Fetch Prompts
    private func fetchPrompts(shuffle: Bool = false) {
        guard !isLoading else { return }
        isLoading = true
        
        let insights = ReflectionEntry.insightsSummary(from: reflections)
        let mode: PromptMode = isPremium ? .aiOpenAI : .local
        
        PromptEngine.generatePrompts(from: insights, selectedMood: selectedMood, mode: mode) { sections in
            DispatchQueue.main.async {
                var freshSections = sections
                
                // 🔁 Shuffle logic: remove previous questions and refill new ones
                if shuffle {
                    freshSections = freshSections.map { section in
                        let newPrompts = section.prompts.filter { !previousPrompts.contains($0) }
                        let refilled = newPrompts.isEmpty ? section.prompts.shuffled() : newPrompts
                        return PromptSection(title: section.title, prompts: Array(refilled.prefix(3)))
                    }
                }
                
                previousPrompts.formUnion(freshSections.flatMap { $0.prompts })
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    // ✅ Always show exactly 3 prompts per section
                    self.promptSections = freshSections.map { section in
                        let trimmed = Array(section.prompts.shuffled().prefix(3))
                        return PromptSection(title: section.title, prompts: trimmed)
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Loading Skeleton
    private var loadingSkeleton: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.Colors.cardBg(scheme).opacity(0.5))
                    .frame(height: 50)
                    .shimmering()
            }
        }
    }
}

// MARK: - Prompt Card
private struct PromptCard: View {
    var prompt: String
    var isSelected: Bool
    var onSelect: () -> Void
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Text(prompt)
                    .multilineTextAlignment(.leading)
                    .font(.body)
                    .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radii.lg)
                    .fill(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.cardBg(scheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radii.lg)
                            .stroke(isSelected ? AppTheme.Colors.accent : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.25), value: isSelected)
    }
}

// MARK: - Shimmer Effect (for loading)
extension View {
    func shimmering() -> some View {
        self
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [.white.opacity(0.4), .white.opacity(0.1), .white.opacity(0.4)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: 250)
                .mask(self)
                .animation(Animation.linear(duration: 1.4).repeatForever(autoreverses: false), value: UUID())
            )
    }
}

// MARK: - Preview
#Preview {
    ReflectionPromptView(
        reflections: [],
        isPremium: false,
        reflectionText: .constant(""),
        selectedMood: "Happy"
    )
    .environment(\.colorScheme, .light)
    .padding()
    .background(Color(.systemGroupedBackground))
}
