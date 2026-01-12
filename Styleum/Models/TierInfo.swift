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
    var wardrobeItems: Int
    var wardrobeLimit: Int
    var wardrobeRemaining: Int
    var dailyOutfitsUsed: Int
    var dailyOutfitsLimit: Int
    var styleCreditsUsed: Int
    var styleCreditsLimit: Int
    var styleCreditsRemaining: Int
    var creditsResetsAt: Date?

    // Streak freeze tracking
    var streakFreezesUsed: Int
    var streakFreezesLimit: Int
    var freezesResetAt: Date?

    enum CodingKeys: String, CodingKey {
        case wardrobeItems = "wardrobe_items"
        case wardrobeLimit = "wardrobe_limit"
        case wardrobeRemaining = "wardrobe_remaining"
        case dailyOutfitsUsed = "daily_outfits_used"
        case dailyOutfitsLimit = "daily_outfits_limit"
        // Flat keys (legacy)
        case styleCreditsUsed = "style_credits_used"
        case styleCreditsLimit = "style_credits_limit"
        case styleCreditsRemaining = "style_credits_remaining"
        case creditsResetsAt = "credits_resets_at"
        // Nested key (current backend format)
        case monthlyCredits = "monthlyCredits"
        // Streak freezes
        case streakFreezesUsed = "streak_freezes_used"
        case streakFreezesLimit = "streak_freezes_limit"
        case freezesResetAt = "freezes_reset_at"
    }

    /// Nested structure for monthly credits from backend
    private struct MonthlyCredits: Codable {
        let used: Int
        let limit: Int
        let remaining: Int
        let resetsAt: Date?
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode wardrobe fields
        wardrobeItems = try container.decodeIfPresent(Int.self, forKey: .wardrobeItems) ?? 0
        wardrobeLimit = try container.decodeIfPresent(Int.self, forKey: .wardrobeLimit) ?? 30
        wardrobeRemaining = try container.decodeIfPresent(Int.self, forKey: .wardrobeRemaining) ?? 30
        dailyOutfitsUsed = try container.decodeIfPresent(Int.self, forKey: .dailyOutfitsUsed) ?? 0
        dailyOutfitsLimit = try container.decodeIfPresent(Int.self, forKey: .dailyOutfitsLimit) ?? 2

        // Try nested monthlyCredits first (current backend format)
        if let monthlyCredits = try? container.decode(MonthlyCredits.self, forKey: .monthlyCredits) {
            styleCreditsUsed = monthlyCredits.used
            styleCreditsLimit = monthlyCredits.limit
            styleCreditsRemaining = monthlyCredits.remaining
            creditsResetsAt = monthlyCredits.resetsAt
        } else {
            // Fall back to flat keys (legacy format)
            styleCreditsUsed = try container.decodeIfPresent(Int.self, forKey: .styleCreditsUsed) ?? 0
            styleCreditsLimit = try container.decodeIfPresent(Int.self, forKey: .styleCreditsLimit) ?? 5
            styleCreditsRemaining = try container.decodeIfPresent(Int.self, forKey: .styleCreditsRemaining) ?? 5
            creditsResetsAt = try container.decodeIfPresent(Date.self, forKey: .creditsResetsAt)
        }

        // Decode streak freeze fields
        streakFreezesUsed = try container.decodeIfPresent(Int.self, forKey: .streakFreezesUsed) ?? 0
        streakFreezesLimit = try container.decodeIfPresent(Int.self, forKey: .streakFreezesLimit) ?? 1
        freezesResetAt = try container.decodeIfPresent(Date.self, forKey: .freezesResetAt)
    }

    /// Memberwise initializer for optimistic updates
    init(
        wardrobeItems: Int,
        wardrobeLimit: Int,
        wardrobeRemaining: Int,
        dailyOutfitsUsed: Int,
        dailyOutfitsLimit: Int,
        styleCreditsUsed: Int,
        styleCreditsLimit: Int,
        styleCreditsRemaining: Int,
        creditsResetsAt: Date?,
        streakFreezesUsed: Int,
        streakFreezesLimit: Int,
        freezesResetAt: Date?
    ) {
        self.wardrobeItems = wardrobeItems
        self.wardrobeLimit = wardrobeLimit
        self.wardrobeRemaining = wardrobeRemaining
        self.dailyOutfitsUsed = dailyOutfitsUsed
        self.dailyOutfitsLimit = dailyOutfitsLimit
        self.styleCreditsUsed = styleCreditsUsed
        self.styleCreditsLimit = styleCreditsLimit
        self.styleCreditsRemaining = styleCreditsRemaining
        self.creditsResetsAt = creditsResetsAt
        self.streakFreezesUsed = streakFreezesUsed
        self.streakFreezesLimit = streakFreezesLimit
        self.freezesResetAt = freezesResetAt
    }

    /// Days until credits reset
    var daysUntilReset: Int {
        guard let resetsAt = creditsResetsAt else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: resetsAt).day ?? 0
        return max(0, days)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(wardrobeItems, forKey: .wardrobeItems)
        try container.encode(wardrobeLimit, forKey: .wardrobeLimit)
        try container.encode(wardrobeRemaining, forKey: .wardrobeRemaining)
        try container.encode(dailyOutfitsUsed, forKey: .dailyOutfitsUsed)
        try container.encode(dailyOutfitsLimit, forKey: .dailyOutfitsLimit)
        try container.encode(styleCreditsUsed, forKey: .styleCreditsUsed)
        try container.encode(styleCreditsLimit, forKey: .styleCreditsLimit)
        try container.encode(styleCreditsRemaining, forKey: .styleCreditsRemaining)
        try container.encodeIfPresent(creditsResetsAt, forKey: .creditsResetsAt)
        try container.encode(streakFreezesUsed, forKey: .streakFreezesUsed)
        try container.encode(streakFreezesLimit, forKey: .streakFreezesLimit)
        try container.encodeIfPresent(freezesResetAt, forKey: .freezesResetAt)
    }
}
