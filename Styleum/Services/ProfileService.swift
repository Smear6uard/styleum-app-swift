import Foundation

@Observable
final class ProfileService {
    static let shared = ProfileService()

    private let api = StyleumAPI.shared

    var currentProfile: Profile?
    var isLoading = false
    var error: Error?

    private init() {}

    // MARK: - Fetch Profile

    func fetchProfile() async {
        guard SupabaseManager.shared.currentUserId != nil else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            currentProfile = try await api.getProfile()
        } catch {
            self.error = error
            print("Fetch profile error: \(error)")
        }
    }

    // MARK: - Update Profile

    func updateProfile(_ updates: ProfileUpdate) async throws {
        guard SupabaseManager.shared.currentUserId != nil else { return }

        isLoading = true
        defer { isLoading = false }

        currentProfile = try await api.updateProfile(updates)

        HapticManager.shared.success()
    }
}

// MARK: - Profile Update Model

struct ProfileUpdate: Encodable {
    var username: String?
    var profilePhotoUrl: String?
    var bodyType: String?
    var heightCm: Int?
    var budgetRange: String?
    var skinTone: String?
    var aestheticPreference: String?
    var fitPreference: String?
    var styleArchetypes: [String]?
    var brandPreferences: [String]?
    var onboardingVersion: Int?

    enum CodingKeys: String, CodingKey {
        case username
        case profilePhotoUrl = "profile_photo_url"
        case bodyType = "body_type"
        case heightCm = "height_cm"
        case budgetRange = "budget_range"
        case skinTone = "skin_tone"
        case aestheticPreference = "aesthetic_preference"
        case fitPreference = "fit_preference"
        case styleArchetypes = "style_archetypes"
        case brandPreferences = "brand_preferences"
        case onboardingVersion = "onboarding_version"
    }
}
