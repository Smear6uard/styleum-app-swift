import Foundation
import CoreLocation

@MainActor
@Observable
final class OutfitRepository {
    static let shared = OutfitRepository()

    private let api = StyleumAPI.shared
    private let wardrobeService = WardrobeService.shared
    private let locationService = LocationService.shared

    // Track first outfit milestone (namespaced key to avoid collisions)
    private static let firstOutfitKey = "com.sameerstudios.Styleum.hasGeneratedFirstOutfit"

    @ObservationIgnored
    private var hasGeneratedFirstOutfit: Bool {
        get { UserDefaults.standard.bool(forKey: Self.firstOutfitKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.firstOutfitKey) }
    }

    // MARK: - Pre-Generated Outfits (Free, shown on Home)

    var preGeneratedOutfits: [ScoredOutfit] = []
    var preGeneratedWeather: WeatherContext?
    private var preGenCacheTimestamp: Date?

    // MARK: - Session Outfits (Fresh generation, uses credits)

    var sessionOutfits: [ScoredOutfit] = []
    var sessionWeather: WeatherContext?

    // MARK: - Legacy Support (backward compatibility)

    /// Returns session outfits if available, otherwise pre-generated
    var todaysOutfits: [ScoredOutfit] {
        sessionOutfits.isEmpty ? preGeneratedOutfits : sessionOutfits
    }

    /// Returns session weather if available, otherwise pre-generated
    var currentWeather: WeatherContext? {
        sessionOutfits.isEmpty ? preGeneratedWeather : sessionWeather
    }

    // MARK: - State

    var isLoading = false
    var isGenerating = false
    var error: Error?
    var outfitSource: String = "none"  // "pre_generated", "fresh", "none"

    private init() {}

    // MARK: - Pre-Generated Outfits (FREE)

    /// Load pre-generated outfits on app launch (free, no credits used)
    func loadPreGeneratedIfAvailable() async {
        guard SupabaseManager.shared.currentUserId != nil else { return }

        // Skip if we already loaded today
        if !preGeneratedOutfits.isEmpty,
           let timestamp = preGenCacheTimestamp,
           Calendar.current.isDateInToday(timestamp) {
            print("🌤️ [OutfitRepo] Already have today's pre-generated, skipping")
            return
        }

        print("🌤️ [OutfitRepo] Loading pre-generated outfits (FREE)...")

        do {
            if let preGen = try await api.getPreGeneratedOutfits(), !preGen.outfits.isEmpty {
                print("🌤️ [OutfitRepo] ✅ API returned \(preGen.outfits.count) outfits")
                print("🌤️ [OutfitRepo] Source: \(preGen.source ?? "unknown")")
                if let first = preGen.outfits.first {
                    print("🌤️ [OutfitRepo] First outfit headline: \(first.headline ?? "none")")
                    print("🌤️ [OutfitRepo] First outfit has \(first.wardrobeItemIds.count) items")
                }
                preGeneratedOutfits = preGen.outfits
                preGeneratedWeather = preGen.weather
                preGenCacheTimestamp = Date()
                outfitSource = "pre_generated"
                error = nil  // Clear any previous error
                print("🌤️ [OutfitRepo] ✅ Stored \(preGeneratedOutfits.count) pre-generated outfits")
            } else {
                print("🌤️ [OutfitRepo] No pre-generated outfits available")
            }
        } catch {
            print("🌤️ [OutfitRepo] ❌ Failed to load pre-generated outfits: \(error)")
            self.error = error  // Set error so UI can show it
        }
    }

    /// Check if pre-generated outfits are ready to show
    var hasPreGeneratedReady: Bool {
        !preGeneratedOutfits.isEmpty && Calendar.current.isDateInToday(preGenCacheTimestamp ?? .distantPast)
    }

    /// View pre-generated outfits (called from Home screen - FREE)
    func viewPreGeneratedOutfits() {
        print("🌤️ [OutfitRepo] Viewing pre-generated outfits (FREE)")
        // Clear session so todaysOutfits returns preGeneratedOutfits
        sessionOutfits = []
        sessionWeather = nil
        outfitSource = "pre_generated"
    }

    // MARK: - Fresh Generation (Uses Credits)

    /// Generate fresh outfits - ALWAYS hits the API, uses credits
    func generateFreshOutfits(preferences: StylePreferences? = nil) async {
        print("🌤️ [OutfitRepo] Generating FRESH outfits (uses credit)...")

        // Clear any previous error before starting new generation
        error = nil

        guard SupabaseManager.shared.currentUserId != nil else {
            print("🌤️ [OutfitRepo] No user ID, aborting")
            return
        }

        guard wardrobeService.hasEnoughForOutfits else {
            print("🌤️ [OutfitRepo] Not enough items for outfits")
            error = OutfitError.notEnoughItems
            return
        }

        isGenerating = true
        defer { isGenerating = false }

        do {
            let location = await locationService.getCurrentLocation()
            print("🌤️ [OutfitRepo] Location: lat=\(location?.latitude ?? 0), lng=\(location?.longitude ?? 0)")

            let result = try await api.generateOutfits(
                occasion: preferences?.occasion,
                mood: preferences?.styleGoal,
                boldnessLevel: preferences?.boldnessLevel ?? 3,
                latitude: location?.latitude,
                longitude: location?.longitude
            )

            print("🌤️ [OutfitRepo] ✅ Generated \(result.outfits.count) fresh outfits")
            if let weather = result.weather {
                print("🌤️ [OutfitRepo] Weather: \(Int(weather.tempFahrenheit))°F, \(weather.condition)")
            }

            sessionOutfits = result.outfits
            sessionWeather = result.weather
            outfitSource = "fresh"

            if let first = sessionOutfits.first {
                print("🌤️ [OutfitRepo] First outfit: \(first.headline ?? "no headline"), \(first.wardrobeItemIds.count) items")
            }

            HapticManager.shared.success()

            // Award gamification XP and update challenge progress (+1 XP per outfit generated)
            let xpForGeneration = result.outfits.count
            GamificationService.shared.awardXP(xpForGeneration, reason: .outfitGenerated)
            GamificationService.shared.updateChallengeProgress(for: .generateOutfit)

            // First outfit celebration
            if !hasGeneratedFirstOutfit && !result.outfits.isEmpty {
                hasGeneratedFirstOutfit = true
                NotificationCenter.default.post(name: .firstOutfitGenerated, object: nil)
            }

            // Save location for future pre-generation
            if let loc = location {
                Task {
                    await api.saveLocationForPreGeneration(latitude: loc.latitude, longitude: loc.longitude)
                }
            }

        } catch {
            print("🌤️ [OutfitRepo] ❌ Generate error: \(error)")
            self.error = error
        }
    }

    // MARK: - Legacy Methods

    /// Legacy method - now always generates fresh (for backward compatibility)
    func generateOutfits(preferences: StylePreferences? = nil) async {
        await generateFreshOutfits(preferences: preferences)
    }

    /// Legacy method - generates in background
    func generateOutfitsInBackground(completion: @escaping () -> Void) {
        Task {
            await generateFreshOutfits()
            await MainActor.run {
                completion()
            }
        }
    }

    /// Legacy check - returns true if any outfits ready
    var hasOutfitsReady: Bool {
        !todaysOutfits.isEmpty
    }

    // MARK: - Get Today's Outfits (for Home screen)

    func getTodaysOutfits(forceRefresh: Bool = false) async {
        guard SupabaseManager.shared.currentUserId != nil else { return }

        isLoading = true
        defer { isLoading = false }

        // Load pre-generated for home screen
        await loadPreGeneratedIfAvailable()
    }

    // MARK: - Save Outfit

    func saveOutfit(_ outfit: ScoredOutfit) async throws {
        guard SupabaseManager.shared.currentUserId != nil else { return }

        try await api.saveOutfit(outfit: outfit)

        HapticManager.shared.likeOutfit()

        // Award gamification XP and update challenge progress
        GamificationService.shared.awardXP(3, reason: .outfitSaved)
        GamificationService.shared.updateChallengeProgress(for: .saveOutfit)
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

        // Award gamification XP and update challenge progress
        // Base: 10 XP for wearing, +15 XP bonus if verified with photo
        let baseXP = 10
        let verifyBonus = photoUrl != nil ? 15 : 0
        GamificationService.shared.awardXP(baseXP, reason: .outfitWorn)
        if verifyBonus > 0 {
            GamificationService.shared.awardXP(verifyBonus, reason: .verifiedWear, showToast: false)
        }
        GamificationService.shared.updateChallengeProgress(for: .wearOutfit)

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

    // MARK: - Clear

    func clearSessionOutfits() {
        sessionOutfits = []
        sessionWeather = nil
    }

    func clearCache() {
        preGeneratedOutfits = []
        preGeneratedWeather = nil
        preGenCacheTimestamp = nil
        sessionOutfits = []
        sessionWeather = nil
    }
}

// MARK: - Outfit Errors

enum OutfitError: LocalizedError {
    case notEnoughItems
    case generationFailed

    var errorDescription: String? {
        switch self {
        case .notEnoughItems:
            return "Add at least 1 top, 1 bottom, and 1 pair of shoes to get outfit suggestions."
        case .generationFailed:
            return "Couldn't create outfits right now. Try again in a moment."
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let newAchievementsUnlocked = Notification.Name("newAchievementsUnlocked")
}
