import Foundation

struct Profile: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
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
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: String?
    var totalDaysActive: Int
    var onboardingVersion: Int?
    let createdAt: Date?
    var updatedAt: Date?

    var displayName: String {
        username ?? "there"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
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
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastActiveDate = "last_active_date"
        case totalDaysActive = "total_days_active"
        case onboardingVersion = "onboarding_version"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        profilePhotoUrl = try container.decodeIfPresent(String.self, forKey: .profilePhotoUrl)
        bodyType = try container.decodeIfPresent(String.self, forKey: .bodyType)
        heightCm = try container.decodeIfPresent(Int.self, forKey: .heightCm)
        budgetRange = try container.decodeIfPresent(String.self, forKey: .budgetRange)
        skinTone = try container.decodeIfPresent(String.self, forKey: .skinTone)
        aestheticPreference = try container.decodeIfPresent(String.self, forKey: .aestheticPreference)
        fitPreference = try container.decodeIfPresent(String.self, forKey: .fitPreference)
        styleArchetypes = try container.decodeIfPresent([String].self, forKey: .styleArchetypes)
        brandPreferences = try container.decodeIfPresent([String].self, forKey: .brandPreferences)
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        longestStreak = try container.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 0
        lastActiveDate = try container.decodeIfPresent(String.self, forKey: .lastActiveDate)
        totalDaysActive = try container.decodeIfPresent(Int.self, forKey: .totalDaysActive) ?? 0
        onboardingVersion = try container.decodeIfPresent(Int.self, forKey: .onboardingVersion)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}
