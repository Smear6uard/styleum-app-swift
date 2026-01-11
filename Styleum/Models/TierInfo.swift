import Foundation

// MARK: - Tier Info

/// Complete tier information including limits and current usage
struct TierInfo: Codable {
    let tier: String
    let limits: TierLimits
    let usage: TierUsage
    let canAddItem: Bool
    let canGenerateOutfit: Bool
    let canUseStyleMe: Bool

    // Subscription status
    let gracePeriodEndsAt: Date?
    let subscriptionExpiresAt: Date?
    let subscriptionCancelledAt: Date?
    let hasBillingIssue: Bool
    let hasSeenTierOnboarding: Bool

    var isPro: Bool { tier == "pro" }
    var isFree: Bool { tier == "free" }

    enum CodingKeys: String, CodingKey {
        case tier
        case limits
        case usage
        case canAddItem = "can_add_item"
        case canGenerateOutfit = "can_generate_outfit"
        case canUseStyleMe = "can_use_style_me"
        case gracePeriodEndsAt = "grace_period_ends_at"
        case subscriptionExpiresAt = "subscription_expires_at"
        case subscriptionCancelledAt = "subscription_cancelled_at"
        case hasBillingIssue = "has_billing_issue"
        case hasSeenTierOnboarding = "has_seen_tier_onboarding"
    }
}

// MARK: - Tier Limits

/// Limits for a given tier (free vs pro)
struct TierLimits: Codable {
    let maxWardrobeItems: Int
    let dailyOutfits: Int
    let monthlyStyleMeCredits: Int
    let outfitHistoryDays: Int
    let streakFreezesPerMonth: Int
    let hasAnalytics: Bool
    let hasOccasionStyling: Bool
    let hasExport: Bool

    enum CodingKeys: String, CodingKey {
        case maxWardrobeItems = "max_wardrobe_items"
        case dailyOutfits = "daily_outfits"
        case monthlyStyleMeCredits = "monthly_style_me_credits"
        case outfitHistoryDays = "outfit_history_days"
        case streakFreezesPerMonth = "streak_freezes_per_month"
        case hasAnalytics = "has_analytics"
        case hasOccasionStyling = "has_occasion_styling"
        case hasExport = "has_export"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        maxWardrobeItems = try container.decodeIfPresent(Int.self, forKey: .maxWardrobeItems) ?? 30
        dailyOutfits = try container.decodeIfPresent(Int.self, forKey: .dailyOutfits) ?? 2
        monthlyStyleMeCredits = try container.decodeIfPresent(Int.self, forKey: .monthlyStyleMeCredits) ?? 5
        outfitHistoryDays = try container.decodeIfPresent(Int.self, forKey: .outfitHistoryDays) ?? 7
        streakFreezesPerMonth = try container.decodeIfPresent(Int.self, forKey: .streakFreezesPerMonth) ?? 1
        hasAnalytics = try container.decodeIfPresent(Bool.self, forKey: .hasAnalytics) ?? false
        hasOccasionStyling = try container.decodeIfPresent(Bool.self, forKey: .hasOccasionStyling) ?? false
        hasExport = try container.decodeIfPresent(Bool.self, forKey: .hasExport) ?? false
    }

    init(
        maxWardrobeItems: Int,
        dailyOutfits: Int,
        monthlyStyleMeCredits: Int,
        outfitHistoryDays: Int,
        streakFreezesPerMonth: Int,
        hasAnalytics: Bool,
        hasOccasionStyling: Bool,
        hasExport: Bool
    ) {
        self.maxWardrobeItems = maxWardrobeItems
        self.dailyOutfits = dailyOutfits
        self.monthlyStyleMeCredits = monthlyStyleMeCredits
        self.outfitHistoryDays = outfitHistoryDays
        self.streakFreezesPerMonth = streakFreezesPerMonth
        self.hasAnalytics = hasAnalytics
        self.hasOccasionStyling = hasOccasionStyling
        self.hasExport = hasExport
    }

    /// Free tier defaults
    static let free = TierLimits(
        maxWardrobeItems: 30,
        dailyOutfits: 2,
        monthlyStyleMeCredits: 5,
        outfitHistoryDays: 7,
        streakFreezesPerMonth: 1,
        hasAnalytics: false,
        hasOccasionStyling: false,
        hasExport: false
    )

    /// Pro tier defaults
    static let pro = TierLimits(
        maxWardrobeItems: Int.max,
        dailyOutfits: 4,
        monthlyStyleMeCredits: Int.max,
        outfitHistoryDays: Int.max,
        streakFreezesPerMonth: 5,
        hasAnalytics: true,
        hasOccasionStyling: true,
        hasExport: true
    )
}

// MARK: - Tier Usage

/// Current usage within the tier limits
struct TierUsage: Codable {
    let wardrobeItems: Int
    let wardrobeLimit: Int
    let wardrobeRemaining: Int
    let dailyOutfitsUsed: Int
    let dailyOutfitsLimit: Int
    let styleCreditsUsed: Int
    let styleCreditsLimit: Int
    let styleCreditsRemaining: Int
    let creditsResetsAt: Date?

    // Streak freeze tracking
    let streakFreezesUsed: Int
    let streakFreezesLimit: Int
    let freezesResetAt: Date?

    enum CodingKeys: String, CodingKey {
        case wardrobeItems = "wardrobe_items"
        case wardrobeLimit = "wardrobe_limit"
        case wardrobeRemaining = "wardrobe_remaining"
        case dailyOutfitsUsed = "daily_outfits_used"
        case dailyOutfitsLimit = "daily_outfits_limit"
        case styleCreditsUsed = "style_credits_used"
        case styleCreditsLimit = "style_credits_limit"
        case styleCreditsRemaining = "style_credits_remaining"
        case creditsResetsAt = "credits_resets_at"
        case streakFreezesUsed = "streak_freezes_used"
        case streakFreezesLimit = "streak_freezes_limit"
        case freezesResetAt = "freezes_reset_at"
    }

    /// Days until credits reset
    var daysUntilReset: Int {
        guard let resetsAt = creditsResetsAt else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: resetsAt).day ?? 0
        return max(0, days)
    }
}
