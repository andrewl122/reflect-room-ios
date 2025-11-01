//
//  CustomTabBar.swift
//  ReflectRoom
//
//  Created by Andrew Lawrence on 10/30/25.
//

import SwiftUI

enum Tab: String, CaseIterable {
    case home = "house"
    case timeline = "calendar"
    case settings = "gear"
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Background blur for modern glassy look
            VisualEffectView(effect: UIBlurEffect(style: colorScheme == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight))
                .ignoresSafeArea(edges: .bottom)

            HStack {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: tab.rawValue)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(selectedTab == tab ? .purple : .gray.opacity(0.7))
                                .scaleEffect(selectedTab == tab ? 1.15 : 1.0)

                            Text(label(for: tab))
                                .font(.caption2)
                                .foregroundColor(selectedTab == tab ? .purple : .gray.opacity(0.7))
                        }
                        .padding(.vertical, 8)
                    }

                    Spacer()
                }
            }
            .padding(.bottom, 8)
            .background(Color.clear)
        }
        // 🔧 Critical: Remove gap above the tab bar
        .ignoresSafeArea(edges: .bottom)
        .frame(height: 75)
    }

    // MARK: - Label helper
    private func label(for tab: Tab) -> String {
        switch tab {
        case .home: return "Home"
        case .timeline: return "Reflections"
        case .settings: return "Settings"
        }
    }
}

// MARK: - UIKit blur bridge for glass background
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}

#Preview {
    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        VStack {
            Spacer()
            CustomTabBar(selectedTab: .constant(.home))
        }
    }
}
