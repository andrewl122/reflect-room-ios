//
//  CustomTabBar.swift
//  ReflectRoom
//
//  Created by Andrew Lawrence on 10/30/25.
//

import SwiftUI

// MARK: - Tab Enum
enum Tab {
    case home
    case timeline
    case settings
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack {
            Spacer()

            // Home Tab
            Button(action: { selectedTab = .home }) {
                VStack(spacing: 6) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 22))
                    Text("Home")
                        .font(.caption)
                }
                .foregroundColor(selectedTab == .home ? .purple : .gray)
            }

            Spacer()

            // Reflections Tab
            Button(action: { selectedTab = .timeline }) {
                VStack(spacing: 6) {
                    Image(systemName: "sparkles.tv.fill") 
                        .font(.system(size: 22))
                    Text("Reflections")
                        .font(.caption)
                }
                .foregroundColor(selectedTab == .timeline ? .purple : .gray)
            }

            Spacer()

            // Settings Tab
            Button(action: { selectedTab = .settings }) {
                VStack(spacing: 6) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22))
                    Text("Settings")
                        .font(.caption)
                }
                .foregroundColor(selectedTab == .settings ? .purple : .gray)
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        )
        .padding(.horizontal)
    }
}

// MARK: - Preview
#Preview {
    CustomTabBar(selectedTab: .constant(.home))
        .previewLayout(.sizeThatFits)
        .padding()
}
