import SwiftUI

struct SettingsScreen: View {
    @Environment(AppCoordinator.self) private var coordinator

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
                    action: {}
                ) {
                    Image(symbol: .settings)
                        .foregroundColor(AppColors.textSecondary)
                } trailing: {
                    EmptyView()
                }
            }

            Section("Account") {
                ListRow(
                    title: "Subscription",
                    action: {
                        coordinator.navigate(to: .subscription)
                    }
                ) {
                    Image(symbol: .star)
                        .foregroundColor(AppColors.textSecondary)
                } trailing: {
                    Text("Free")
                        .foregroundColor(AppColors.textSecondary)
                }

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
                    action: {}
                ) {
                    Image(symbol: .info)
                        .foregroundColor(AppColors.textSecondary)
                } trailing: {
                    EmptyView()
                }

                ListRow(
                    title: "Contact Us",
                    action: {}
                ) {
                    Image(symbol: .settings)
                        .foregroundColor(AppColors.textSecondary)
                } trailing: {
                    EmptyView()
                }
            }

            Section {
                ListRow(
                    title: "Sign Out",
                    showChevron: false,
                    destructive: true,
                    action: {
                        // Sign out action
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
}

#Preview {
    NavigationStack {
        SettingsScreen()
            .environment(AppCoordinator())
    }
}
