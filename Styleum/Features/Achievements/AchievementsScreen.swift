import SwiftUI

struct AchievementsScreen: View {
    @Environment(AppCoordinator.self) var coordinator
    @State private var achievementsService = AchievementsService.shared
    @State private var selectedCategory: String = "All"

    let categories = ["All", "Wardrobe", "Outfits", "Streaks", "Social"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Achievements")
                    .font(AppTypography.headingLarge)

                HStack(spacing: 4) {
                    Text("\(achievementsService.unlockedCount) of \(achievementsService.totalCount)")
                        .font(AppTypography.titleMedium)
                    Text("Achievements Unlocked")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(AppColors.filterTagBg)
                            .frame(height: 4)
                            .cornerRadius(2)

                        Rectangle()
                            .fill(AppColors.black)
                            .frame(width: geo.size.width * progress, height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
                .padding(.top, 4)
            }
            .padding(AppSpacing.pageMargin)

            // Underline tabs (single select)
            UnderlineTabsSingle(
                tabs: categories,
                selectedTab: $selectedCategory
            )
            .padding(.bottom, AppSpacing.md)

            // Content
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: AppSpacing.md),
                        GridItem(.flexible(), spacing: AppSpacing.md)
                    ],
                    spacing: AppSpacing.md
                ) {
                    ForEach(0..<6) { index in
                        AchievementCard(
                            title: "Achievement \(index + 1)",
                            description: "Complete this task",
                            isUnlocked: index < 2,
                            progress: index < 2 ? 1.0 : Double(index) / 10.0
                        )
                    }
                }
                .padding(AppSpacing.pageMargin)
            }
        }
        .background(AppColors.background)
        .navigationBarHidden(true)
        .task {
            await achievementsService.fetchAchievements()
        }
    }

    private var progress: CGFloat {
        guard achievementsService.totalCount > 0 else { return 0 }
        return CGFloat(achievementsService.unlockedCount) / CGFloat(achievementsService.totalCount)
    }
}

struct AchievementCard: View {
    let title: String
    let description: String
    let isUnlocked: Bool
    let progress: Double

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? AppColors.black : AppColors.filterTagBg)
                    .frame(width: 48, height: 48)

                Image(systemName: isUnlocked ? "checkmark" : "star")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isUnlocked ? .white : AppColors.textMuted)
            }

            Text(title)
                .font(AppTypography.labelMedium)
                .foregroundColor(AppColors.textPrimary)

            Text(description)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppColors.filterTagBg)
                        .frame(height: 3)
                        .cornerRadius(1.5)

                    Rectangle()
                        .fill(AppColors.black)
                        .frame(width: geo.size.width * progress, height: 3)
                        .cornerRadius(1.5)
                }
            }
            .frame(height: 3)
            .padding(.top, 4)
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
