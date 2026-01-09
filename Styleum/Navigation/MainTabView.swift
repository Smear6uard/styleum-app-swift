import SwiftUI

struct MainTabView: View {
    @State private var coordinator = AppCoordinator()
    @State private var tierManager = TierManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Tab content
            TabView(selection: $coordinator.selectedTab) {
                HomeTab(coordinator: coordinator)
                    .tag(AppCoordinator.Tab.home)

                WardrobeTab(coordinator: coordinator)
                    .tag(AppCoordinator.Tab.wardrobe)

                StyleMeTab(coordinator: coordinator)
                    .tag(AppCoordinator.Tab.styleMe)

                AchievementsTab(coordinator: coordinator)
                    .tag(AppCoordinator.Tab.achievements)

                ProfileTab(coordinator: coordinator)
                    .tag(AppCoordinator.Tab.profile)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

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
            OutfitResultsView()
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
    case .editProfile:
        EditProfileScreen()
    case .subscription:
        ProUpgradeView(trigger: .manual)
    case .deleteAccount:
        DeleteAccountView()
    case .notificationSettings:
        NotificationSettingsScreen()
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
}
