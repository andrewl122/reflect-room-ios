//
//  HomeView.swift
//  Reflect Room
//
//  Optimized by Ace (ChatGPT)
//

import SwiftUI
import Charts
import CoreData

// MARK: - MoodStat Model
struct MoodStat: Identifiable, Equatable {
    var id = UUID()
    var mood: MoodType
    var count: Int

    static func == (lhs: MoodStat, rhs: MoodStat) -> Bool {
        lhs.id == rhs.id &&
        lhs.mood == rhs.mood &&
        lhs.count == rhs.count
    }
}

// MARK: - Mood Category for Sheet Selection
enum MoodCategory: String, CaseIterable, Identifiable {
    case positive
    case neutralReflective
    case difficult

    var id: String { rawValue }

    var title: String {
        switch self {
        case .positive: return "Positive Emotions"
        case .neutralReflective: return "Neutral & Reflective"
        case .difficult: return "Difficult Emotions"
        }
    }

    var subtitle: String {
        switch self {
        case .positive: return "Tap what feels closest right now."
        case .neutralReflective: return "Somewhere in the middle, just noticing."
        case .difficult: return "Name what’s heavy so you can release it."
        }
    }

    var moods: [MoodType] {
        switch self {
        case .positive:
            return [.happy, .peaceful, .grateful]
        case .neutralReflective:
            return [.neutral, .reflective, .tired]
        case .difficult:
            return [.sad, .stressed, .anxious]
        }
    }

    var icon: String {
        switch self {
        case .positive: return "🌞"
        case .neutralReflective: return "🌤"
        case .difficult: return "🌧"
        }
    }
}

// MARK: - Routing
private enum HomeRoute: Hashable {
    case checkIn(MoodType)
}

// MARK: - HomeView
struct HomeView: View {

    // Navigation / Tabs
    @State private var selectedTab: Tab = .home
    @State private var isTabBarHidden = false
    @State private var navPath: [HomeRoute] = []

    // Mood sheet
    @State private var activeCategory: MoodCategory? = nil
    @State private var isMoodSheetPresented = false

    // Banner state
    @State private var lastReflectionCount: Int = 0
    @State private var bannerMessage: String = ""

    @Environment(\.colorScheme) var scheme
    @Environment(\.managedObjectContext) private var viewContext

    // Notification permission
    @AppStorage("didRequestNotificationPermission")
    private var didRequestNotificationPermission = false

    // AppStorage from CheckInView → HomeView
    @AppStorage("lastMoodBannerMessage") private var storedBannerMessage: String = ""
    @AppStorage("lastMoodType") private var storedMoodTypeRaw: String = ""

    private var storedMoodType: MoodType? {
        MoodType(rawValue: storedMoodTypeRaw)
    }

    // MARK: - Core Data
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ReflectionEntry.timestamp, ascending: false)],
        animation: .default
    )
    private var reflections: FetchedResults<ReflectionEntry>

    // MARK: - Mood Data
    private var moodData: [MoodStat] {
        guard let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) else {
            return []
        }

        let recent = reflections.filter {
            if let t = $0.timestamp { return t >= startDate }
            return false
        }

        let moods: [MoodType] = [
            .happy, .peaceful, .grateful,
            .neutral, .reflective, .tired,
            .sad, .stressed, .anxious
        ]

        return moods.compactMap { mood in
            let count = recent.filter { $0.moodType == mood }.count
            return count > 0 ? MoodStat(mood: mood, count: count) : nil
        }
    }

    // MARK: - Streaks
    private var currentStreakValue: Int {
        ReflectionEntry.currentStreak(from: Array(reflections))
    }

    private var longestStreakValue: Int {
        ReflectionEntry.longestStreak(from: Array(reflections))
    }

    // MARK: - Greeting
    private var currentGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning, Andrew 🌅"
        case 12..<17: return "Good afternoon, Andrew ☀️"
        case 17..<22: return "Good evening, Andrew 🌙"
        default: return "Hi Andrew 🌌"
        }
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            
            // MAIN TAB CONTENT
            if selectedTab == .home {
                NavigationStack(path: $navPath) {
                    ZStack {
                        ReflectRoomBackground()
                            .ignoresSafeArea()
                        
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: AppTheme.Spacing.lg) {
                                
                                Spacer(minLength: 20)
                                
                                greetingSection
                                
                                if !bannerMessage.isEmpty {
                                    MoodBannerView(message: bannerMessage)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                        .onAppear {
                                            // Auto-dismiss after 3 seconds
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                withAnimation(.easeOut(duration: 0.25)) {
                                                    bannerMessage = ""
                                                }
                                            }
                                        }
                                }
                                
                                moodCategorySection
                                
                                moodOverviewSection
                                
                                Spacer(minLength: 40)
                            }
                            .padding()
                        }
                        .scrollBounceBehavior(.automatic)
                    }
                    .navigationTitle("")
                    .navigationBarHidden(true)
                    .navigationDestination(for: HomeRoute.self) { route in
                        switch route {
                        case .checkIn(let mood):
                            CheckInView(
                                isTabBarHidden: $isTabBarHidden,
                                mood: mood
                            )
                        }
                    }
                }
            }
            else if selectedTab == .timeline {
                TimelineView()
            }
            else if selectedTab == .settings {
                SettingsView()
            }
            
            // TAB BAR
            if !isTabBarHidden {
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        
        // Mood sheet (category selection)
        .sheet(isPresented: $isMoodSheetPresented) {
            if let category = activeCategory {
                moodSelectionSheet(for: category)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        
        // On appear: notification permissions + baseline reflection count
        .onAppear {
            lastReflectionCount = reflections.count
            
            if !didRequestNotificationPermission {
                NotificationManager.shared.requestPermissionAndScheduleDefaults(context: viewContext)
                didRequestNotificationPermission = true
            }
            
            // If there is a leftover stored banner (edge case after app relaunch),
            // show it once then clear.
            if !storedBannerMessage.isEmpty {
                withAnimation(.spring()) {
                    bannerMessage = storedBannerMessage
                }
                storedBannerMessage = ""
                storedMoodTypeRaw = ""
            }
        }
        
        // Detect new reflections and show banner only when a *new* one is saved
        .onChange(of: reflections.count) { newCount in
            guard newCount > lastReflectionCount else {
                lastReflectionCount = newCount
                return
            }
            
            lastReflectionCount = newCount
            
            // Only show banner if CheckInView wrote something into AppStorage
            guard !storedBannerMessage.isEmpty else { return }
            
            // Show banner with animation
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                bannerMessage = storedBannerMessage
            }
            
            // Fade-out after a delay (recommended)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.35)) {
                    bannerMessage = ""
                }
                
                // Fully clear AppStorage after fade-out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    storedBannerMessage = ""
                    storedMoodTypeRaw = ""
                }
            }
        }
    }

    // MARK: - Greeting + Streaks Section
    private var greetingSection: some View {
        VStack(spacing: 12) {

            Text(currentGreeting)
                .font(.title3.bold())
                .foregroundColor(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Divider().padding(.horizontal)

            HStack(spacing: 16) {
                streakBox(title: "Current streak", value: currentStreakValue)
                Spacer()
                streakBox(title: "Longest streak", value: longestStreakValue)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radii.lg)
                .fill(AppTheme.Colors.cardBg(scheme).opacity(0.4))
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        )
    }

    private func streakBox(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)

            Text(dayLabel(value))
                .font(.headline)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }

    private func dayLabel(_ value: Int) -> String {
        value == 1 ? "1 day" : "\(value) days"
    }

    // MARK: - Mood Category Section
    private var moodCategorySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {

            Text("Tap a mood category to check in")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.horizontal, 4)

            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(MoodCategory.allCases) { category in
                    categoryCard(for: category)
                }
            }
        }
    }

    private func categoryCard(for category: MoodCategory) -> some View {
        Button {
            Haptics.tap()
            activeCategory = category
            isMoodSheetPresented = true
        } label: {
            HStack(spacing: 14) {
                Text(category.icon)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.title)
                        .font(.subheadline.bold())
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text(category.subtitle)
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .minimumScaleFactor(0.8)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.8))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radii.lg)
                    .fill(Color.white.opacity(scheme == .dark ? 0.06 : 0.2))
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Mood Sheet
    private func moodSelectionSheet(for category: MoodCategory) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 40, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            Text(category.title)
                .font(.headline)

            Text(category.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            ForEach(category.moods, id: \.self) { mood in
                Button {
                    Haptics.tap()
                    isMoodSheetPresented = false

                    // Navigate to CheckInView for this mood
                    navPath.append(.checkIn(mood))
                } label: {
                    HStack(spacing: 12) {
                        Text(mood.icon)
                            .font(.system(size: 32))
                            .padding(8)
                            .background(mood.color.opacity(0.25))
                            .clipShape(Circle())

                        VStack(alignment: .leading) {
                            Text(mood.title)
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)

                            Text("Reflect from this feeling.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button("Cancel") {
                isMoodSheetPresented = false
            }
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)

        }
        .padding(20)
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Mood Overview
    private var moodOverviewSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {

            Text("Your Mood Overview")
                .appHeadline()
                .foregroundColor(AppTheme.Colors.accent)

            if moodData.isEmpty {
                Text("No reflections yet. Start your first check-in today!")
                    .subtleLabel()
                    .multilineTextAlignment(.center)
            } else {
                MoodChartCard(moodData: moodData, scheme: scheme)
            }
        }
        .padding(.top)
    }
}

// MARK: - Mood Chart Card
private struct MoodChartCard: View {
    let moodData: [MoodStat]
    let scheme: ColorScheme
    @State private var showInsightsView = false
    @Environment(\.managedObjectContext) private var viewContext

    // Need reflections for MoodInsightsView
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ReflectionEntry.timestamp, ascending: false)],
        animation: .default
    )
    private var reflections: FetchedResults<ReflectionEntry>

    var body: some View {
        Button {
            Haptics.tap()
            showInsightsView = true
        } label: {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: scheme == .dark
                                       ? [AppTheme.Colors.accent.opacity(0.25), Color.black.opacity(0.4)]
                                       : [AppTheme.Colors.accent.opacity(0.15), Color.blue.opacity(0.1)]
                                      ),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(AppTheme.Radii.lg)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                VStack(spacing: AppTheme.Spacing.md) {

                    Chart {
                        ForEach(moodData) { stat in
                            BarMark(
                                x: .value("Mood", stat.mood.icon),
                                y: .value("Count", stat.count)
                            )
                            .foregroundStyle(stat.mood.color)
                            .cornerRadius(6)
                            .annotation {
                                Text("\(stat.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(height: 180)
                    .padding(.horizontal)
                    .chartLegend(.hidden)
                    .chartYAxis(.hidden)

                    HStack(spacing: 14) {
                        ForEach(moodData, id: \.mood) { stat in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(stat.mood.color)
                                    .frame(width: 10, height: 10)

                                Text(stat.mood.title)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding(.vertical, AppTheme.Spacing.md)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showInsightsView) {
            MoodInsightsView(reflections: reflections)
        }
    }
}

// MARK: - Mood Banner View
private struct MoodBannerView: View {
    let message: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.accent)

            Text(message)
                .font(.footnote)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radii.lg)
                .fill(AppTheme.Colors.cardBg(scheme).opacity(0.9))
                .shadow(
                    color: .black.opacity(scheme == .dark ? 0.25 : 0.08),
                    radius: 6, x: 0, y: 3
                )
        )
        .padding(.horizontal, 4)
    }
}

// MARK: - Preview
#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
