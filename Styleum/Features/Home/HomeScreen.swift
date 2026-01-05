import SwiftUI

struct HomeScreen: View {
    @Environment(AppCoordinator.self) var coordinator
    @State private var wardrobeService = WardrobeService.shared
    @State private var profileService = ProfileService.shared
    @State private var outfitRepo = OutfitRepository.shared

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(timeOfDayGreeting)
                            .font(AppTypography.displayMedium)

                        HStack(spacing: 6) {
                            Image(systemName: "sun.max")
                                .font(.system(size: 14, weight: .medium))
                            Text("72° Sunny")
                            Text("·")
                            Text("Chicago, IL")
                        }
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    Button {
                        // Notifications
                    } label: {
                        Image(systemName: "bell")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }

                // Streak progress bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("STYLE STREAK")
                            .font(AppTypography.kicker)
                            .foregroundColor(AppColors.textMuted)
                            .tracking(1)

                        Spacer()

                        Text("\(profileService.currentProfile?.currentStreak ?? 0) days")
                            .font(AppTypography.labelMedium)
                            .foregroundColor(AppColors.textPrimary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(AppColors.filterTagBg)
                                .frame(height: 4)
                                .cornerRadius(2)

                            Rectangle()
                                .fill(AppColors.black)
                                .frame(width: geo.size.width * streakProgress, height: 4)
                                .cornerRadius(2)
                        }
                    }
                    .frame(height: 4)

                    Text("Keep it going! Style an outfit today.")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textMuted)
                }
                .padding(AppSpacing.md)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(AppSpacing.radiusMd)

                // Today's outfit
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("TODAY'S OUTFIT")
                        .font(AppTypography.kicker)
                        .foregroundColor(AppColors.textMuted)
                        .tracking(1)

                    if let outfit = outfitRepo.todaysOutfits.first {
                        TodaysOutfitCard(outfit: outfit)
                    } else if outfitRepo.isLoading {
                        SkeletonCard()
                            .frame(height: 200)
                    } else {
                        VStack(spacing: AppSpacing.md) {
                            Image(systemName: "square.stack")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(AppColors.textMuted)

                            Text("Ready to style")
                                .font(AppTypography.titleMedium)

                            Text("Tap Style Me to get your outfit for today")
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)

                            Button {
                                coordinator.switchTab(to: .styleMe)
                            } label: {
                                Text("Style Me")
                                    .font(AppTypography.labelLarge)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(AppColors.black)
                                    .cornerRadius(AppSpacing.radiusMd)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(AppSpacing.xl)
                        .frame(maxWidth: .infinity)
                        .background(AppColors.backgroundSecondary)
                        .cornerRadius(AppSpacing.radiusLg)
                    }
                }

                // Quick actions
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("QUICK ACTIONS")
                        .font(AppTypography.kicker)
                        .foregroundColor(AppColors.textMuted)
                        .tracking(1)

                    HStack(spacing: AppSpacing.md) {
                        QuickActionButton(icon: "plus", label: "Add Item") {
                            coordinator.present(.addItem)
                        }

                        QuickActionButton(icon: "square.stack", label: "Style Me") {
                            coordinator.switchTab(to: .styleMe)
                        }
                    }
                }

                // Wardrobe Insights (replaces redundant streak stats)
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("WARDROBE INSIGHTS")
                        .font(AppTypography.kicker)
                        .foregroundColor(AppColors.textMuted)
                        .tracking(1)

                    HStack(spacing: AppSpacing.md) {
                        InsightCard(
                            value: "\(wardrobeService.items.count)",
                            label: "Items",
                            detail: categoryBreakdown
                        )

                        InsightCard(
                            value: mostWornCount,
                            label: "Most Worn",
                            detail: mostWornItem
                        )
                    }
                }
            }
            .padding(AppSpacing.pageMargin)
        }
        .background(AppColors.background)
        .navigationBarHidden(true)
        .refreshable {
            HapticManager.shared.light()
            await outfitRepo.getTodaysOutfits(forceRefresh: true)
        }
        .task {
            await wardrobeService.fetchItems()
            await profileService.fetchProfile()
            await outfitRepo.getTodaysOutfits()
        }
    }

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Morning."
        case 12..<17: return "Afternoon."
        default: return "Evening."
        }
    }

    private var streakProgress: CGFloat {
        let streak = profileService.currentProfile?.currentStreak ?? 0
        return min(CGFloat(streak) / 7.0, 1.0)
    }

    private var categoryBreakdown: String {
        let categories = Set(wardrobeService.items.compactMap { $0.category?.displayName })
        return "\(categories.count) categories"
    }

    private var mostWornItem: String {
        guard let item = wardrobeService.items.max(by: { $0.timesWorn < $1.timesWorn }),
              item.timesWorn > 0 else {
            return "No data yet"
        }
        return item.itemName ?? item.category?.displayName ?? "Item"
    }

    private var mostWornCount: String {
        guard let item = wardrobeService.items.max(by: { $0.timesWorn < $1.timesWorn }),
              item.timesWorn > 0 else {
            return "—"
        }
        return "\(item.timesWorn)x"
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let value: String
    let label: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(AppTypography.displaySmall)

            Text(label)
                .font(AppTypography.labelMedium)
                .foregroundColor(AppColors.textPrimary)

            Text(detail)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusMd)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(label)
                    .font(AppTypography.labelMedium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(AppColors.black)
            .cornerRadius(AppSpacing.radiusMd)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Today's Outfit Card
struct TodaysOutfitCard: View {
    let outfit: ScoredOutfit
    @State private var wardrobeService = WardrobeService.shared

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(outfit.wardrobeItemIds.prefix(3), id: \.self) { itemId in
                    if let item = wardrobeService.items.first(where: { $0.id == itemId }) {
                        AsyncImage(url: URL(string: item.photoUrl ?? "")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Rectangle().fill(AppColors.filterTagBg)
                        }
                        .frame(width: 80, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSm))
                    }
                }
            }

            Text(outfit.whyItWorks)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    try? await OutfitRepository.shared.markAsWorn(outfit)
                }
            } label: {
                Text("Wear This Today")
                    .font(AppTypography.labelLarge)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColors.black)
                    .cornerRadius(AppSpacing.radiusMd)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(AppSpacing.lg)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusLg)
    }
}

#Preview {
    HomeScreen()
        .environment(AppCoordinator())
}
