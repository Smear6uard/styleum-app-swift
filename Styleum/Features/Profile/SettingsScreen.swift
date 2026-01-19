import SwiftUI

struct SettingsScreen: View {
    @Environment(AppCoordinator.self) private var coordinator
    @AppStorage("temperatureUnit") private var temperatureUnit = "fahrenheit"
    @State private var tierManager = TierManager.shared
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var profileService = ProfileService.shared
    @State private var isRestoring = false
    @State private var showSignOutConfirmation = false
    @State private var isSigningOut = false
    @State private var showRestoreSuccess = false
    @State private var versionTapCount = 0
    @State private var showSignOutGlow = false
    @State private var showProScreenshot = false
    @State private var showRetakeStyleQuizConfirmation = false
    @State private var showTemperatureUnitPicker = false

    var body: some View {
        List {
            Section("Preferences") {
                ListRow(
                    title: "Temperature Unit",
                    action: {
                        HapticManager.shared.light()
                        showTemperatureUnitPicker = true
                    }
                ) {
                    Image(symbol: .sunMax)
                        .foregroundColor(AppColors.textSecondary)
                } trailing: {
                    Text(temperatureUnit == "celsius" ? "°C" : "°F")
                        .foregroundColor(AppColors.textSecondary)
                }

                ListRow(
                    title: "Notifications",
                    action: {
                        coordinator.navigate(to: .notificationSettings)
                    }
                ) {
                    Image(systemName: "bell")
                        .foregroundColor(AppColors.textSecondary)
                } trailing: {
                    EmptyView()
                }

                ListRow(
                    title: "Retake Style Quiz",
                    subtitle: "Update your style preferences",
                    action: {
                        HapticManager.shared.light()
                        showRetakeStyleQuizConfirmation = true
                    }
                ) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(AppColors.textSecondary)
                } trailing: {
                    EmptyView()
                }
            }

            Section("Subscription") {
                // Pro Status Row - tappable for free users
                Button {
                    if !tierManager.isPro {
                        coordinator.navigate(to: .subscription)
                    }
                } label: {
                    HStack {
                        Image(systemName: tierManager.isPro ? "checkmark.seal.fill" : "seal")
                            .foregroundStyle(tierManager.isPro ? AppColors.success : AppColors.textMuted)

                        Text(tierManager.isPro ? "Styleum Pro" : "Free Plan")
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)

                        Spacer()

                        if !tierManager.isPro {
                            Text("Upgrade")
                                .font(AppTypography.labelSmall)
                                .foregroundStyle(AppColors.brownPrimary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)

                // Manage Subscription (Pro only)
                if tierManager.isPro {
                    ListRow(
                        title: "Manage Subscription",
                        action: { openSubscriptionManagement() }
                    ) {
                        Image(systemName: "creditcard")
                            .foregroundColor(AppColors.textSecondary)
                    } trailing: {
                        Image(systemName: "arrow.up.right")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textMuted)
                    }
                }

                // Restore Purchases
                ListRow(
                    title: "Restore Purchases",
                    action: { Task { await restorePurchases() } }
                ) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(AppColors.textSecondary)
                } trailing: {
                    if isRestoring {
                        ProgressView()
                    } else {
                        EmptyView()
                    }
                }
            }

            Section("Referral") {
                ListRow(
                    title: "Invite Friends",
                    subtitle: "Get free Pro time",
                    action: {
                        coordinator.navigate(to: .referral)
                    }
                ) {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(AppColors.textSecondary)
                } trailing: {
                    EmptyView()
                }
            }

            Section("Account") {
                ListRow(
                    title: "Delete Account",
                    action: {
                        coordinator.navigate(to: .deleteAccount)
                    }
                ) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                } trailing: {
                    EmptyView()
                }
                .foregroundColor(.red)
            }

            Section("Legal") {
                ListRow(
                    title: "Privacy Policy",
                    action: {
                        openURL("https://styleum.xyz/privacy")
                    }
                ) {
                    Image(systemName: "hand.raised")
                        .foregroundColor(AppColors.textSecondary)
                } trailing: {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textMuted)
                }

                ListRow(
                    title: "Terms of Service",
                    action: {
                        openURL("https://styleum.xyz/terms")
                    }
                ) {
                    Image(systemName: "doc.text")
                        .foregroundColor(AppColors.textSecondary)
                } trailing: {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textMuted)
                }
            }

            Section("Support") {
                ListRow(
                    title: "Help & FAQ",
                    action: {
                        openURL("https://styleum.xyz/faq")
                    }
                ) {
                    Image(symbol: .info)
                        .foregroundColor(AppColors.textSecondary)
                } trailing: {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textMuted)
                }

                ListRow(
                    title: "Contact Us",
                    action: {
                        openURL("mailto:support@styleum.xyz")
                    }
                ) {
                    Image(symbol: .settings)
                        .foregroundColor(AppColors.textSecondary)
                } trailing: {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textMuted)
                }
            }

            // TEMPORARY: Screenshot button for App Store
            Section {
                Button {
                    showProScreenshot = true
                } label: {
                    Label("Pro Screenshot", systemImage: "camera")
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Section {
                // Polished Sign Out Button
                Button {
                    HapticManager.shared.medium()
                    withAnimation(.easeOut(duration: 0.15)) {
                        showSignOutGlow = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        showSignOutConfirmation = true
                        showSignOutGlow = false
                    }
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        ZStack {
                            // Glow effect on press
                            Circle()
                                .fill(AppColors.textSecondary.opacity(0.15))
                                .frame(width: 36, height: 36)
                                .scaleEffect(showSignOutGlow ? 1.3 : 1.0)
                                .opacity(showSignOutGlow ? 0 : 0)

                            Image(systemName: isSigningOut ? "hand.wave.fill" : "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(AppColors.textSecondary)
                                .symbolEffect(.bounce, value: isSigningOut)
                        }

                        if isSigningOut {
                            HStack(spacing: 8) {
                                Text("Signing Out")
                                    .font(AppTypography.bodyMedium)
                                    .foregroundStyle(AppColors.textSecondary)
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(AppColors.textMuted)
                            }
                        } else {
                            Text("Sign Out")
                                .font(AppTypography.bodyMedium)
                                .foregroundStyle(AppColors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, AppSpacing.xs)
                    .contentShape(Rectangle())
                }
                .buttonStyle(SignOutButtonStyle())
                .disabled(isSigningOut)
            }

            // About section with logo and easter egg
            Section {
                VStack(spacing: AppSpacing.md) {
                    // Logo with subtle animation on tap
                    Button {
                        versionTapCount += 1
                        if versionTapCount >= 5 {
                            HapticManager.shared.success()
                            versionTapCount = 0
                        } else if versionTapCount >= 3 {
                            HapticManager.shared.light()
                        }
                    } label: {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                            .opacity(0.8)
                            .scaleEffect(versionTapCount >= 3 ? 1.1 : 1.0)
                            .rotationEffect(.degrees(versionTapCount >= 5 ? 360 : 0))
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: versionTapCount)
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 4) {
                        Text("Styleum")
                            .font(AppTypography.editorialTitle)
                            .foregroundColor(AppColors.textPrimary)

                        Text("Version \(Bundle.main.appVersion)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textMuted)

                        if versionTapCount >= 3 {
                            Text(versionTapCount >= 5 ? "Made with love" : "\(5 - versionTapCount) more...")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.brownLight)
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.lg)
                .listRowBackground(Color.clear)
                .animation(.spring(response: 0.3), value: versionTapCount)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Heading out?", isPresented: $showSignOutConfirmation) {
            Button("Stay", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                performSignOut()
            }
        } message: {
            Text("Your wardrobe will be waiting when you return. See you soon!")
        }
        .alert("Retake Style Quiz?", isPresented: $showRetakeStyleQuizConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Retake") {
                coordinator.presentFullScreen(.styleQuiz)
            }
        } message: {
            Text("This will update your style preferences based on your new choices.")
        }
        .overlay {
            if showRestoreSuccess {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)
                        Text("Purchases restored")
                            .font(AppTypography.labelMedium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(AppSpacing.radiusMd)
                    .padding(.bottom, 32)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showProScreenshot) {
            ProUpgradeScreenshotView()
        }
        .confirmationDialog("Temperature Unit", isPresented: $showTemperatureUnitPicker) {
            Button("°F (Fahrenheit)") { updateTemperatureUnit("fahrenheit") }
            Button("°C (Celsius)") { updateTemperatureUnit("celsius") }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func updateTemperatureUnit(_ unit: String) {
        temperatureUnit = unit  // Save to UserDefaults immediately via @AppStorage
        Task {
            try? await profileService.updateProfile(ProfileUpdate(temperatureUnit: unit))
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    private func openSubscriptionManagement() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }

    private func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }

        // Restore purchases via RevenueCat
        _ = await subscriptionManager.restorePurchases()

        // Refresh tier state from backend
        await tierManager.refresh()

        // Show success feedback
        HapticManager.shared.success()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showRestoreSuccess = true
        }

        // Auto-hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.25)) {
                showRestoreSuccess = false
            }
        }
    }

    private func performSignOut() {
        isSigningOut = true

        Task {
            do {
                try await AuthService.shared.signOut()
                HapticManager.shared.success()
            } catch {
                HapticManager.shared.error()
                // Error handling - user will see they're still signed in
            }
            await MainActor.run {
                isSigningOut = false
            }
        }
    }
}

// MARK: - Sign Out Button Style
private struct SignOutButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.radiusSm)
                    .fill(configuration.isPressed ? AppColors.fill : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
            .environment(AppCoordinator())
    }
}
