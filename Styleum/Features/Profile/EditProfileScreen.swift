import SwiftUI

struct EditProfileScreen: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var displayName = "Sameer"
    @State private var location = "Chicago, IL"

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Avatar
                VStack(spacing: AppSpacing.sm) {
                    AvatarView(initials: "SA", size: .xlarge)

                    Button("Change Photo") {
                        // Photo picker action
                    }
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.slate)
                }
                .padding(.vertical, AppSpacing.md)

                // Form fields
                VStack(spacing: AppSpacing.md) {
                    AppTextField(
                        placeholder: "Display Name",
                        text: $displayName,
                        icon: .profile
                    )

                    AppTextField(
                        placeholder: "Location",
                        text: $location,
                        icon: .location
                    )
                }

                Spacer(minLength: AppSpacing.xl)

                AppButton(label: "Save Changes") {
                    HapticManager.shared.success()
                    coordinator.pop()
                }
            }
            .padding(AppSpacing.pageMargin)
        }
        .background(AppColors.background)
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EditProfileScreen()
            .environment(AppCoordinator())
    }
}
