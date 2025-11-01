//
//  SettingsView.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 11/2/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // 🌈 Animated Reflect Room gradient background
            ReflectRoomBackground()

            VStack(spacing: 30) {
                // Header
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.top, 20)

                Text("Customize your reflection experience.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Placeholder setting options
                VStack(spacing: 16) {
                    settingsRow(icon: "lock.fill", title: "App Lock", subtitle: "Enable Face ID or Passcode")
                    settingsRow(icon: "icloud.fill", title: "iCloud Sync", subtitle: "Backup reflections automatically")
                    settingsRow(icon: "person.crop.circle.badge.checkmark", title: "Privacy Mode", subtitle: "Keep entries private")
                    settingsRow(icon: "paintbrush.fill", title: "Theme", subtitle: "Light / Dark / System")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.2))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 3)
                )
                .padding(.horizontal, 20)

                Spacer()

                // Footer
                VStack(spacing: 6) {
                    Text("Reflect Room v1.0")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Text("Created with purpose and reflection.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 30)
            }
            .padding()
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Settings Row Component
    private func settingsRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundColor(.purple)
                    .font(.system(size: 18, weight: .medium))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.6))
                .font(.system(size: 14))
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.light)
}
