//
//  SettingsView.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 11/2/25.
//

import SwiftUI
import UserNotifications
import CoreData

struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - Reminder States
    @State private var remindersEnabled = false
    @State private var reminderTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var showSaveConfirmation = false
    @State private var showTimePicker = false

    var body: some View {
        ZStack {
            ReflectRoomBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // MARK: - Header
                    VStack(spacing: 6) {
                        Text("Settings")
                            .appTitle()
                        Text("Customize your reflection experience.")
                            .subtleLabel()
                    }
                    .padding(.top, 20)

                    // MARK: - Reflection Reminder Section
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.Colors.accentSoft)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(AppTheme.Colors.accent)
                                    .font(.system(size: 18, weight: .medium))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reflection Reminders")
                                    .appHeadline()
                                Text("Receive a gentle nudge to reflect daily.")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                        }

                        // MARK: - Toggle
                        Toggle("Enable Daily Reminder", isOn: $remindersEnabled.animation(.spring(response: 0.4, dampingFraction: 0.8)))
                            .onChange(of: remindersEnabled) { newValue in
                                Haptics.tap()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showTimePicker = newValue
                                }

                                if newValue {
                                    // Use new API: combines permission + scheduling
                                    NotificationManager.shared.requestPermissionAndScheduleDefaults(context: viewContext)
                                } else {
                                    NotificationManager.shared.cancelReminders()
                                }
                            }

                        // MARK: - Custom Time Picker
                        if remindersEnabled && showTimePicker {
                            VStack(spacing: AppTheme.Spacing.md) {
                                DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.wheel)
                                    .labelsHidden()
                                    .padding(.bottom, AppTheme.Spacing.sm)

                                Button(action: {
                                    Haptics.tap()
                                    NotificationManager.shared.scheduleCustomReminder(at: reminderTime, context: viewContext)
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        showTimePicker = false
                                        showSaveConfirmation = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            showSaveConfirmation = false
                                        }
                                    }
                                }) {
                                    Text("Save Reminder")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(AppTheme.Colors.accent)
                                        .cornerRadius(AppTheme.Radii.md)
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                }
                                .padding(.top, 8)

                                if showSaveConfirmation {
                                    Text("✅ Reminder saved successfully!")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .transition(.opacity)
                                }
                            }
                            .transition(.opacity.combined(with: .slide))
                        }
                    }
                    .padding()
                    .cardBackground(scheme)
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: remindersEnabled)
                    .padding(.bottom, remindersEnabled ? 8 : 0)

                    // MARK: - Other Settings
                    VStack(spacing: AppTheme.Spacing.sm) {
                        settingsRow(icon: "lock.fill", title: "App Lock", subtitle: "Enable Face ID or Passcode")
                        settingsRow(icon: "icloud.fill", title: "iCloud Sync", subtitle: "Backup reflections automatically")
                        settingsRow(icon: "person.crop.circle.badge.checkmark", title: "Privacy Mode", subtitle: "Keep entries private")
                        settingsRow(icon: "paintbrush.fill", title: "Theme", subtitle: "Light / Dark / System")
                    }
                    .padding(.vertical, AppTheme.Spacing.md)
                    .cardBackground(scheme)

                    Spacer(minLength: 50)

                    // MARK: - Footer
                    VStack(spacing: 4) {
                        Text("Reflect Room v1.0")
                            .font(.footnote)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        Text("Created with purpose and reflection.")
                            .font(.caption2)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(.bottom, 30)
                }
                .padding()
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Settings Row
    private func settingsRow(icon: String, title: String, subtitle: String) -> some View {
        Button {
            Haptics.tap()
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accentSoft)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundColor(AppTheme.Colors.accent)
                        .font(.system(size: 18, weight: .medium))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .appHeadline()
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.6))
                    .font(.system(size: 14))
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .preferredColorScheme(.light)
}
