import SwiftUI

struct AchievementsScreen: View {
    @Environment(AppCoordinator.self) var coordinator
    @State private var achievementsService = AchievementsService.shared
    @State private var streakService = StreakService.shared
    @State private var selectedCategory: AchievementCategory? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Editorial header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Achievements")
                        .font(AppTypography.headingLarge)

                    Spacer()

                    // Unlocked count badge
                    Text("\(achievementsService.unlockedCount)/\(achievementsService.totalCount)")
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColors.textSecondary)
                }

                Text("Track your style journey")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.pageMargin)

            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    CategoryChip(title: "All", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }

                    ForEach(AchievementCategory.allCases) { category in
                        CategoryChip(
                            title: category.displayName,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.pageMargin)
            }
            .padding(.bottom, AppSpacing.md)

            // Content
            if achievementsService.isLoading && achievementsService.achievements.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Featured next achievement
                        if let nextAchievement = achievementsService.nextAchievement(for: selectedCategory) {
                            NextAchievementCard(achievement: nextAchievement)
                                .padding(.horizontal, AppSpacing.pageMargin)
                        }

                        // Achievements grid
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: AppSpacing.md),
                                GridItem(.flexible(), spacing: AppSpacing.md)
                            ],
                            spacing: AppSpacing.md
                        ) {
                            ForEach(filteredAchievements) { achievement in
                                AchievementCard(achievement: achievement)
                                    .onTapGesture {
                                        HapticManager.shared.light()
                                        // Mark as seen if it's new
                                        if achievement.isNew {
                                            Task {
                                                await achievementsService.markAsSeen(achievementId: achievement.id)
                                            }
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, AppSpacing.pageMargin)
                    }
                    .padding(.bottom, AppSpacing.xl)
                }
                .refreshable {
                    await achievementsService.fetchAchievements()
                }
            }
        }
        .background(AppColors.background)
        .navigationBarHidden(true)
        .task {
            await achievementsService.fetchAchievements()
        }
    }

    // MARK: - Computed Properties

    private var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return achievementsService.achievements(for: category)
        }
        return achievementsService.achievements
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            action()
        }) {
            Text(title)
                .font(AppTypography.labelMedium)
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(isSelected ? AppColors.black : AppColors.filterTagBg)
                .cornerRadius(AppSpacing.radiusSm)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Next Achievement Card

struct NextAchievementCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Text("NEXT MILESTONE")
                    .font(AppTypography.kicker)
                    .foregroundColor(AppColors.textMuted)
                Spacer()

                // Rarity badge
                Text(achievement.rarity.displayName.uppercased())
                    .font(AppTypography.kicker)
                    .foregroundColor(achievement.rarityColor)
            }

            HStack(spacing: AppSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppColors.filterTagBg)
                        .frame(width: 56, height: 56)

                    Image(systemName: achievement.iconName)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(achievement.title)
                        .font(AppTypography.titleLarge)
                        .foregroundColor(AppColors.textPrimary)

                    Text(achievement.description)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Text("\(achievement.currentProgress)/\(achievement.targetProgress)")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.textMuted)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppColors.filterTagBg)
                        .frame(height: 6)
                        .cornerRadius(3)

                    Rectangle()
                        .fill(AppColors.black)
                        .frame(width: geo.size.width * achievement.progressPercent, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
        .padding(AppSpacing.lg)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusLg)
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                // Icon background
                ZStack {
                    Circle()
                        .fill(achievement.isUnlocked ? AppColors.black : AppColors.filterTagBg)
                        .frame(width: 48, height: 48)

                    Image(systemName: achievement.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(achievement.isUnlocked ? .white : AppColors.textMuted)
                }

                // New badge
                if achievement.isNew {
                    Circle()
                        .fill(achievement.rarityColor)
                        .frame(width: 12, height: 12)
                        .offset(x: 18, y: -18)
                }
            }

            Text(achievement.title)
                .font(AppTypography.labelMedium)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)

            Text(achievement.description)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if achievement.isUnlocked {
                // Unlocked state
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                    Text("Unlocked")
                        .font(AppTypography.kicker)
                }
                .foregroundColor(achievement.rarityColor)
                .padding(.top, 4)
            } else {
                // Progress bar
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(AppColors.filterTagBg)
                                .frame(height: 3)
                                .cornerRadius(1.5)

                            Rectangle()
                                .fill(AppColors.black)
                                .frame(width: geo.size.width * achievement.progressPercent, height: 3)
                                .cornerRadius(1.5)
                        }
                    }
                    .frame(height: 3)

                    Text("\(achievement.currentProgress)/\(achievement.targetProgress)")
                        .font(AppTypography.kicker)
                        .foregroundColor(AppColors.textMuted)
                }
                .padding(.top, 4)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusMd)
    }
}

#Preview {
    AchievementsScreen()
        .environment(AppCoordinator())
}
