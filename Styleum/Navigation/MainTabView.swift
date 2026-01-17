import SwiftUI

struct MainTabView: View {
    @State private var coordinator = AppCoordinator()
    @State private var tierManager = TierManager.shared
    @State private var profileService = ProfileService.shared
    @AppStorage("hasShownTierOnboarding") private var hasShownTierOnboarding = false

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
            .animation(.easeOut(duration: 0.15), value: coordinator.selectedTab)

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
            print("📱 [MAINTAB] Task started - checking for tier onboarding")
            // Check if new free user needs tier onboarding
            await tierManager.refresh()
            print("📱 [MAINTAB] Tier info refreshed - hasSeenTierOnboarding: \(tierManager.hasSeenTierOnboarding), isFree: \(tierManager.isFree), tierInfo exists: \(tierManager.tierInfo != nil)")
            
            // Only show if we have tier info loaded
            guard tierManager.tierInfo != nil else {
                print("📱 [MAINTAB] ⚠️ No tier info loaded yet")
                return
            }
            
            // Don't show twice per session
            guard !hasShownTierOnboarding else {
                print("📱 [MAINTAB] ⚠️ Already shown tier onboarding this session")
                return
            }
            
            // Check if user just completed onboarding (onboardingVersion just changed to 2)
            let justCompletedOnboarding = profileService.currentProfile?.onboardingVersion == 2
            
            if justCompletedOnboarding {
                print("📱 [MAINTAB] User just completed onboarding - waiting before showing tier onboarding")
                // Small delay for smooth transition after onboarding
                try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s
            }
            
            if !tierManager.hasSeenTierOnboarding && tierManager.isFree {
                print("📱 [MAINTAB] ✅ Showing tier onboarding")
                hasShownTierOnboarding = true
                coordinator.present(.tierOnboarding)
            } else {
                print("📱 [MAINTAB] ⚠️ Not showing tier onboarding - hasSeenTierOnboarding: \(tierManager.hasSeenTierOnboarding), isFree: \(tierManager.isFree)")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showTierOnboarding)) { _ in
            print("📱 [MAINTAB] Received showTierOnboarding notification")
            // Handle tier onboarding trigger from RootView after onboarding completion
            Task {
                print("📱 [MAINTAB] Refreshing tier info from notification...")
                await tierManager.refresh()
                print("📱 [MAINTAB] Tier info refreshed - hasSeenTierOnboarding: \(tierManager.hasSeenTierOnboarding), isFree: \(tierManager.isFree), hasShownTierOnboarding: \(hasShownTierOnboarding)")
                // Small delay to ensure smooth transition
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                // Check if user just completed onboarding - if so, ignore hasShownTierOnboarding flag
                let justCompletedOnboarding = profileService.currentProfile?.onboardingVersion == 2
                let shouldShow = justCompletedOnboarding ? (!tierManager.hasSeenTierOnboarding && tierManager.isFree) : (!hasShownTierOnboarding && !tierManager.hasSeenTierOnboarding && tierManager.isFree)
                
                if shouldShow {
                    print("📱 [MAINTAB] ✅ Showing tier onboarding from notification")
                    hasShownTierOnboarding = true
                    coordinator.present(.tierOnboarding)
                } else {
                    print("📱 [MAINTAB] ⚠️ Not showing tier onboarding from notification - hasShownTierOnboarding: \(hasShownTierOnboarding), hasSeenTierOnboarding: \(tierManager.hasSeenTierOnboarding), isFree: \(tierManager.isFree), justCompletedOnboarding: \(justCompletedOnboarding)")
                }
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
        case .eveningConfirmation:
            EveningConfirmationView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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
        case .sharedOutfit(let shareId):
            SharedOutfitView(shareId: shareId)
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
