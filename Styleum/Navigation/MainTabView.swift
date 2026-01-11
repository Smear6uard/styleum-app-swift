import SwiftUI

struct MainTabView: View {
    @State private var coordinator = AppCoordinator()
    @State private var tierManager = TierManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Tab content - ZStack with spring transitions
            ZStack {
                HomeTab(coordinator: coordinator)
                    .tabTransition(isActive: coordinator.selectedTab == .home)

                WardrobeTab(coordinator: coordinator)
                    .tabTransition(isActive: coordinator.selectedTab == .wardrobe)

                StyleMeTab(coordinator: coordinator)
                    .tabTransition(isActive: coordinator.selectedTab == .styleMe)

                AchievementsTab(coordinator: coordinator)
                    .tabTransition(isActive: coordinator.selectedTab == .achievements)

                ProfileTab(coordinator: coordinator)
                    .tabTransition(isActive: coordinator.selectedTab == .profile)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: coordinator.selectedTab)

            // Custom tab bar
            TabBar(selectedTab: $coordinator.selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .edgesIgnoringSafeArea(.bottom)
        .sheet(item: $coordinator.activeSheet) { sheet in
            sheetContent(for: sheet)
        }
        .fullScreenCover(item: $coordinator.activeFullScreen) { destination in
            fullScreenContent(for: destination)
        }
        .environment(coordinator)
        .task {
            // Check if new free user needs tier onboarding
            await tierManager.refresh()
            if !tierManager.hasSeenTierOnboarding && tierManager.isFree {
                coordinator.present(.tierOnboarding)
            }
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: AppCoordinator.SheetDestination) -> some View {
        switch sheet {
        case .addItem:
            AddItemSheet()
        case .customizeStyleMe:
            CustomizeStyleMeSheet()
        case .outfitOptions(let outfitId):
            OutfitOptionsSheet(outfitId: outfitId)
        case .achievementDetail(let achievementId):
            AchievementDetailSheet(achievementId: achievementId)
        case .createOutfit(let itemIds):
            CreateOutfitSheet(itemIds: itemIds)
        case .tierOnboarding:
            TierOnboardingSheet()
        case .applyReferralCode:
            ApplyCodeSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        case .referralCelebration(let daysEarned):
            ReferralCelebrationView(daysEarned: daysEarned)
        }
    }

    @ViewBuilder
    private func fullScreenContent(for destination: AppCoordinator.FullScreenDestination) -> some View {
        switch destination {
        case .onboarding:
            OnboardingContainerView()
        case .styleQuiz:
            StandaloneStyleQuizView()
        case .aiProcessing:
            AIProcessingView()
        case .outfitResults:
            OutfitResultsView(isInlineMode: false)  // Modal mode - uses dismiss()
        }
    }
}

// MARK: - Tab Containers
struct HomeTab: View {
    @Bindable var coordinator: AppCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.homePath) {
            HomeScreen()
                .navigationDestination(for: AppCoordinator.Destination.self) { destination in
                    destinationView(for: destination)
                }
        }
    }
}

struct WardrobeTab: View {
    @Bindable var coordinator: AppCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.wardrobePath) {
            WardrobeScreen()
                .navigationDestination(for: AppCoordinator.Destination.self) { destination in
                    destinationView(for: destination)
                }
        }
    }
}

struct StyleMeTab: View {
    @Bindable var coordinator: AppCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.styleMePath) {
            StyleMeScreen()
                .navigationDestination(for: AppCoordinator.Destination.self) { destination in
                    destinationView(for: destination)
                }
        }
    }
}

struct AchievementsTab: View {
    @Bindable var coordinator: AppCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.achievementsPath) {
            AchievementsScreen()
                .navigationDestination(for: AppCoordinator.Destination.self) { destination in
                    destinationView(for: destination)
                }
        }
    }
}

struct ProfileTab: View {
    @Bindable var coordinator: AppCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.profilePath) {
            ProfileScreen()
                .navigationDestination(for: AppCoordinator.Destination.self) { destination in
                    destinationView(for: destination)
                }
        }
    }
}

// MARK: - Destination View Builder
@ViewBuilder
func destinationView(for destination: AppCoordinator.Destination) -> some View {
    switch destination {
    case .itemDetail(let itemId):
        ItemDetailScreen(itemId: itemId)
    case .outfitDetail(let outfitId):
        OutfitDetailScreen(outfitId: outfitId)
    case .settings:
        SettingsScreen()
    case .subscription:
        ProUpgradeView(trigger: .manual)
    case .deleteAccount:
        DeleteAccountView()
    case .notificationSettings:
        NotificationSettingsScreen()
    case .referral:
        ReferralView()
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}
