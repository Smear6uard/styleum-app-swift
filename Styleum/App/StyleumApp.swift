//
//  StyleumApp.swift
//  Styleum
//
//  Created by Sameer Akhtar on 1/3/26.
//

import SwiftUI
import GoogleSignIn
import UserNotifications

@main
struct StyleumApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Initialize managers at app launch
    private let supabase = SupabaseManager.shared
    private let haptics = HapticManager.shared

    init() {
        // Configure Google Sign-In with client ID
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: Config.googleClientID)
        print("✅ Google Sign-In configured with client ID")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)  // Force light mode for MVP
                .onOpenURL { url in
                    print("📱 Received URL: \(url)")

                    // Handle Google Sign-In
                    if GIDSignIn.sharedInstance.handle(url) {
                        return
                    }

                    // Handle referral deep links
                    if let code = Self.parseReferralCode(from: url) {
                        ReferralService.shared.storePendingCode(code)
                        print("📨 [Referral] Stored referral code from deep link: \(code)")
                    }
                }
        }
    }

    // MARK: - Referral Deep Link Parsing

    /// Parses a referral code from a deep link URL
    /// Supports: styleum://referral?code=XXX and https://styleum.app/r/XXX
    private static func parseReferralCode(from url: URL) -> String? {
        // Handle styleum://referral?code=XXX
        if url.scheme == "styleum" && url.host == "referral" {
            return URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "code" })?.value
        }

        // Handle https://styleum.app/r/XXX
        if url.host == "styleum.app" && url.pathComponents.contains("r") {
            if let index = url.pathComponents.firstIndex(of: "r"),
               index + 1 < url.pathComponents.count {
                return url.pathComponents[index + 1]
            }
        }

        return nil
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Register custom fonts from asset catalog
        FontManager.registerFonts()

        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        print("📱 [APP] AppDelegate initialized, notification delegate set")

        // Note: Quick actions launched from cold start are handled by
        // application(_:performActionFor:completionHandler:) delegate method

        return true
    }

    // MARK: - Quick Actions (3D Touch / Long Press on App Icon)

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let handled = handleShortcutItem(shortcutItem)
        completionHandler(handled)
    }

    @discardableResult
    private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        print("📱 [APP] Quick action triggered: \(shortcutItem.type)")

        switch shortcutItem.type {
        case "com.styleum.styleme":
            // Navigate to Style Me tab
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .navigateToStyleMe, object: nil)
            }
            return true
        case "com.styleum.additem":
            // Navigate to Wardrobe and open Add Item sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .openAddItem, object: nil)
            }
            return true
        case "com.styleum.wardrobe":
            // Navigate to Wardrobe tab
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .navigateToWardrobe, object: nil)
            }
            return true
        default:
            print("📱 [APP] Unknown quick action type: \(shortcutItem.type)")
            return false
        }
    }

    // MARK: - Remote Notification Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        PushNotificationService.shared.handleDeviceToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        PushNotificationService.shared.handleRegistrationError(error)
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when a notification is received while the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show the notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Called when the user taps on a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("📱 [APP] Notification tapped with userInfo: \(userInfo)")

        // Handle deep linking based on notification type
        if let type = userInfo["type"] as? String {
            switch type {
            case "daily_outfit":
                // Navigate to Style Me tab
                NotificationCenter.default.post(name: .navigateToDailyOutfit, object: nil)
            default:
                print("📱 [APP] Unknown notification type: \(type)")
            }
        }

        completionHandler()
    }
}
