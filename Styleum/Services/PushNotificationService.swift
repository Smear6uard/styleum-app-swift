import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

@Observable
final class PushNotificationService {
    static let shared = PushNotificationService()

    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var deviceToken: String?

    private let api = StyleumAPI.shared

    private init() {
        // Check initial authorization status
        Task {
            await refreshAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    /// Refreshes the current authorization status from the system
    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            self.authorizationStatus = settings.authorizationStatus
        }
    }

    /// Requests notification permission and registers for remote notifications if granted
    /// - Returns: true if authorization was granted
    @discardableResult
    func requestAuthorization() async -> Bool {
        print("🔔 [PUSH] Requesting notification authorization...")

        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )

            await refreshAuthorizationStatus()

            if granted {
                print("🔔 [PUSH] ✅ Authorization granted")
                registerForRemoteNotifications()
            } else {
                print("🔔 [PUSH] ❌ Authorization denied")
            }

            return granted
        } catch {
            print("🔔 [PUSH] ❌ Authorization error: \(error)")
            return false
        }
    }

    /// Registers for remote notifications on the main thread
    @MainActor
    private func registerForRemoteNotifications() {
        #if canImport(UIKit) && !targetEnvironment(simulator)
        UIApplication.shared.registerForRemoteNotifications()
        print("🔔 [PUSH] Registered for remote notifications")
        #else
        print("🔔 [PUSH] ⚠️ Remote notifications not available (simulator or non-iOS)")
        #endif
    }

    // MARK: - Token Handling

    /// Handles the device token received from APNs
    /// - Parameter tokenData: Raw token data from didRegisterForRemoteNotificationsWithDeviceToken
    func handleDeviceToken(_ tokenData: Data) {
        // Convert token data to hex string
        let tokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString

        print("🔔 [PUSH] ✅ Received device token: \(tokenString.prefix(20))...")

        // Send token to backend
        Task {
            await sendTokenToBackend(tokenString)
        }
    }

    /// Handles registration failure
    func handleRegistrationError(_ error: Error) {
        print("🔔 [PUSH] ❌ Failed to register for remote notifications: \(error)")
    }

    /// Sends the push token to the backend
    private func sendTokenToBackend(_ token: String) async {
        do {
            try await api.registerPushToken(token)
            print("🔔 [PUSH] ✅ Token registered with backend")
        } catch {
            print("🔔 [PUSH] ❌ Failed to register token with backend: \(error)")
        }
    }

    // MARK: - Helpers

    /// Opens the app's notification settings in System Settings
    @MainActor
    func openSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when a push notification should navigate to the daily outfit screen
    static let navigateToDailyOutfit = Notification.Name("navigateToDailyOutfit")

    /// Posted when quick action should navigate to Style Me tab
    static let navigateToStyleMe = Notification.Name("navigateToStyleMe")

    /// Posted when quick action should open Add Item sheet
    static let openAddItem = Notification.Name("openAddItem")

    /// Posted when quick action should navigate to Wardrobe tab
    static let navigateToWardrobe = Notification.Name("navigateToWardrobe")

    /// Posted when tier onboarding should be shown after onboarding completion
    static let showTierOnboarding = Notification.Name("showTierOnboarding")

    /// Posted when push notification should navigate to Achievements tab
    static let navigateToAchievements = Notification.Name("navigateToAchievements")

    /// Posted when evening confirmation notification should show the confirmation sheet
    static let showEveningConfirmation = Notification.Name("showEveningConfirmation")

    /// Posted when a shared outfit deep link is opened
    static let navigateToSharedOutfit = Notification.Name("navigateToSharedOutfit")
}
