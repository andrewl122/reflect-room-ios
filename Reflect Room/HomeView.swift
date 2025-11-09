//
//  HomeView.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 10/30/25.
//

import SwiftUI
import Charts
import CoreData

// MARK: - MoodStat Model
struct MoodStat: Identifiable, Equatable {
    var id = UUID()
    var mood: String
    var count: Int
    var emoji: String

    static func == (lhs: MoodStat, rhs: MoodStat) -> Bool {
        lhs.id == rhs.id &&
        lhs.mood == rhs.mood &&
        lhs.count == rhs.count &&
        lhs.emoji == rhs.emoji
    }
}

// MARK: - HomeView
struct HomeView: View {
    @State private var selectedMood: String? = nil
    @State private var navigateToCheckIn = false
    @State private var selectedTab: Tab = .home
    @State private var showInsightsView = false
    @State private var isTabBarHidden = false
    @Environment(\.colorScheme) var scheme
    
    @AppStorage("didRequestNotificationPermission") private var didRequestNotificationPermission = false
    @Environment(\.managedObjectContext) private var viewContext


    // MARK: - Core Data
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ReflectionEntry.timestamp, ascending: false)],
        animation: .default
    )
    private var reflections: FetchedResults<ReflectionEntry>

    // MARK: - Mood Data
    private var moodData: [MoodStat] {
        let moods = ["Happy", "Okay", "Sad", "Anxious", "Angry"]
        let emojis = ["😊", "😐", "😢", "😰", "😠"]
        var stats: [MoodStat] = []

        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let recent = reflections.filter {
            if let t = $0.timestamp { return t >= startDate }
            return false
        }

        for (i, mood) in moods.enumerated() {
            let count = recent.filter { $0.mood == mood }.count
            if count > 0 {
                stats.append(MoodStat(mood: mood, count: count, emoji: emojis[i]))
            }
        }
        return stats
    }

    // MARK: - Greeting Logic
    private var currentGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning, Andrew 🌅"
        case 12..<17:
            return "Good afternoon, Andrew ☀️"
        case 17..<22:
            return "Good evening, Andrew 🌙"
        default:
            return "Hi Andrew 🌌"
        }
    }

    private var reflectionSummary: String {
        let thisWeek = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let recent = reflections.filter { ($0.timestamp ?? .distantPast) > thisWeek }
        let count = recent.count
        if count == 0 {
            return "No reflections this week yet — today’s a great time to start."
        } else if count == 1 {
            return "You’ve checked in once this week — nice start!"
        } else {
            return "You’ve checked in \(count) times this week — keep that consistency going!"
        }
    }

    private var lastMoodMessage: String {
        guard let lastMood = reflections.first?.mood else {
            return "Tap your mood below to begin your next reflection."
        }

        let messages: [String]

        switch lastMood.lowercased() {
        case "happy":
            messages = [
                "You’ve been radiating good energy lately — keep leaning into that joy.",
                "Your reflections show gratitude and light — beautiful work staying positive.",
                "You seem to be in a great rhythm lately. Savor those little wins.",
                "Your last entry felt peaceful — sounds like your spirit’s in a good place.",
                "You’ve been finding joy in the small things. That’s powerful self-care."
            ]
        case "okay":
            messages = [
                "You’re holding steady — sometimes balance is the best place to be.",
                "Your recent reflections show calm and clarity. Keep that grounded energy.",
                "Even ‘okay’ days matter — they remind you of your progress.",
                "You’ve been consistent and thoughtful — that stability pays off.",
                "Not every day is fireworks, and that’s okay. Steady feels safe."
            ]
        case "sad":
            messages = [
                "Your last reflection carried some weight. Give yourself space to heal.",
                "You’ve been processing something deep — it’s okay to slow down.",
                "Sad moments show you what matters most. Let them move through gently.",
                "Your heart sounded heavy last time. Remember: reflection itself is healing.",
                "You’ve been brave enough to feel — that’s strength, not weakness."
            ]
        case "anxious":
            messages = [
                "Your recent reflections showed tension — maybe take a slow breath before you write.",
                "You’ve been carrying a lot in your mind. Let today’s check-in help release it.",
                "Your thoughts seemed restless lately — grounding yourself here can help.",
                "You’ve been in your head a lot lately. Let’s bring you back to calm.",
                "Your reflections reveal awareness — that’s the first step toward peace."
            ]
        case "angry":
            messages = [
                "You’ve had fire in your words recently — reflection helps you channel it constructively.",
                "Your emotions have been intense. Use this space to transform them into clarity.",
                "You’ve been feeling that spark of frustration — let’s turn it into focus.",
                "You’ve been processing anger lately — journaling can cool the storm.",
                "Your last reflection carried heat. Let’s redirect that energy into healing."
            ]
        default:
            messages = ["Tap your mood below to begin your next reflection."]
        }

        return messages.randomElement() ?? "Tap your mood below to begin your next reflection."
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            if selectedTab == .home {
                NavigationView {
                    ZStack {
                        ReflectRoomBackground()

                        VStack(spacing: AppTheme.Spacing.lg) {
                            Spacer(minLength: 20)
                            greetingSection
                            moodButtonRow

                            NavigationLink(
                                destination: CheckInView(
                                    isTabBarHidden: $isTabBarHidden,
                                    selectedMood: selectedMood ?? "Unknown"
                                ),
                                isActive: $navigateToCheckIn
                            ) { EmptyView() }

                            moodOverviewSection
                            Spacer(minLength: 40)
                        }
                        .padding()
                    }
                }
            } else if selectedTab == .timeline {
                TimelineView()
            } else if selectedTab == .settings {
                SettingsView()
            }

            if !isTabBarHidden {
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .onAppear {
            if !didRequestNotificationPermission {
                NotificationManager.shared.requestPermissionAndScheduleDefaults(context: viewContext)
                didRequestNotificationPermission = true
                print("🔔 Notification permission requested and reminders scheduled.")
            }
        }
    }

    // MARK: - Greeting Section
    private var greetingSection: some View {
        VStack(spacing: 10) {
            Text(currentGreeting)
                .font(.title3.bold())
                .foregroundColor(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(reflectionSummary)
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

//            Text(lastMoodMessage)
//                .font(.footnote)
//                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.9))
//                .multilineTextAlignment(.center)
//                .padding(.horizontal, 20)
//                .padding(.top, 4)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radii.lg)
                .fill(AppTheme.Colors.cardBg(scheme).opacity(0.4))
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal)
    }

    // MARK: - Mood Buttons
    private var moodButtonRow: some View {
        HStack(spacing: 20) {
            moodButton("😊", mood: "Happy")
            moodButton("😐", mood: "Okay")
            moodButton("😢", mood: "Sad")
            moodButton("😰", mood: "Anxious")
            moodButton("😠", mood: "Angry")
        }
        .padding(.bottom, AppTheme.Spacing.sm)
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
                    .padding(.horizontal)
            } else {
                Button {
                    Haptics.tap()
                    showInsightsView = true
                } label: {
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: scheme == .dark
                                ? [AppTheme.Colors.accent.opacity(0.25),
                                   Color.black.opacity(0.4)]
                                : [AppTheme.Colors.accent.opacity(0.15),
                                   Color.blue.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .cornerRadius(AppTheme.Radii.lg)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                        VStack(spacing: AppTheme.Spacing.md) {
                            Chart {
                                ForEach(moodData) { stat in
                                    BarMark(
                                        x: .value("Mood", stat.emoji),
                                        y: .value("Count", stat.count)
                                    )
                                    .foregroundStyle(colorForMood(stat.mood))
                                    .cornerRadius(6)
                                    .annotation {
                                        Text("\(stat.count)")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.Colors.textSecondary)
                                    }
                                }
                            }
                            .frame(height: 180)
                            .padding(.horizontal)
                            .chartLegend(.hidden)
                            .chartYAxis(.hidden)
                            .animation(.easeInOut(duration: 0.4), value: moodData)

                            HStack(spacing: 14) {
                                ForEach(moodData, id: \.mood) { stat in
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(colorForMood(stat.mood))
                                            .frame(width: 10, height: 10)
                                        Text(stat.mood)
                                            .font(.caption)
                                            .foregroundColor(AppTheme.Colors.textPrimary)
                                    }
                                }
                            }
                            .padding(.bottom, 6)
                            .padding(.top, 4)
                        }
                        .padding(.vertical, AppTheme.Spacing.md)
                    }
                    .padding(.horizontal)
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showInsightsView) {
                    MoodInsightsView(reflections: reflections)
                }
            }
        }
        .padding(.top)
    }

    // MARK: - Mood Button Template
    private func moodButton(_ emoji: String, mood: String) -> some View {
        Button {
            selectedMood = mood
            navigateToCheckIn = true
            Haptics.tap()
        } label: {
            VStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 44))
                Text(mood)
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
            }
            .padding(AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radii.md)
                    .fill(Color.white.opacity(scheme == .dark ? 0.05 : 0.2))
                    .shadow(radius: 1)
            )
        }
    }
    

    // MARK: - Mood Color Mapping
    private func colorForMood(_ mood: String) -> Color {
        switch mood.lowercased() {
        case "happy": return .yellow
        case "okay": return .gray
        case "sad": return .blue
        case "anxious": return .orange
        case "angry": return .red
        default: return AppTheme.Colors.accent
        }
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
