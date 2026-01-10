import Foundation

/// Manages user tier status and usage limits
@Observable
final class TierManager {
    static let shared = TierManager()
    private let api = StyleumAPI.shared

    // MARK: - State

    var tierInfo: TierInfo?
    var isLoading = false
    var error: Error?

    // MARK: - Convenience Properties

    var isPro: Bool { tierInfo?.isPro ?? false }
    var isFree: Bool { tierInfo?.isFree ?? true }

    var wardrobeRemaining: Int { tierInfo?.usage.wardrobeRemaining ?? 0 }
    var canAddItem: Bool { tierInfo?.canAddItem ?? true }

    var canGenerateOutfit: Bool { tierInfo?.canGenerateOutfit ?? true }
    var styleCreditsRemaining: Int { tierInfo?.usage.styleCreditsRemaining ?? 0 }

    var dailyOutfitsLimit: Int { tierInfo?.limits.dailyOutfits ?? 2 }
    var dailyOutfitsUsed: Int { tierInfo?.usage.dailyOutfitsUsed ?? 0 }
    var dailyOutfitsRemaining: Int {
        guard let info = tierInfo else { return 2 }
        return max(0, info.limits.dailyOutfits - info.usage.dailyOutfitsUsed)
    }

    var streakFreezesLimit: Int { tierInfo?.limits.streakFreezesPerMonth ?? 1 }
    var hasAnalytics: Bool { tierInfo?.limits.hasAnalytics ?? false }
    var hasExport: Bool { tierInfo?.limits.hasExport ?? false }

    var daysUntilCreditsReset: Int { tierInfo?.usage.daysUntilReset ?? 0 }

    // MARK: - Subscription State Properties

    var hasBillingIssue: Bool {
        tierInfo?.hasBillingIssue ?? false
    }

    var inGracePeriod: Bool {
        guard let endsAt = tierInfo?.gracePeriodEndsAt else { return false }
        return endsAt > Date()
    }

    var isCancelled: Bool {
        tierInfo?.subscriptionCancelledAt != nil
    }

    var isOverLimit: Bool {
        guard let info = tierInfo, info.isFree else { return false }
        return info.usage.wardrobeItems > info.limits.maxWardrobeItems
    }

    var gracePeriodDaysRemaining: Int {
        guard let endsAt = tierInfo?.gracePeriodEndsAt else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: endsAt).day ?? 0
    }

    var subscriptionExpiryDate: Date? {
        tierInfo?.subscriptionExpiresAt
    }

    var streakFreezesRemaining: Int {
        guard let usage = tierInfo?.usage else { return 0 }
        return usage.streakFreezesLimit - usage.streakFreezesUsed
    }

    var hasSeenTierOnboarding: Bool {
        tierInfo?.hasSeenTierOnboarding ?? true
    }

    // MARK: - Init

    private init() {}

    // MARK: - Fetch

    @MainActor
    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            tierInfo = try await api.getTierInfo()
            error = nil
            print("[TierManager] Refreshed tier: \(tierInfo?.tier ?? "unknown")")
        } catch {
            self.error = error
            print("[TierManager] Failed to refresh: \(error)")
        }
    }

    /// Optimistically update usage after an action
    @MainActor
    func decrementStyleCredits() {
        guard let info = tierInfo else { return }
        // Create updated usage with decremented credits
        let updatedUsage = TierUsage(
            wardrobeItems: info.usage.wardrobeItems,
            wardrobeLimit: info.usage.wardrobeLimit,
            wardrobeRemaining: info.usage.wardrobeRemaining,
            dailyOutfitsUsed: info.usage.dailyOutfitsUsed + 1,
            dailyOutfitsLimit: info.usage.dailyOutfitsLimit,
            styleCreditsUsed: info.usage.styleCreditsUsed + 1,
            styleCreditsLimit: info.usage.styleCreditsLimit,
            styleCreditsRemaining: max(0, info.usage.styleCreditsRemaining - 1),
            creditsResetsAt: info.usage.creditsResetsAt,
            streakFreezesUsed: info.usage.streakFreezesUsed,
            streakFreezesLimit: info.usage.streakFreezesLimit,
            freezesResetAt: info.usage.freezesResetAt
        )
        tierInfo = TierInfo(
            tier: info.tier,
            limits: info.limits,
            usage: updatedUsage,
            canAddItem: info.canAddItem,
            canGenerateOutfit: updatedUsage.styleCreditsRemaining > 0,
            canUseStyleMe: updatedUsage.styleCreditsRemaining > 0,
            gracePeriodEndsAt: info.gracePeriodEndsAt,
            subscriptionExpiresAt: info.subscriptionExpiresAt,
            subscriptionCancelledAt: info.subscriptionCancelledAt,
            hasBillingIssue: info.hasBillingIssue,
            hasSeenTierOnboarding: info.hasSeenTierOnboarding
        )
    }

    /// Optimistically update usage after adding wardrobe item
    @MainActor
    func incrementWardrobeItems() {
        guard let info = tierInfo else { return }
        let newCount = info.usage.wardrobeItems + 1
        let newRemaining = max(0, info.usage.wardrobeRemaining - 1)
        let updatedUsage = TierUsage(
            wardrobeItems: newCount,
            wardrobeLimit: info.usage.wardrobeLimit,
            wardrobeRemaining: newRemaining,
            dailyOutfitsUsed: info.usage.dailyOutfitsUsed,
            dailyOutfitsLimit: info.usage.dailyOutfitsLimit,
            styleCreditsUsed: info.usage.styleCreditsUsed,
            styleCreditsLimit: info.usage.styleCreditsLimit,
            styleCreditsRemaining: info.usage.styleCreditsRemaining,
            creditsResetsAt: info.usage.creditsResetsAt,
            streakFreezesUsed: info.usage.streakFreezesUsed,
            streakFreezesLimit: info.usage.streakFreezesLimit,
            freezesResetAt: info.usage.freezesResetAt
        )
        tierInfo = TierInfo(
            tier: info.tier,
            limits: info.limits,
            usage: updatedUsage,
            canAddItem: newRemaining > 0 || info.isPro,
            canGenerateOutfit: info.canGenerateOutfit,
            canUseStyleMe: info.canUseStyleMe,
            gracePeriodEndsAt: info.gracePeriodEndsAt,
            subscriptionExpiresAt: info.subscriptionExpiresAt,
            subscriptionCancelledAt: info.subscriptionCancelledAt,
            hasBillingIssue: info.hasBillingIssue,
            hasSeenTierOnboarding: info.hasSeenTierOnboarding
        )
    }

    // MARK: - Streak Freeze

    @MainActor
    func useStreakFreeze() async -> Bool {
        guard streakFreezesRemaining > 0 else { return false }

        do {
            _ = try await api.useStreakFreeze()
            await refresh()
            return true
        } catch {
            print("[TierManager] Failed to use streak freeze: \(error)")
            return false
        }
    }

    // MARK: - Onboarding

    @MainActor
    func markOnboardingSeen() async {
        do {
            try await api.markTierOnboardingSeen()
            await refresh()
        } catch {
            print("[TierManager] Failed to mark onboarding seen: \(error)")
        }
    }

    // MARK: - Reset

    func reset() {
        tierInfo = nil
        error = nil
    }
}
