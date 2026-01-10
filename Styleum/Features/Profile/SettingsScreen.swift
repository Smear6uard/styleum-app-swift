import SwiftUI

struct SettingsScreen: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var tierManager = TierManager.shared
    @State private var isRestoring = false

    var body: some View {
        List {
            Section("Preferences") {
                ListRow(
                    title: "Temperature Unit",
                    action: {}
                ) {
                    Image(symbol: .sunMax)
                        .foregroundColor(AppColors.textSecondary)
                } trailing: {
                    Text("°F")
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
            }

            Section("Subscription") {
                // Pro Status Row
                HStack {
                    Image(systemName: tierManager.isPro ? "checkmark.seal.fill" : "seal")
                        .foregroundStyle(tierManager.isPro ? .green : AppColors.textMuted)

                    Text(tierManager.isPro ? "Styleum Pro" : "Free Plan")
                        .font(.system(size: 15))

                    Spacer()

                    if !tierManager.isPro {
                        Button("Upgrade") {
                            coordinator.navigate(to: .subscription)
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.brownPrimary)
                    }
                }
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
                            .font(.system(size: 12))
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

            Section("Account") {
                ListRow(
                    title: "Edit Profile",
                    action: {
                        coordinator.navigate(to: .editProfile)
                    }
                ) {
                    Image(symbol: .profile)
                        .foregroundColor(AppColors.textSecondary)
                } trailing: {
                    EmptyView()
                }

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

            Section {
                ListRow(
                    title: "Sign Out",
                    showChevron: false,
                    destructive: true,
                    action: {
                        Task {
                            try? await AuthService.shared.signOut()
                        }
                    }
                ) {
                    EmptyView()
                } trailing: {
                    EmptyView()
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
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

        // TODO: Implement RevenueCat restore
        // try await Purchases.shared.restorePurchases()
        await tierManager.refresh()
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
            .environment(AppCoordinator())
    }
}
