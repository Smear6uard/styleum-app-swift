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

            // Underline-style category tabs (matching Wardrobe)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    // "All" option
                    VStack(spacing: 6) {
                        Text("All")
                            .font(.system(size: 14, weight: selectedCategory == nil ? .semibold : .regular))
                            .foregroundColor(selectedCategory == nil ? AppColors.textPrimary : AppColors.textMuted)

                        Rectangle()
                            .fill(selectedCategory == nil ? AppColors.brownPrimary : Color.clear)
                            .frame(height: 2.5)
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = nil
                        }
                        HapticManager.shared.selection()
                    }

                    ForEach(AchievementCategory.allCases) { category in
                        let isSelected = selectedCategory == category
                        VStack(spacing: 6) {
                            Text(category.displayName)
                                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textMuted)

                            Rectangle()
                                .fill(isSelected ? AppColors.brownPrimary : Color.clear)
                                .frame(height: 2.5)
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = category
                            }
                            HapticManager.shared.selection()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, AppSpacing.md)

            // Content
            if achievementsService.isLoading && achievementsService.achievements.isEmpty {
                // Skeleton loading state
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: AppSpacing.md),
                            GridItem(.flexible(), spacing: AppSpacing.md)
                        ],
                        spacing: AppSpacing.md
                    ) {
                        ForEach(0..<6, id: \.self) { _ in
                            AchievementCardSkeleton()
                        }
                    }
                    .padding(.horizontal, AppSpacing.pageMargin)
                    .padding(.top, AppSpacing.lg)
                }
            } else if filteredAchievements.isEmpty {
                // Empty state for category
                ContentUnavailableView {
                    Label(emptyStateTitle, systemImage: emptyStateIcon)
                } description: {
                    Text(emptyStateDescription)
                } actions: {
                    if selectedCategory == .worn {
                        Button("Style Me") {
                            coordinator.switchTab(to: .styleMe)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.brownPrimary)
                    }
                }
            } else {
                ScrollView {
                    if selectedCategory == nil {
                        // "All" tab: Grouped by category with sticky headers
                        LazyVStack(spacing: AppSpacing.lg, pinnedViews: [.sectionHeaders]) {
                            // Featured next achievement
                            if let nextAchievement = achievementsService.nextAchievement(for: nil) {
                                NextAchievementCard(achievement: nextAchievement)
                                    .padding(.horizontal, AppSpacing.pageMargin)
                            }

                            ForEach(groupedAchievements, id: \.category) { group in
                                Section {
                                    LazyVGrid(
                                        columns: [
                                            GridItem(.flexible(), spacing: AppSpacing.md),
                                            GridItem(.flexible(), spacing: AppSpacing.md)
                                        ],
                                        spacing: AppSpacing.md
                                    ) {
                                        ForEach(group.achievements) { achievement in
                                            achievementCardWithActions(achievement)
                                        }
                                    }
                                    .padding(.horizontal, AppSpacing.pageMargin)
                                } header: {
                                    sectionHeader(for: group.category)
                                }
                            }
                        }
                        .padding(.bottom, AppSpacing.xl)
                    } else {
                        // Single category view
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
                                    achievementCardWithActions(achievement)
                                }
                            }
                            .padding(.horizontal, AppSpacing.pageMargin)
                        }
                        .padding(.bottom, AppSpacing.xl)
                    }
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

    // MARK: - Actions

    private func shareAchievement(_ achievement: Achievement) {
        HapticManager.shared.light()
        let text = "I just unlocked '\(achievement.title)' on Styleum! \(achievement.description)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    // MARK: - Computed Properties

    private var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return achievementsService.achievements(for: category)
        }
        return achievementsService.achievements
    }

    private var groupedAchievements: [(category: AchievementCategory, achievements: [Achievement])] {
        AchievementCategory.allCases.compactMap { category in
            let achievements = achievementsService.achievements(for: category)
            return achievements.isEmpty ? nil : (category, achievements)
        }
    }

    private var emptyStateTitle: String {
        switch selectedCategory {
        case .worn: return "No outfits worn yet"
        case .wardrobe: return "No wardrobe achievements"
        case .outfits: return "No outfit achievements"
        case .streaks: return "No streak achievements"
        case .social: return "No social achievements"
        case .style: return "No style achievements"
        case nil: return "No achievements"
        }
    }

    private var emptyStateIcon: String {
        switch selectedCategory {
        case .worn: return "tshirt"
        case .wardrobe: return "cabinet"
        case .outfits: return "sparkles"
        case .streaks: return "flame"
        case .social: return "person.2"
        case .style: return "wand.and.stars"
        case nil: return "trophy"
        }
    }

    private var emptyStateDescription: String {
        switch selectedCategory {
        case .worn: return "Mark outfits as worn to track your style journey"
        case .wardrobe: return "Add items to your wardrobe to unlock achievements"
        case .outfits: return "Create outfits to unlock achievements"
        case .streaks: return "Build your streak to unlock achievements"
        case .social: return "Share your style to unlock achievements"
        case .style: return "Complete style quizzes to unlock achievements"
        case nil: return "Start your style journey to earn achievements"
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private func sectionHeader(for category: AchievementCategory) -> some View {
        HStack {
            Text(category.displayName.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.brownSecondary)
                .tracking(1)
            Spacer()
            Text("\(achievementsService.achievements(for: category).filter(\.isUnlocked).count)/\(achievementsService.achievements(for: category).count)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(.horizontal, AppSpacing.pageMargin)
        .padding(.vertical, 10)
        .background(AppColors.background)
    }

    @ViewBuilder
    private func achievementCardWithActions(_ achievement: Achievement) -> some View {
        AchievementCard(achievement: achievement)
            .contextMenu {
                if achievement.isUnlocked {
                    Button {
                        shareAchievement(achievement)
                    } label: {
                        Label("Share Achievement", systemImage: "square.and.arrow.up")
                    }
                }

                Button {
                    coordinator.present(.achievementDetail(achievementId: achievement.id))
                } label: {
                    Label("View Details", systemImage: "info.circle")
                }
            }
            .onTapGesture {
                HapticManager.shared.light()
                if achievement.isNew {
                    Task {
                        await achievementsService.markAsSeen(achievementId: achievement.id)
                    }
                }
            }
    }
}


// MARK: - Next Achievement Card

struct NextAchievementCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                Text("NEXT")
                    .font(AppTypography.kicker)
                    .foregroundColor(AppColors.brownLight)
                    .tracking(1)
                Spacer()

                Text("\(achievement.currentProgress)/\(achievement.targetProgress)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.textMuted)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppColors.textPrimary)

                Text(achievement.description)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Progress bar with brown accent
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppColors.brownLight.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)

                    Rectangle()
                        .fill(AppColors.brownPrimary)
                        .frame(width: geo.size.width * achievement.progressPercent, height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
        .padding(AppSpacing.lg)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusLg)
    }
}

// MARK: - Achievement Card (Simplified)

struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Title
            Text(achievement.title)
                .font(AppTypography.titleSmall)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)

            // Description
            Text(achievement.description)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(2)

            Spacer(minLength: 4)

            if achievement.isUnlocked {
                // Subtle unlocked indicator
                Text("Unlocked")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.brownLight)
            } else {
                // Thin progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(AppColors.brownLight.opacity(0.2))
                            .frame(height: 2)

                        Rectangle()
                            .fill(AppColors.brownPrimary)
                            .frame(width: geo.size.width * achievement.progressPercent, height: 2)
                    }
                }
                .frame(height: 2)

                Text("\(achievement.currentProgress)/\(achievement.targetProgress)")
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.textMuted)
            }
        }
        .padding(AppSpacing.md)
        .frame(minHeight: 120, alignment: .topLeading)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusMd)
        .opacity(achievement.isUnlocked ? 1.0 : 0.75)
    }
}

// MARK: - Achievement Card Skeleton

struct AchievementCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SkeletonBox(height: 16, width: 100)
            SkeletonBox(height: 12, width: 140)
            Spacer(minLength: 4)
            SkeletonBox(height: 2)
            SkeletonBox(height: 10, width: 40)
        }
        .padding(AppSpacing.md)
        .frame(minHeight: 120, alignment: .topLeading)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusMd)
    }
}

#Preview {
    AchievementsScreen()
        .environment(AppCoordinator())
}
