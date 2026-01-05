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

                ListRow(
                    title: "Privacy",
                    action: {}
                ) {
                    Image(symbol: .info)
                        .foregroundColor(AppColors.textSecondary)
                } trailing: {
                    EmptyView()
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
}

#Preview {
    NavigationStack {
        SettingsScreen()
            .environment(AppCoordinator())
    }
}
