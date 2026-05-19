//
//  Theme.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 11/1/25.
//

import SwiftUI

// MARK: - Design Tokens
enum AppTheme {
    enum Colors {
        // Brand Accent
        static let accent      = Color.purple
        static let accentSoft  = Color.purple.opacity(0.18)
        static let successSoft = Color.green.opacity(0.22)
        static let dangerSoft  = Color.red.opacity(0.18)

        // 🔤 Text: locked for light backgrounds
        // Anything that would normally flip white in Dark Mode now stays dark & readable.
        static let textPrimary   = Color.black.opacity(0.9)
        static let textSecondary = Color.black.opacity(0.6)

        // 🧾 Card Background: stable, soft, non-adaptive
        // Used by cardBg(_:) everywhere (Home, Settings, Timeline, etc.)
        static let cardBgBase = Color.white.opacity(0.92)

        static func cardBg(_ scheme: ColorScheme) -> Color {
            cardBgBase
        }
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radii {
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
        static let xl: CGFloat = 24
    }
}

// MARK: - Text Styles
struct TitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.largeTitle, design: .rounded).bold())
            .foregroundColor(AppTheme.Colors.textPrimary)
            .tracking(0.2)
    }
}

struct HeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.title3, design: .rounded).weight(.semibold))
            .foregroundColor(AppTheme.Colors.textPrimary)
    }
}

struct BodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.body, design: .rounded))
            .foregroundColor(AppTheme.Colors.textPrimary)
    }
}

struct SubtleLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.callout, design: .rounded))
            .foregroundColor(AppTheme.Colors.textSecondary)
    }
}

extension View {
    func appTitle() -> some View { modifier(TitleStyle()) }
    func appHeadline() -> some View { modifier(HeadlineStyle()) }
    func appBody() -> some View { modifier(BodyStyle()) }
    func subtleLabel() -> some View { modifier(SubtleLabelStyle()) }

    /// Consistent card background with radius + shadow
    func cardBackground(_ scheme: ColorScheme,
                        padding: CGFloat = AppTheme.Spacing.md) -> some View {
        self
            .background(AppTheme.Colors.cardBg(scheme))
            .cornerRadius(AppTheme.Radii.lg)
            .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
            .padding(padding)
    }
}

// MARK: - Haptics
enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}

// MARK: - Animated Streak Bar
struct StreakBar: View {
    let value: Double   // 0...1
    @Environment(\.colorScheme) private var scheme
    @State private var anim: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppTheme.Radii.sm)
                    .fill(AppTheme.Colors.cardBg(scheme).opacity(0.6))

                RoundedRectangle(cornerRadius: AppTheme.Radii.sm)
                    .fill(AppTheme.Colors.textPrimary.opacity(0.85))
                    .frame(width: max(0, min(geo.size.width * anim, geo.size.width)))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8),
                               value: anim)
            }
        }
        .frame(height: 10)
        .onAppear { anim = value }
    }
}
