import SwiftUI

struct NotificationSettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pushService = PushNotificationService.shared
    @State private var profileService = ProfileService.shared

    // Local state for form
    @State private var isEnabled = true
    @State private var selectedHour = 9
    @State private var isSaving = false
    @State private var showingPermissionDenied = false

    // Delivery hour options (4 AM to 11 AM)
    private let hourOptions = Array(4...11)

    var body: some View {
        List {
            Section {
                Toggle("Daily Outfit Notifications", isOn: $isEnabled)
                    .tint(AppColors.slate)
                    .onChange(of: isEnabled) { _, newValue in
                        HapticManager.shared.light()
                        if newValue {
                            Task {
                                await requestPermissionIfNeeded()
                            }
                        }
                    }
            } footer: {
                Text("Get a personalized outfit suggestion each morning based on your wardrobe and the weather.")
                    .foregroundColor(AppColors.textMuted)
            }

            if isEnabled {
                Section {
                    Picker("Delivery Time", selection: $selectedHour) {
                        ForEach(hourOptions, id: \.self) { hour in
                            Text(formattedHour(hour))
                                .tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .onChange(of: selectedHour) { _, _ in
                        HapticManager.shared.selection()
                    }
                } header: {
                    Text("When would you like to receive your daily outfit?")
                }
            }

            // Show warning if system permissions are denied
            if pushService.authorizationStatus == .denied {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Notifications Disabled")
                                .font(.headline)
                        }

                        Text("You've disabled notifications for Styleum. To receive daily outfit suggestions, please enable notifications in Settings.")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)

                        Button(action: {
                            pushService.openSettings()
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Open Settings")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.backgroundSecondary)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await savePreferences()
                    }
                }
                .disabled(isSaving)
            }
        }
        .onAppear {
            loadCurrentPreferences()
            Task {
                await pushService.refreshAuthorizationStatus()
            }
        }
    }

    // MARK: - Helpers

    private func formattedHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"

        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }

    private func loadCurrentPreferences() {
        if let profile = profileService.currentProfile {
            isEnabled = profile.pushEnabled ?? true

            // Parse hour from time string
            if let timeString = profile.morningNotificationTime {
                let components = timeString.split(separator: ":")
                if let hourString = components.first, let hour = Int(hourString) {
                    selectedHour = hour
                }
            }
        }
    }

    private func requestPermissionIfNeeded() async {
        if pushService.authorizationStatus == .notDetermined {
            let granted = await pushService.requestAuthorization()
            if !granted {
                await MainActor.run {
                    isEnabled = false
                }
            }
        } else if pushService.authorizationStatus == .denied {
            await MainActor.run {
                showingPermissionDenied = true
            }
        }
    }

    private func savePreferences() async {
        // Guard against double-submit from rapid taps
        guard !isSaving else { return }
        isSaving = true

        let timeString = NotificationPreferences.timeString(from: selectedHour)
        let timezone = TimeZone.current.identifier

        do {
            let updatedProfile = try await StyleumAPI.shared.updateNotificationPreferences(
                enabled: isEnabled,
                time: timeString,
                timezone: timezone
            )

            // Update state on MainActor
            await MainActor.run {
                profileService.currentProfile = updatedProfile
                isSaving = false
            }

            // Small delay to ensure UI updates complete
            try? await Task.sleep(nanoseconds: 50_000_000)

            // Dismiss on MainActor
            await MainActor.run {
                HapticManager.shared.success()
                dismiss()
            }
        } catch {
            print("❌ Failed to save notification preferences: \(error)")
            await MainActor.run {
                isSaving = false
                HapticManager.shared.error()
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsScreen()
    }
}
