import Foundation
import CoreLocation
import Sentry

@MainActor
@Observable
final class OutfitRepository {
    static let shared = OutfitRepository()

    private let api = StyleumAPI.shared
    private let wardrobeService = WardrobeService.shared
    private let locationService = LocationService.shared

    // Track first outfit milestone (namespaced key to avoid collisions)
    private static let firstOutfitKey = "com.sameerstudios.Styleum.hasGeneratedFirstOutfit"
    private static let firstAutoOutfitSeenKey = "com.sameerstudios.Styleum.hasSeenFirstAutoOutfit"

    @ObservationIgnored
    private var hasGeneratedFirstOutfit: Bool {
        get { UserDefaults.standard.bool(forKey: Self.firstOutfitKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.firstOutfitKey) }
    }

    @ObservationIgnored
    private var hasSeenFirstAutoOutfit: Bool {
        get { UserDefaults.standard.bool(forKey: Self.firstAutoOutfitSeenKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.firstAutoOutfitSeenKey) }
    }

    // MARK: - Pre-Generated Outfits (Free, shown on Home)

    var preGeneratedOutfits: [ScoredOutfit] = []
    var preGeneratedWeather: WeatherContext?
    private var preGenCacheTimestamp: Date?

    // Fallback state (when no pre-generated outfits)
    var isFallback = false
    var fallbackMessage: String?
    var inspirationItems: [InspirationItem] = []
    var canGenerate = true

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
            if let preGen = try await api.getPreGeneratedOutfits() {
                // Check if this is a fallback response
                if preGen.fallback == true {
                    print("🌤️ [OutfitRepo] 📋 Got fallback response")
                    isFallback = true
                    fallbackMessage = preGen.fallbackMessage
                    inspirationItems = preGen.inspirationItems ?? []
                    canGenerate = preGen.canGenerate ?? true
                    preGenCacheTimestamp = Date()
                    outfitSource = "none"
                    error = nil
                    print("🌤️ [OutfitRepo] Fallback message: \(fallbackMessage ?? "none")")
                    print("🌤️ [OutfitRepo] Inspiration items: \(inspirationItems.count)")
                    print("🌤️ [OutfitRepo] Can generate: \(canGenerate)")
                } else if !preGen.outfits.isEmpty {
                    print("🌤️ [OutfitRepo] ✅ API returned \(preGen.outfits.count) outfits")
                    print("🌤️ [OutfitRepo] Source: \(preGen.source ?? "unknown")")
                    if let first = preGen.outfits.first {
                        print("🌤️ [OutfitRepo] First outfit headline: \(first.headline ?? "none")")
                        print("🌤️ [OutfitRepo] First outfit has \(first.wardrobeItemIds.count) items")
                    }
                    // Clear any previous fallback state
                    isFallback = false
                    fallbackMessage = nil
                    inspirationItems = []
                    canGenerate = true

                    preGeneratedOutfits = preGen.outfits
                    preGeneratedWeather = preGen.weather
                    preGenCacheTimestamp = Date()
                    outfitSource = "pre_generated"
                    error = nil  // Clear any previous error
                    print("🌤️ [OutfitRepo] ✅ Stored \(preGeneratedOutfits.count) pre-generated outfits")

                    // Track outfit generated event (pre-generated)
                    AnalyticsService.track(AnalyticsEvent.outfitGenerated, properties: [
                        "count": preGen.outfits.count,
                        "source": "pre_generated"
                    ])

                    // Check for first auto-generated outfit celebration
                    if preGen.source == "first_outfit_auto" && !hasSeenFirstAutoOutfit {
                        print("🌤️ [OutfitRepo] 🎉 First auto-generated outfit detected!")
                        hasSeenFirstAutoOutfit = true
                        // Post notification after slight delay to ensure splash is done
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            NotificationCenter.default.post(name: .firstAutoOutfitReady, object: nil)
                        }
                    }
                } else {
                    print("🌤️ [OutfitRepo] No pre-generated outfits available")
                }
            } else {
                print("🌤️ [OutfitRepo] No pre-generated outfits available")
            }
        } catch {
            print("🌤️ [OutfitRepo] ❌ Failed to load pre-generated outfits: \(error)")
            // Don't set error - pre-gen failures shouldn't affect StyleMe screen
            // User can still tap "Style Me" to generate fresh outfits
        }
    }

    /// Check if pre-generated outfits are ready to show
    var hasPreGeneratedReady: Bool {
        !preGeneratedOutfits.isEmpty && Calendar.current.isDateInToday(preGenCacheTimestamp ?? .distantPast)
    }

    /// Check if fallback state is ready to show
    var hasFallbackReady: Bool {
        isFallback && !inspirationItems.isEmpty
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

        // Sentry breadcrumb: outfit generation started
        let startCrumb = Breadcrumb(level: .info, category: "outfit.generation")
        startCrumb.message = "Started outfit generation"
        if let prefs = preferences {
            startCrumb.data = [
                "hasOccasion": prefs.occasion != nil,
                "boldnessLevel": prefs.boldnessLevel ?? 3
            ]
        }
        SentrySDK.addBreadcrumb(startCrumb)

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

            // Sentry breadcrumb: outfit generation completed
            let completeCrumb = Breadcrumb(level: .info, category: "outfit.generation")
            completeCrumb.message = "Outfit generation completed"
            completeCrumb.data = ["outfitCount": result.outfits.count]
            SentrySDK.addBreadcrumb(completeCrumb)

            if let first = sessionOutfits.first {
                print("🌤️ [OutfitRepo] First outfit: \(first.headline ?? "no headline"), \(first.wardrobeItemIds.count) items")
            }

            HapticManager.shared.success()

            // Track outfit generated event
            AnalyticsService.track(AnalyticsEvent.outfitGenerated, properties: [
                "count": result.outfits.count,
                "source": "fresh"
            ])

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

        } catch is CancellationError {
            // Swift Task was cancelled (e.g., view lifecycle)
            print("🌤️ [OutfitRepo] ❌ Task cancelled by SwiftUI lifecycle")
            self.error = OutfitError.generationFailed
        } catch {
            // Detailed error logging
            let errorType = type(of: error)
            print("🌤️ [OutfitRepo] ❌ Generate error type: \(errorType)")
            print("🌤️ [OutfitRepo] ❌ Generate error: \(error)")

            if let urlError = error as? URLError {
                print("🌤️ [OutfitRepo] URLError code: \(urlError.code.rawValue), description: \(urlError.localizedDescription)")

                // Convert cancelled/timeout errors to user-friendly message
                if urlError.code == .cancelled || urlError.code == .timedOut {
                    self.error = OutfitError.generationFailed
                    return
                }
            }

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

        // Track outfit worn event
        AnalyticsService.track(AnalyticsEvent.outfitWorn)

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

            // Track streak incremented event
            AnalyticsService.track(AnalyticsEvent.streakIncremented, properties: [
                "streak_count": streakUpdate.currentStreak
            ])
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
    static let firstAutoOutfitReady = Notification.Name("firstAutoOutfitReady")
}
