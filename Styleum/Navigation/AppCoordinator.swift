import SwiftUI

@MainActor
@Observable
final class AppCoordinator {
    var selectedTab: Tab = .home
    var homePath = NavigationPath()
    var wardrobePath = NavigationPath()
    var styleMePath = NavigationPath()
    var achievementsPath = NavigationPath()
    var profilePath = NavigationPath()

    var activeSheet: SheetDestination?
    var activeFullScreen: FullScreenDestination?

    /// Item pre-selected from wardrobe for "Style this piece" flow
    var preSelectedWardrobeItem: WardrobeItem?

    init() {
        // Observe deep link notifications from push notifications
        NotificationCenter.default.addObserver(
            forName: .navigateToDailyOutfit,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let coordinator = self else { return }
            Task { @MainActor in
                coordinator.handleDailyOutfitDeepLink()
            }
        }

        // Observe quick action: Style Me
        NotificationCenter.default.addObserver(
            forName: .navigateToStyleMe,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let coordinator = self else { return }
            Task { @MainActor in
                coordinator.switchTab(to: .styleMe)
            }
        }

        // Observe quick action: Add Item
        NotificationCenter.default.addObserver(
            forName: .openAddItem,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let coordinator = self else { return }
            Task { @MainActor in
                coordinator.switchTab(to: .wardrobe)
                // Slight delay to ensure tab switch completes
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                coordinator.present(.addItem)
            }
        }

        // Observe quick action: My Wardrobe
        NotificationCenter.default.addObserver(
            forName: .navigateToWardrobe,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let coordinator = self else { return }
            Task { @MainActor in
                coordinator.switchTab(to: .wardrobe)
            }
        }
    }

    /// Handles deep link navigation to Style Me tab
    private func handleDailyOutfitDeepLink() {
        print("🔗 [NAV] Deep link: navigating to Style Me tab")
        switchTab(to: .styleMe)
    }

    // MARK: - Tabs
    enum Tab: Int, CaseIterable {
        case home = 0
        case wardrobe = 1
        case styleMe = 2
        case achievements = 3
        case profile = 4

        var title: String {
            switch self {
            case .home: return "Home"
            case .wardrobe: return "Wardrobe"
            case .styleMe: return "Style Me"
            case .achievements: return "Achievements"
            case .profile: return "Profile"
            }
        }

        var symbol: AppSymbol {
            switch self {
            case .home: return .home
            case .wardrobe: return .wardrobe
            case .styleMe: return .styleMe
            case .achievements: return .achievements
            case .profile: return .profile
            }
        }
    }

    // MARK: - Navigation Destinations
    enum Destination: Hashable {
        case itemDetail(itemId: String)
        case outfitDetail(outfitId: String)
        case settings
        case editProfile
        case subscription
        case deleteAccount
        case notificationSettings
    }

    // MARK: - Sheet Destinations
    enum SheetDestination: Identifiable {
        case addItem
        case customizeStyleMe
        case outfitOptions(outfitId: String)
        case achievementDetail(achievementId: String)
        case createOutfit(itemIds: [String])
        case tierOnboarding

        var id: String {
            switch self {
            case .addItem: return "addItem"
            case .customizeStyleMe: return "customizeStyleMe"
            case .outfitOptions(let id): return "outfitOptions_\(id)"
            case .achievementDetail(let id): return "achievementDetail_\(id)"
            case .createOutfit: return "createOutfit"
            case .tierOnboarding: return "tierOnboarding"
            }
        }
    }

    // MARK: - Full Screen Destinations
    enum FullScreenDestination: Identifiable {
        case onboarding
        case styleQuiz       // Standalone style quiz for users who skipped during onboarding
        case aiProcessing
        case outfitResults

        var id: String {
            switch self {
            case .onboarding: return "onboarding"
            case .styleQuiz: return "styleQuiz"
            case .aiProcessing: return "aiProcessing"
            case .outfitResults: return "outfitResults"
            }
        }
    }

    // MARK: - Navigation Methods
    func navigate(to destination: Destination) {
        switch selectedTab {
        case .home:
            homePath.append(destination)
        case .wardrobe:
            wardrobePath.append(destination)
        case .styleMe:
            styleMePath.append(destination)
        case .achievements:
            achievementsPath.append(destination)
        case .profile:
            profilePath.append(destination)
        }
    }

    func pop() {
        switch selectedTab {
        case .home:
            if !homePath.isEmpty { homePath.removeLast() }
        case .wardrobe:
            if !wardrobePath.isEmpty { wardrobePath.removeLast() }
        case .styleMe:
            if !styleMePath.isEmpty { styleMePath.removeLast() }
        case .achievements:
            if !achievementsPath.isEmpty { achievementsPath.removeLast() }
        case .profile:
            if !profilePath.isEmpty { profilePath.removeLast() }
        }
    }

    func popToRoot() {
        switch selectedTab {
        case .home:
            homePath = NavigationPath()
        case .wardrobe:
            wardrobePath = NavigationPath()
        case .styleMe:
            styleMePath = NavigationPath()
        case .achievements:
            achievementsPath = NavigationPath()
        case .profile:
            profilePath = NavigationPath()
        }
    }

    func present(_ sheet: SheetDestination) {
        HapticManager.shared.light()
        activeSheet = sheet
    }

    func presentFullScreen(_ destination: FullScreenDestination) {
        activeFullScreen = destination
    }

    func dismissSheet() {
        activeSheet = nil
    }

    func dismissFullScreen() {
        activeFullScreen = nil
    }

    func switchTab(to tab: Tab) {
        HapticManager.shared.selection()

        // If already on this tab, pop to root
        if selectedTab == tab {
            popToRoot()
        } else {
            selectedTab = tab
        }
    }

    /// Navigate to Style Me with pre-selected item for "Style this piece" flow
    func styleThisPiece(_ item: WardrobeItem) {
        preSelectedWardrobeItem = item
        switchTab(to: .styleMe)
    }
}
