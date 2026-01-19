import Foundation

@MainActor
@Observable
final class ProfileService {
    static let shared = ProfileService()

    private let api = StyleumAPI.shared

    var currentProfile: Profile?
    var isLoading = false
    var error: Error?
    var hasFetchedOnce = false  // Track if we've attempted a fetch (prevents infinite loops)

    private init() {
        print("👤 [PROFILE] ProfileService initialized")
    }

    // MARK: - Reset (call on sign-out)

    func reset() {
        print("👤 [PROFILE] ========== RESET ==========")
        currentProfile = nil
        hasFetchedOnce = false
        error = nil
        isLoading = false
    }

    // MARK: - Fetch Profile

    func fetchProfile() async {
        print("👤 [PROFILE] ========== FETCH PROFILE START ==========")
        print("👤 [PROFILE] Timestamp: \(Date())")
        print("👤 [PROFILE] Current profile before fetch: \(currentProfile?.id ?? "nil")")
        print("👤 [PROFILE] isLoading: \(isLoading), hasFetchedOnce: \(hasFetchedOnce)")

        // Guard against multiple simultaneous fetches
        guard !isLoading else {
            print("👤 [PROFILE] ⚠️ Already loading - skipping duplicate fetch")
            return
        }

        let userId = SupabaseManager.shared.currentUserId
        print("👤 [PROFILE] Checking currentUserId: \(userId ?? "nil")")

        guard userId != nil else {
            print("👤 [PROFILE] ⚠️ No currentUserId - aborting fetch")
            hasFetchedOnce = true  // Mark as attempted even if no user
            print("👤 [PROFILE] ========== FETCH PROFILE END (NO USER) ==========")
            return
        }

        print("👤 [PROFILE] ✅ User ID exists, proceeding with API call")
        isLoading = true
        print("👤 [PROFILE] Set isLoading=true")

        defer {
            isLoading = false
            hasFetchedOnce = true
            print("👤 [PROFILE] Set isLoading=false, hasFetchedOnce=true (defer)")
        }

        do {
            print("👤 [PROFILE] Calling api.getProfile()...")
            currentProfile = try await api.getProfile()
            print("👤 [PROFILE] ✅ Profile fetched successfully")
            print("👤 [PROFILE] Profile ID: \(currentProfile?.id ?? "nil")")
            print("👤 [PROFILE] Profile firstName: \(currentProfile?.firstName ?? "nil")")
            print("👤 [PROFILE] Profile email: \(currentProfile?.email ?? "nil")")
            print("👤 [PROFILE] Profile onboardingVersion: \(currentProfile?.onboardingVersion.map { String($0) } ?? "nil")")
            print("👤 [PROFILE] Profile styleQuizCompleted: \(currentProfile?.styleQuizCompleted.map { String($0) } ?? "nil")")
            print("👤 [PROFILE] Profile departments: \(currentProfile?.departments ?? [])")

            // Sync temperature unit preference from backend to UserDefaults
            if let unit = currentProfile?.temperatureUnit {
                UserDefaults.standard.set(unit, forKey: "temperatureUnit")
                print("👤 [PROFILE] Synced temperatureUnit from backend: \(unit)")
            }
        } catch {
            self.error = error
            print("👤 [PROFILE] ❌ Fetch profile error occurred")
            print("👤 [PROFILE] Error type: \(type(of: error))")
            print("👤 [PROFILE] Error description: \(error.localizedDescription)")
            print("👤 [PROFILE] Full error: \(error)")
        }
        print("👤 [PROFILE] ========== FETCH PROFILE END ==========")
    }

    // MARK: - Update Profile

    func updateProfile(_ updates: ProfileUpdate) async throws {
        print("👤 [PROFILE] ========== UPDATE PROFILE START ==========")
        print("👤 [PROFILE] Timestamp: \(Date())")
        print("👤 [PROFILE] Updates: \(updates)")

        let userId = SupabaseManager.shared.currentUserId
        print("👤 [PROFILE] Checking currentUserId: \(userId ?? "nil")")

        guard userId != nil else {
            print("👤 [PROFILE] ⚠️ No currentUserId - aborting update")
            print("👤 [PROFILE] ========== UPDATE PROFILE END (NO USER) ==========")
            return
        }

        print("👤 [PROFILE] ✅ User ID exists, proceeding with API call")
        isLoading = true
        print("👤 [PROFILE] Set isLoading=true")

        defer {
            isLoading = false
            print("👤 [PROFILE] Set isLoading=false (defer)")
        }

        print("👤 [PROFILE] Calling api.updateProfile()...")
        currentProfile = try await api.updateProfile(updates)
        print("👤 [PROFILE] ✅ Profile updated successfully")
        print("👤 [PROFILE] Updated profile ID: \(currentProfile?.id ?? "nil")")
        print("👤 [PROFILE] Updated onboardingVersion: \(currentProfile?.onboardingVersion.map { String($0) } ?? "nil")")

        HapticManager.shared.success()
        print("👤 [PROFILE] ========== UPDATE PROFILE END ==========")
    }
}

// MARK: - Profile Update Model

struct ProfileUpdate: Encodable {
    var username: String?
    var profilePhotoUrl: String?
    var bodyType: String?
    var heightCategory: String?
    var budgetRange: String?
    var skinUndertone: String?
    var aestheticPreference: String?
    var fitPreference: String?
    var styleArchetypes: [String]?
    var brandPreferences: [String]?
    var onboardingVersion: Int?
    var temperatureUnit: String?

    enum CodingKeys: String, CodingKey {
        case username
        case profilePhotoUrl = "profile_photo_url"
        case bodyType = "body_type"
        case heightCategory = "height_category"
        case budgetRange = "budget_range"
        case skinUndertone = "skin_undertone"
        case aestheticPreference = "aesthetic_preference"
        case fitPreference = "fit_preference"
        case styleArchetypes = "style_archetypes"
        case brandPreferences = "brand_preferences"
        case onboardingVersion = "onboarding_version"
        case temperatureUnit = "temperature_unit"
    }
}
