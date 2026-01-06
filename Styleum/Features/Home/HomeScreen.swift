import SwiftUI

struct HomeScreen: View {
    @Environment(AppCoordinator.self) var coordinator
    @State private var wardrobeService = WardrobeService.shared
    @State private var profileService = ProfileService.shared
    @State private var streakService = StreakService.shared
    @State private var outfitRepo = OutfitRepository.shared
    @State private var insights: WardrobeInsights?
    @State private var isLoadingInsights = true

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

                        Text("\(streakService.currentStreak) days")
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

                // Wardrobe Insights
                WardrobeInsightsSection(
                    insights: insights,
                    isLoading: isLoadingInsights,
                    hasItems: !wardrobeService.items.isEmpty,
                    onAddItems: { coordinator.present(.addItem) },
                    onItemTapped: { _ in coordinator.switchTab(to: .wardrobe) }
                )
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
            isLoadingInsights = true
            insights = try? await StyleumAPI.shared.fetchWardrobeInsights()
            isLoadingInsights = false
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
        let streak = streakService.currentStreak
        return min(CGFloat(streak) / 7.0, 1.0)
    }

}

// MARK: - Wardrobe Insights Section
struct WardrobeInsightsSection: View {
    let insights: WardrobeInsights?
    let isLoading: Bool
    let hasItems: Bool
    let onAddItems: () -> Void
    let onItemTapped: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("WARDROBE INSIGHTS")
                .font(AppTypography.kicker)
                .foregroundColor(AppColors.textMuted)
                .tracking(1)

            if isLoading {
                if hasItems {
                    HStack(spacing: AppSpacing.md) {
                        InsightCardSkeleton()
                        InsightCardSkeleton()
                    }
                } else {
                    EmptyWardrobeSkeleton()
                }
            } else if let insights = insights {
                if insights.itemCount == 0 {
                    EmptyWardrobeCard(onAddItems: onAddItems)
                } else {
                    HStack(spacing: AppSpacing.md) {
                        ItemCountCard(count: insights.itemCount, categoryCount: insights.categoryCount)
                        MostWornCard(item: insights.mostWornItem, onTap: {
                            if let item = insights.mostWornItem {
                                onItemTapped(item.id)
                            }
                        })
                    }
                }
            } else {
                EmptyWardrobeCard(onAddItems: onAddItems)
            }
        }
    }
}

struct EmptyWardrobeCard: View {
    let onAddItems: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "tshirt")
                .font(.system(size: 32))
                .foregroundColor(AppColors.textMuted)
            Text("Add your first items")
                .font(AppTypography.titleSmall)
            Text("to get started")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
            Button(action: onAddItems) {
                Text("Add Items")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(AppColors.black)
                    .cornerRadius(AppSpacing.radiusSm)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusMd)
    }
}

struct ItemCountCard: View {
    let count: Int
    let categoryCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(count)")
                .font(AppTypography.displaySmall)
            Text("Items")
                .font(AppTypography.labelMedium)
            Text("\(categoryCount) categories")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusMd)
    }
}

struct MostWornCard: View {
    let item: MostWornItem?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                if let item = item {
                    HStack(spacing: AppSpacing.sm) {
                        AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(AppColors.filterTagBg)
                        }
                        .frame(width: 40, height: 40)
                        .cornerRadius(AppSpacing.radiusSm)

                        Text(item.name)
                            .font(AppTypography.bodySmall)
                            .lineLimit(1)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    Spacer()
                    Text("Most Worn")
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColors.textPrimary)
                    Text("Worn \(item.wearCount)x")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textMuted)
                } else {
                    Text("—")
                        .font(AppTypography.displaySmall)
                        .foregroundColor(AppColors.textMuted)
                    Text("Most Worn")
                        .font(AppTypography.labelMedium)
                    Text("Wear an outfit to track")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.md)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.radiusMd)
        }
        .buttonStyle(.plain)
        .disabled(item == nil)
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
                        AsyncImage(url: URL(string: item.displayPhotoUrl ?? "")) { image in
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
