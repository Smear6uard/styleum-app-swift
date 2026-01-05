import Foundation

@Observable
final class OutfitRepository {
    static let shared = OutfitRepository()

    private let api = StyleumAPI.shared
    private let wardrobeService = WardrobeService.shared

    var todaysOutfits: [ScoredOutfit] = []
    var isLoading = false
    var isGenerating = false
    var error: Error?

    // Cache
    private var cacheTimestamp: Date?
    private let cacheExpiry: TimeInterval = 4 * 60 * 60 // 4 hours

    private init() {}

    // MARK: - Get Today's Outfits

    func getTodaysOutfits(forceRefresh: Bool = false) async {
        guard SupabaseManager.shared.currentUserId != nil else { return }

        // Check cache
        if !forceRefresh, let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheExpiry,
           !todaysOutfits.isEmpty {
            return
        }

        isLoading = true
        defer { isLoading = false }

        // Try to get cached outfits first, fall back to generation
        await generateOutfits()
    }

    // MARK: - Generate Outfits

    func generateOutfits(preferences: StylePreferences? = nil) async {
        guard SupabaseManager.shared.currentUserId != nil else { return }

        // Check if user has enough items
        guard wardrobeService.hasEnoughForOutfits else {
            error = OutfitError.notEnoughItems
            return
        }

        isGenerating = true
        defer { isGenerating = false }

        do {
            let result = try await api.generateOutfits(
                occasion: preferences?.occasion,
                mood: preferences?.styleGoal,
                boldnessLevel: preferences?.boldnessLevel ?? 3
            )

            todaysOutfits = result.outfits
            cacheTimestamp = Date()

            HapticManager.shared.success()

        } catch {
            self.error = error
            print("Generate outfits error: \(error)")
        }
    }

    // MARK: - Save Outfit

    func saveOutfit(_ outfit: ScoredOutfit) async throws {
        guard SupabaseManager.shared.currentUserId != nil else { return }

        try await api.saveOutfit(outfit: outfit)

        HapticManager.shared.likeOutfit()
    }

    // MARK: - Mark Outfit as Worn

    func markAsWorn(_ outfit: ScoredOutfit, photoUrl: String? = nil) async throws {
        guard SupabaseManager.shared.currentUserId != nil else { return }

        // Call API - handles logging, streak update, achievements
        let response = try await api.wearOutfit(id: outfit.id, photoUrl: photoUrl)

        // Update times_worn for each item locally
        for itemId in outfit.wardrobeItemIds {
            try? await wardrobeService.markAsWorn(id: itemId)
        }

        HapticManager.shared.success()

        // Handle streak update notification if needed
        if let streakUpdate = response.streakUpdate, streakUpdate.streakIncreased {
            HapticManager.shared.streakMilestone()
        }

        // Handle new achievements if any
        if let newAchievements = response.newAchievements, !newAchievements.isEmpty {
            // Post notification for achievement celebration
            NotificationCenter.default.post(
                name: .newAchievementsUnlocked,
                object: nil,
                userInfo: ["achievements": newAchievements]
            )
        }
    }

    // MARK: - Get Outfit History

    func getOutfitHistory() async throws -> [OutfitHistory] {
        try await api.getOutfitHistory()
    }

    // MARK: - Generate Outfits in Background

    func generateOutfitsInBackground(completion: @escaping () -> Void) {
        Task {
            await generateOutfits()
            await MainActor.run {
                completion()
            }
        }
    }

    // MARK: - Regenerate with Feedback

    func regenerateWithFeedback(currentOutfit: ScoredOutfit, feedback: FeedbackType) async -> ScoredOutfit? {
        guard SupabaseManager.shared.currentUserId != nil else { return nil }

        isGenerating = true
        defer { isGenerating = false }

        do {
            let result = try await api.regenerateOutfit(
                currentIds: currentOutfit.wardrobeItemIds,
                feedback: feedback.rawValue,
                occasion: currentOutfit.occasion
            )

            if let outfit = result.outfit {
                HapticManager.shared.success()
                return outfit
            }

            return nil
        } catch {
            self.error = error
            print("Regenerate outfit error: \(error)")
            HapticManager.shared.error()
            return nil
        }
    }

    // MARK: - Clear Cache

    func clearCache() {
        todaysOutfits = []
        cacheTimestamp = nil
    }
}

// MARK: - Outfit Errors

enum OutfitError: LocalizedError {
    case notEnoughItems
    case generationFailed

    var errorDescription: String? {
        switch self {
        case .notEnoughItems: return "Add at least 1 top, 1 bottom, and 1 pair of shoes"
        case .generationFailed: return "Failed to generate outfits"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let newAchievementsUnlocked = Notification.Name("newAchievementsUnlocked")
}
