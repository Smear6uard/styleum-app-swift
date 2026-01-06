import SwiftUI
import Auth

struct ProfileScreen: View {
    @Environment(AppCoordinator.self) var coordinator
    @State private var profileService = ProfileService.shared
    @State private var wardrobeService = WardrobeService.shared
    @State private var achievementsService = AchievementsService.shared
    @State private var streakService = StreakService.shared
    @State private var authService = AuthService.shared
    @State private var showEditUsername = false
    @State private var editingUsername = ""

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Settings button
                HStack {
                    Spacer()
                    Button {
                        coordinator.navigate(to: .settings)
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }

                // Avatar - tappable to edit
                Button {
                    editingUsername = profileService.currentProfile?.firstName ?? ""
                    showEditUsername = true
                } label: {
                    AvatarView(
                        imageURL: nil,
                        initials: initials,
                        size: .xlarge
                    )
                }
                .buttonStyle(.plain)

                // Name and location - with edit capability
                VStack(spacing: 4) {
                    Button {
                        editingUsername = profileService.currentProfile?.firstName ?? ""
                        showEditUsername = true
                    } label: {
                        HStack(spacing: 6) {
                            Text(displayName)
                                .font(AppTypography.headingLarge)
                                .foregroundColor(AppColors.textPrimary)

                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textMuted)
                        }
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.system(size: 12, weight: .medium))
                        Text("Chicago, IL")
                            .font(AppTypography.bodyMedium)
                    }
                    .foregroundColor(AppColors.textSecondary)
                }

                // Stats row
                HStack(spacing: 0) {
                    ProfileStatItem(value: "\(wardrobeService.items.count)", label: "Items")

                    Divider()
                        .frame(height: 40)

                    ProfileStatItem(value: "\(streakService.currentStreak)", label: "Day Streak")

                    Divider()
                        .frame(height: 40)

                    ProfileStatItem(value: "\(streakService.totalDaysActive)", label: "Days Active")
                }
                .padding(.vertical, AppSpacing.md)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(AppSpacing.radiusMd)

                // Style Journey card
                Button {
                    coordinator.switchTab(to: .achievements)
                } label: {
                    HStack {
                        Image(systemName: "trophy")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.textMuted)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Style Journey")
                                .font(AppTypography.labelLarge)
                                .foregroundColor(AppColors.textPrimary)

                            Text("\(achievementsService.unlockedCount) of \(achievementsService.totalCount) achievements")
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textMuted)
                    }
                    .padding()
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(AppSpacing.radiusMd)
                }
                .buttonStyle(.plain)

                // Referral card - only orbs here have subtle gradient
                VStack(spacing: AppSpacing.md) {
                    // Subtle gradient orbs - muted colors
                    HStack(spacing: -8) {
                        Circle()
                            .fill(Color(hex: "C9B8A8")) // Warm taupe
                            .frame(width: 28, height: 28)

                        Circle()
                            .fill(Color(hex: "A8B8A8")) // Sage gray
                            .frame(width: 28, height: 28)

                        Circle()
                            .fill(Color(hex: "B8A8A8")) // Dusty mauve
                            .frame(width: 28, height: 28)
                    }

                    Text("Know someone who stares at\ntheir closet too long?")
                        .font(AppTypography.bodyMedium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppColors.textPrimary)

                    Button {
                        HapticManager.shared.medium()
                        // Share
                    } label: {
                        Text("Send them Styleum")
                            .font(AppTypography.labelLarge)
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.background)
                            .cornerRadius(AppSpacing.radiusMd)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    }

                    Text("You'll both get a free month")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textMuted)
                }
                .padding(AppSpacing.lg)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(AppSpacing.radiusLg)

                // Sign out
                Button {
                    Task {
                        try? await authService.signOut()
                    }
                } label: {
                    Text("Sign Out")
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.top, AppSpacing.md)
            }
            .padding(AppSpacing.pageMargin)
        }
        .background(AppColors.background)
        .navigationBarHidden(true)
        .alert("Edit Username", isPresented: $showEditUsername) {
            TextField("Username", text: $editingUsername)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                Task {
                    await saveUsername()
                }
            }
        } message: {
            Text("Enter your display name")
        }
        .task {
            await profileService.fetchProfile()
            await achievementsService.fetchAchievements()
        }
    }

    private func saveUsername() async {
        guard !editingUsername.isEmpty else { return }
        // TODO: Update ProfileUpdate model and API to support firstName update
        // For now, skipping update as API structure has changed
        // User can update name through API when support is added
    }

    private var initials: String {
        let name = displayName
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var displayName: String {
        if let firstName = profileService.currentProfile?.firstName, !firstName.isEmpty {
            return firstName
        }
        return "Set Name"
    }
}

struct ProfileStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppTypography.titleLarge)
            Text(label)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProfileScreen()
        .environment(AppCoordinator())
}
