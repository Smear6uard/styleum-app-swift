import SwiftUI

struct HomeScreen: View {
    @Environment(AppCoordinator.self) var coordinator
    @State private var wardrobeService = WardrobeService.shared
    @State private var profileService = ProfileService.shared
    @State private var gamificationService = GamificationService.shared
    @State private var outfitRepo = OutfitRepository.shared
    @State private var locationService = LocationService.shared
    @State private var tierManager = TierManager.shared
    @State private var insights: WardrobeInsights?
    @State private var isLoadingInsights = true
    @State private var headerAppeared = false
    @State private var showChallengesExpanded = false
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        TrackableScrollView(scrollOffset: $scrollOffset) {
            VStack(spacing: AppSpacing.lg) {
                // Editorial Header with scroll-linked effects
                headerSection
                    .scrollLinkedHeader(scrollOffset: scrollOffset)

                // HERO: Daily Outfit - THE MAIN EVENT (above the fold)
                dailyOutfitHero
                    .progressiveReveal(delay: 0.05)

                // Secondary action when pre-generated is ready
                if outfitRepo.hasPreGeneratedReady {
                    VStack(spacing: AppSpacing.sm) {
                        Text("Want something different?")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textSecondary)

                        Button {
                            coordinator.switchTab(to: .styleMe)
                        } label: {
                            Text("Generate New Looks")
                                .font(AppTypography.labelMedium)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppColors.textMuted.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, AppSpacing.pageMargin)
                }

                // Streak Calendar (7-day week view) - compact inline
                if gamificationService.isLoading && gamificationService.activityHistory.isEmpty {
                    StreakCalendarSkeleton()
                        .padding(.horizontal, AppSpacing.pageMargin)
                } else {
                    StreakCalendar()
                        .padding(.horizontal, AppSpacing.pageMargin)
                        .progressiveReveal(delay: 0.1)
                }

                // Quick Actions - Editorial Style
                VStack(spacing: AppSpacing.sm) {
                    HStack(spacing: AppSpacing.sm) {
                        QuickActionCard(
                            icon: "plus",
                            title: "Add",
                            subtitle: "New piece"
                        ) {
                            coordinator.present(.addItem)
                        }

                        QuickActionCard(
                            icon: "rectangle.stack",
                            title: "Style",
                            subtitle: "Get looks"
                        ) {
                            coordinator.switchTab(to: .styleMe)
                        }

                        QuickActionCard(
                            icon: "square.grid.2x2",
                            title: "Browse",
                            subtitle: "Wardrobe"
                        ) {
                            coordinator.switchTab(to: .wardrobe)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.pageMargin)

                // Daily Challenges Card (collapsible, secondary)
                if gamificationService.isLoading && gamificationService.dailyChallenges.isEmpty {
                    DailyChallengesCardSkeleton()
                        .padding(.horizontal, AppSpacing.pageMargin)
                } else {
                    DailyChallengesCard(
                        onChallengeTapped: { challenge in
                            handleChallengeTap(challenge)
                        }
                    )
                    .padding(.horizontal, AppSpacing.pageMargin)
                    .progressiveReveal(delay: 0.15)
                }

                // Wardrobe Insights
                WardrobeInsightsSection(
                    insights: insights,
                    isLoading: isLoadingInsights,
                    hasItems: !wardrobeService.items.isEmpty,
                    onAddItems: { coordinator.present(.addItem) },
                    onItemTapped: { _ in coordinator.switchTab(to: .wardrobe) }
                )
                .padding(.horizontal, AppSpacing.pageMargin)

                // Contextual banners (bottom of scroll)
                subscriptionBanners

                // Streak At Risk Warning (when applicable)
                if gamificationService.streakAtRisk && gamificationService.currentStreak > 0 {
                    StreakAtRiskBanner(
                        onGenerateOutfit: {
                            coordinator.switchTab(to: .styleMe)
                        },
                        onAddItem: {
                            coordinator.present(.addItem)
                        }
                    )
                    .padding(.horizontal, AppSpacing.pageMargin)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            .padding(.vertical, AppSpacing.pageMargin)
        }
        .background(AppColors.background)
        .navigationBarHidden(true)
        .refreshable {
            HapticManager.shared.light()
            await refreshAll()
        }
        .task {
            await tierManager.refresh()
            await loadInitialData()
        }
        .animation(.easeInOut(duration: 0.3), value: gamificationService.streakAtRisk)
    }

    // MARK: - Header Section (Compact)

    @ViewBuilder
    private var headerSection: some View {
        HStack(alignment: .firstTextBaseline) {
            // Greeting - tighter editorial
            Text(personalizedGreeting)
                .font(AppTypography.editorial(28, weight: .light))
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            // Weather pill - inline with greeting
            if outfitRepo.preGeneratedWeather != nil || outfitRepo.currentWeather != nil {
                HStack(spacing: 4) {
                    Image(systemName: weatherIconName)
                        .font(.system(size: 12, weight: .medium))
                    Text(weatherText)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppColors.backgroundSecondary)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.pageMargin)
        .opacity(headerAppeared ? 1 : 0)
        .offset(y: headerAppeared ? 0 : 8)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                headerAppeared = true
            }
        }
    }

    // MARK: - Subscription Status Banners

    @ViewBuilder
    private var subscriptionBanners: some View {
        VStack(spacing: 8) {
            // Priority order: Billing > Grace Period > Cancellation > Over Limit
            if tierManager.hasBillingIssue {
                BillingIssueBanner {
                    openSubscriptionManagement()
                }
            } else if tierManager.inGracePeriod {
                GracePeriodBanner(daysRemaining: tierManager.gracePeriodDaysRemaining) {
                    openSubscriptionManagement()
                }
            } else if tierManager.isCancelled, let expiry = tierManager.subscriptionExpiryDate {
                CancellationBanner(expiryDate: expiry) {
                    coordinator.navigate(to: .subscription)
                }
            } else if tierManager.isOverLimit, let info = tierManager.tierInfo {
                OverLimitBanner(
                    itemCount: info.usage.wardrobeItems,
                    limit: info.limits.maxWardrobeItems
                ) {
                    coordinator.navigate(to: .subscription)
                }
            }
        }
        .padding(.horizontal, AppSpacing.pageMargin)
    }

    private func openSubscriptionManagement() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Daily Outfit Hero (THE MAIN EVENT)

    @ViewBuilder
    private var dailyOutfitHero: some View {
        if outfitRepo.hasPreGeneratedReady {
            DailyOutfitHeroCard(
                outfits: outfitRepo.preGeneratedOutfits,
                wardrobeItems: wardrobeService.items,
                onViewTapped: {
                    HapticManager.shared.medium()
                    outfitRepo.viewPreGeneratedOutfits()
                    coordinator.presentFullScreen(.outfitResults)
                }
            )
        } else if outfitRepo.isLoading {
            SkeletonCard()
                .frame(height: 280)
                .padding(.horizontal, AppSpacing.pageMargin)
        } else {
            // Empty state - editorial with subtle animation
            EmptyOutfitHero(
                weatherCopy: emptyStateWeatherCopy,
                onStyleMe: {
                    coordinator.switchTab(to: .styleMe)
                }
            )
            .padding(.horizontal, AppSpacing.pageMargin)
        }
    }

    // MARK: - Data Loading

    private func loadInitialData() async {
        isLoadingInsights = true

        // Load all data in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                insights = try? await StyleumAPI.shared.fetchWardrobeInsights()
            }
            group.addTask {
                await wardrobeService.fetchItems()
            }
            group.addTask {
                await profileService.fetchProfile()
            }
            group.addTask {
                await outfitRepo.getTodaysOutfits()
            }
            group.addTask {
                await gamificationService.loadGamificationData()
            }
        }

        isLoadingInsights = false
    }

    private func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await outfitRepo.getTodaysOutfits(forceRefresh: true)
            }
            group.addTask {
                await gamificationService.loadGamificationData()
            }
        }
    }

    // MARK: - Challenge Handling

    private func handleChallengeTap(_ challenge: DailyChallenge) {
        // Navigate based on challenge type
        guard let type = challenge.type else {
            // Default to StyleMe for unknown challenge types
            coordinator.switchTab(to: .styleMe)
            return
        }

        switch type {
        case .wearOutfit:
            if outfitRepo.hasPreGeneratedReady {
                coordinator.presentFullScreen(.outfitResults)
            } else {
                coordinator.switchTab(to: .styleMe)
            }
        case .addItem:
            coordinator.present(.addItem)
        case .generateOutfit:
            coordinator.switchTab(to: .styleMe)
        case .saveOutfit:
            coordinator.switchTab(to: .styleMe)
        case .viewWardrobe:
            coordinator.switchTab(to: .wardrobe)
        }
    }

    // MARK: - Personalized Greeting

    private var personalizedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        switch hour {
        case 0..<12: timeGreeting = "Morning"
        case 12..<17: timeGreeting = "Afternoon"
        default: timeGreeting = "Evening"
        }

        if let firstName = profileService.currentProfile?.firstName, !firstName.isEmpty {
            return "\(timeGreeting), \(firstName)."
        }
        return "\(timeGreeting)."
    }

    // MARK: - Weather-Aware Empty State

    private var emptyStateWeatherCopy: String {
        guard let weather = outfitRepo.preGeneratedWeather ?? outfitRepo.currentWeather else {
            return "Let's find your look for today."
        }

        let temp = weather.tempFahrenheit
        let condition = weather.condition.lowercased()

        if condition.contains("rain") {
            return "Rainy day calls for a cozy look."
        } else if condition.contains("snow") {
            return "Time to bundle up in style."
        } else if condition.contains("clear") || condition.contains("sunny") {
            if temp > 80 {
                return "Hot and sunny—dress light, look sharp."
            } else if temp > 60 {
                return "Perfect weather for a fresh outfit."
            } else {
                return "Clear skies, cool air—layer up."
            }
        } else if condition.contains("cloud") {
            return "Cloudy vibes. Perfect for layering."
        } else if temp > 85 {
            return "It's warm out. Keep it breezy."
        } else if temp < 40 {
            return "Bundle up—it's chilly out there."
        }

        return "Let's find your perfect look."
    }

    /// Weather text - tries preGeneratedWeather first, then currentWeather
    private var weatherText: String {
        if let weather = outfitRepo.preGeneratedWeather ?? outfitRepo.currentWeather {
            return "\(Int(weather.tempFahrenheit))° \(weather.condition.lowercased())"
        }
        return "--°"
    }

    /// Weather icon - matches the condition
    private var weatherIconName: String {
        guard let weather = outfitRepo.preGeneratedWeather ?? outfitRepo.currentWeather else {
            return "cloud"
        }
        let condition = weather.condition.lowercased()
        if condition.contains("clear") || condition.contains("sunny") {
            return "sun.max.fill"
        } else if condition.contains("cloud") {
            return "cloud.fill"
        } else if condition.contains("rain") {
            return "cloud.rain.fill"
        } else if condition.contains("snow") {
            return "cloud.snow.fill"
        }
        return "cloud"
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
            Text("INSIGHTS")
                .kickerStyle()

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
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 90)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
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
                        .frame(width: 36, height: 36)
                        .cornerRadius(6)
                        .clipped()

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Most Worn")
                                .font(AppTypography.labelSmall)
                                .foregroundColor(AppColors.textMuted)
                            Text(item.name)
                                .font(AppTypography.labelMedium)
                                .lineLimit(1)
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                    Spacer(minLength: 0)
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
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 90)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.radiusMd)
        }
        .buttonStyle(.plain)
        .disabled(item == nil)
    }
}

// MARK: - Quick Action Card (Editorial Style)
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)

                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.radiusMd)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Empty Outfit Hero (Animated)
struct EmptyOutfitHero: View {
    let weatherCopy: String
    let onStyleMe: () -> Void

    @State private var hangerOffset: CGFloat = 0
    @State private var contentOpacity: Double = 0

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
                .frame(height: 32)

            // Animated hanger icon
            Image(systemName: "hanger")
                .font(.system(size: 52, weight: .ultraLight))
                .foregroundColor(AppColors.textMuted)
                .offset(y: hangerOffset)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 2.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        hangerOffset = -6
                    }
                }

            VStack(spacing: 10) {
                Text("TODAY'S LOOK")
                    .kickerStyle()

                Text(weatherCopy)
                    .font(AppTypography.editorial(22, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .opacity(contentOpacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    contentOpacity = 1
                }
            }

            Button(action: onStyleMe) {
                Text("Style Me")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppColors.black)
                    .cornerRadius(AppSpacing.radiusMd)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, AppSpacing.lg)
            .opacity(contentOpacity)

            Spacer()
                .frame(height: 32)
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusLg)
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

// MARK: - Daily Outfit Hero Card (Editorial Design - Premium)
struct DailyOutfitHeroCard: View {
    let outfits: [ScoredOutfit]
    let wardrobeItems: [WardrobeItem]
    let onViewTapped: () -> Void

    private var firstOutfit: ScoredOutfit? { outfits.first }

    /// Get hero image URL - try outfit.items first, fallback to wardrobeItems
    private var heroImageUrl: String? {
        if let items = firstOutfit?.items, let firstItem = items.first {
            return firstItem.imageUrl
        }
        if let firstItemId = firstOutfit?.wardrobeItemIds.first,
           let wardrobeItem = wardrobeItems.first(where: { $0.id == firstItemId }) {
            return wardrobeItem.displayPhotoUrl
        }
        return nil
    }

    /// Get preview item URLs for the outfit strip
    private var previewItemUrls: [String] {
        guard let outfit = firstOutfit else { return [] }

        // Try outfit.items first
        if let items = outfit.items, !items.isEmpty {
            return Array(items.prefix(4).compactMap { $0.imageUrl })
        }

        // Fallback to wardrobeItems lookup
        return Array(outfit.wardrobeItemIds.prefix(4).compactMap { id in
            wardrobeItems.first(where: { $0.id == id })?.displayPhotoUrl
        })
    }

    var body: some View {
        VStack(spacing: 0) {
            // Hero image with gradient overlay - DOMINANT
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: heroImageUrl ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .transition(.opacity.combined(with: .scale(scale: 1.02)))
                    case .failure, .empty:
                        Rectangle()
                            .fill(AppColors.backgroundSecondary)
                            .overlay(
                                VStack(spacing: 12) {
                                    Image(systemName: "hanger")
                                        .font(.system(size: 48, weight: .ultraLight))
                                    Text("Your look awaits")
                                        .font(AppTypography.bodyMedium)
                                }
                                .foregroundColor(AppColors.textMuted)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(AppColors.backgroundSecondary)
                    }
                }
                .frame(height: 400)
                .clipped()

                // Premium gradient overlay - deeper, more editorial
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black.opacity(0.3), location: 0.5),
                        .init(color: .black.opacity(0.85), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Text content overlay
                VStack(alignment: .leading, spacing: 8) {
                    Text("TODAY'S LOOK")
                        .font(AppTypography.kicker)
                        .kerning(AppTypography.trackingLoose)
                        .foregroundColor(.white.opacity(0.9))

                    Text(firstOutfit?.headline ?? "Your Perfect Look")
                        .font(AppTypography.editorial(28, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Text("\(outfits.count) look\(outfits.count == 1 ? "" : "s") curated for you")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(.white.opacity(0.75))

                    // Outfit items preview strip
                    if !previewItemUrls.isEmpty {
                        HStack(spacing: -8) {
                            ForEach(Array(previewItemUrls.enumerated()), id: \.offset) { index, url in
                                AsyncImage(url: URL(string: url)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    default:
                                        Circle()
                                            .fill(AppColors.backgroundSecondary)
                                    }
                                }
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1.5))
                                .zIndex(Double(previewItemUrls.count - index))
                            }

                            if previewItemUrls.count < (firstOutfit?.wardrobeItemIds.count ?? 0) {
                                Text("+\((firstOutfit?.wardrobeItemIds.count ?? 0) - previewItemUrls.count)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 44, height: 44)
                                    .background(.white.opacity(0.15))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1.5))
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(24)
            }

            // View button bar - refined
            Button(action: {
                HapticManager.shared.medium()
                onViewTapped()
            }) {
                HStack {
                    Text("View Your Looks")
                        .font(.system(size: 16, weight: .semibold))

                    Spacer()

                    HStack(spacing: 4) {
                        Text("Tap to explore")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .background(AppColors.background)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusXl)
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
        .shadow(color: .black.opacity(0.04), radius: 32, y: 16)
        .padding(.horizontal, AppSpacing.pageMargin)
    }
}

#Preview {
    HomeScreen()
        .environment(AppCoordinator())
}
