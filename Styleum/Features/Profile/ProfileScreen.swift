import SwiftUI
import Auth
import UIKit

struct ProfileScreen: View {
    @Environment(AppCoordinator.self) var coordinator
    private let profileService = ProfileService.shared
    private let wardrobeService = WardrobeService.shared
    private let achievementsService = AchievementsService.shared
    private let gamificationService = GamificationService.shared
    private let authService = AuthService.shared
    private let locationService = LocationService.shared
    @State private var showEditUsername = false
    @State private var editingUsername = ""
    @State private var showSignOutConfirmation = false
    @State private var isSigningOut = false
    @State private var isLoadingShare = false
    @State private var showShareError = false
    @State private var showRetakeStyleQuizConfirmation = false

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
                    HapticManager.shared.light()
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
                        HapticManager.shared.light()
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
                        Text(locationService.locationName.isEmpty ? "Location unavailable" : locationService.locationName)
                            .font(AppTypography.bodyMedium)
                            .lineLimit(1)
                    }
                    .foregroundColor(AppColors.textSecondary)
                }

                // Your Journey Section
                if gamificationService.isLoading && gamificationService.xp == 0 {
                    ProfileStatsSkeleton()
                } else {
                    JourneyStatsSection(
                        gamificationService: gamificationService,
                        achievementsService: achievementsService,
                        wardrobeItemCount: wardrobeService.items.count,
                        onAchievementsTapped: {
                            coordinator.switchTab(to: .achievements)
                        }
                    )
                }

                // Retake Style Quiz Button
                Button {
                    HapticManager.shared.light()
                    showRetakeStyleQuizConfirmation = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Retake Style Quiz")
                                .font(AppTypography.labelLarge)
                                .foregroundColor(AppColors.textPrimary)

                            Text("Update your style preferences")
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColors.textMuted)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textMuted)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(AppSpacing.radiusMd)
                }
                .buttonStyle(ScaleButtonStyle())

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
                        Task {
                            await shareReferralLink()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isLoadingShare {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(AppColors.textPrimary)
                            }
                            Text("Send them Styleum")
                                .font(AppTypography.labelLarge)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.background)
                        .cornerRadius(AppSpacing.radiusMd)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                    }
                    .disabled(isLoadingShare)

                    Text("You'll both get a free month")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textMuted)
                }
                .padding(AppSpacing.lg)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(AppSpacing.radiusLg)

                // Sign out - polished pill button
                Button {
                    HapticManager.shared.light()
                    showSignOutConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isSigningOut ? "hand.wave.fill" : "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14, weight: .medium))
                            .symbolEffect(.bounce, value: isSigningOut)

                        if isSigningOut {
                            HStack(spacing: 6) {
                                Text("Signing Out")
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(AppColors.textSecondary)
                            }
                        } else {
                            Text("Sign Out")
                        }
                    }
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(AppSpacing.radiusFull)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isSigningOut)
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
        .alert("Heading out?", isPresented: $showSignOutConfirmation) {
            Button("Stay", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await performSignOut()
                }
            }
        } message: {
            Text("Your wardrobe will be waiting when you return.")
        }
        .alert("Couldn't Load Referral", isPresented: $showShareError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please try again in a moment.")
        }
        .alert("Retake Style Quiz?", isPresented: $showRetakeStyleQuizConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Retake") {
                coordinator.presentFullScreen(.styleQuiz)
            }
        } message: {
            Text("This will update your style preferences based on your new choices.")
        }
        .task {
            await profileService.fetchProfile()
            await achievementsService.fetchAchievements()
            await gamificationService.loadGamificationData()
            // Ensure location is available for display
            _ = await locationService.getCurrentLocation()
        }
    }

    private func saveUsername() async {
        guard !editingUsername.isEmpty else { return }
        // TODO: Update ProfileUpdate model and API to support firstName update
        // For now, skipping update as API structure has changed
        // User can update name through API when support is added
    }

    private func performSignOut() async {
        isSigningOut = true
        HapticManager.shared.medium()

        do {
            try await authService.signOut()
            HapticManager.shared.success()
        } catch {
            HapticManager.shared.error()
            isSigningOut = false
        }
    }

    private func shareReferralLink() async {
        isLoadingShare = true
        defer { isLoadingShare = false }

        let referralService = ReferralService.shared

        // Fetch referral info if not already loaded
        if referralService.shareUrl == nil {
            do {
                try await referralService.fetchReferralInfo()
            } catch {
                print("❌ [Profile] Failed to fetch referral info: \(error)")
                HapticManager.shared.error()
                showShareError = true
                return
            }
        }

        // Use the same share message as ReferralView for consistency
        let shareMessage = referralService.getShareMessage()

        let shareItems: [Any] = [shareMessage]

        await MainActor.run {
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
                let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
                let rootVC = keyWindow.rootViewController else {
                return
            }

            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }

            let activityVC = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)

            // iPad support
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topVC.view
                popover.sourceRect = CGRect(
                    x: topVC.view.bounds.midX,
                    y: topVC.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }

            topVC.present(activityVC, animated: true)
        }
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

// MARK: - Journey Stats Section

struct JourneyStatsSection: View {
    let gamificationService: GamificationService
    let achievementsService: AchievementsService
    let wardrobeItemCount: Int
    let onAchievementsTapped: () -> Void

    @State private var progressAnimated = false

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Section Header
            HStack {
                Text("PROGRESS")
                    .font(AppTypography.kicker)
                    .foregroundColor(AppColors.brownLight)
                    .tracking(1)

                Spacer()
            }

            // Stats Row - Clean typography, no icons
            HStack(spacing: 0) {
                CleanStatItem(
                    value: "\(gamificationService.longestStreak)",
                    label: "Best Streak"
                )

                Divider()
                    .frame(height: 44)

                CleanStatItem(
                    value: formattedXP,
                    label: "Total XP"
                )

                Divider()
                    .frame(height: 44)

                Button(action: onAchievementsTapped) {
                    CleanStatItem(
                        value: "\(achievementsService.unlockedCount)",
                        label: "Achievements"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.radiusMd)

            // Level Progress Card
            VStack(spacing: AppSpacing.sm) {
                HStack {
                    // Level badge - minimal
                    HStack(spacing: 4) {
                        Text("L")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.brownLight)

                        Text("\(gamificationService.level)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                            .contentTransition(.numericText())
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(gamificationService.levelTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)

                        Text("\(gamificationService.xpInCurrentLevel)/\(gamificationService.xpForNextLevel - gamificationService.xpForCurrentLevel) XP to next")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textMuted)
                    }

                    Spacer()
                }

                // XP Progress Bar - warm brown accent
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.brownLight.opacity(0.2))
                            .frame(height: 6)

                        // Filled progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.brownPrimary)
                            .frame(width: progressAnimated ? geo.size.width * gamificationService.levelProgress : 0, height: 6)
                    }
                }
                .frame(height: 6)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                        progressAnimated = true
                    }
                }

                // Next level preview
                if let nextTitle = nextLevelTitle {
                    HStack {
                        Spacer()
                        Text("Next: \(nextTitle) at Level \(gamificationService.level + 1)")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.textMuted)
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.radiusMd)

            // Quick Stats Row
            HStack(spacing: AppSpacing.sm) {
                QuickStatPill(
                    icon: "tshirt.fill",
                    value: "\(wardrobeItemCount)",
                    label: "Items"
                )

                QuickStatPill(
                    icon: "calendar",
                    value: "\(gamificationService.totalDaysActive)",
                    label: "Days Active"
                )

                QuickStatPill(
                    icon: "snowflake",
                    value: "\(gamificationService.streakFreezes)",
                    label: "Freezes"
                )
            }
        }
    }

    private var formattedXP: String {
        let xp = gamificationService.xp
        if xp >= 1000 {
            return String(format: "%.1fk", Double(xp) / 1000)
        }
        return "\(xp)"
    }

    private var nextLevelTitle: String? {
        let nextLevel = gamificationService.level + 1
        switch nextLevel {
        case 2: return "Fashion Curious"
        case 3: return "Wardrobe Builder"
        case 4: return "Style Explorer"
        case 5: return "Outfit Crafter"
        case 6: return "Trend Spotter"
        case 7: return "Look Curator"
        case 8: return "Style Confident"
        case 9: return "Fashion Forward"
        case 10: return "Wardrobe Master"
        case 11...15: return "Style Expert"
        case 16...20: return "Fashion Authority"
        case 21...30: return "Style Icon"
        case 31...50: return "Fashion Legend"
        default: return "Style Deity"
        }
    }
}

// MARK: - Clean Stat Item (Typography Only)

private struct CleanStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Stat Pill

private struct QuickStatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textMuted)

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusSm)
    }
}


#Preview {
    ProfileScreen()
        .environment(AppCoordinator())
}
