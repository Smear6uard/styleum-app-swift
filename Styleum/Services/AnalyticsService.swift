import Foundation
import PostHog

/// Centralized analytics service for tracking user events via PostHog
enum AnalyticsService {

    // MARK: - Configuration

    static func configure() {
        let config = PostHogConfig(apiKey: Config.postHogAPIKey, host: "https://app.posthog.com")
        PostHogSDK.shared.setup(config)
        print("📊 [ANALYTICS] PostHog configured")
    }

    // MARK: - User Identity

    static func identify(userId: String) {
        PostHogSDK.shared.identify(userId)
        print("📊 [ANALYTICS] User identified: \(userId)")
    }

    static func reset() {
        PostHogSDK.shared.reset()
        print("📊 [ANALYTICS] User reset")
    }

    // MARK: - Event Tracking

    static func track(_ event: String, properties: [String: Any]? = nil) {
        PostHogSDK.shared.capture(event, properties: properties)
        print("📊 [ANALYTICS] Event tracked: \(event) \(properties.map { "with properties: \($0)" } ?? "")")
    }
}

// MARK: - Event Names

enum AnalyticsEvent {
    static let userLoggedIn = "user_logged_in"
    static let onboardingStarted = "onboarding_started"
    static let onboardingCompleted = "onboarding_completed"
    static let itemUploaded = "item_uploaded"
    static let outfitGenerated = "outfit_generated"
    static let outfitWorn = "outfit_worn"
    static let outfitShared = "outfit_shared"
    static let streakIncremented = "streak_incremented"
    static let streakBroken = "streak_broken"
    static let paywallViewed = "paywall_viewed"
    static let subscriptionStarted = "subscription_started"
}
