import Foundation

struct Profile: Codable, Identifiable, Equatable {
    let id: String
    let firstName: String?
    let email: String?
    var departments: [String]?
    var referralSource: String?
    var onboardingCompleted: Bool?
    var onboardingVersion: Int?
    var styleQuizCompleted: Bool?
    let createdAt: Date?
    var updatedAt: Date?
    var isPro: Bool?

    // Notification preferences
    var pushEnabled: Bool?
    var morningNotificationTime: String?
    var timezone: String?
    var temperatureUnit: String?

    var displayName: String {
        firstName ?? "there"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case email
        case departments
        case referralSource = "referral_source"
        case onboardingCompleted = "onboarding_completed"
        case onboardingVersion = "onboarding_version"
        case styleQuizCompleted = "style_quiz_completed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isPro = "is_pro"
        case pushEnabled = "push_enabled"
        case morningNotificationTime = "morning_notification_time"
        case timezone
        case temperatureUnit = "temperature_unit"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        departments = try container.decodeIfPresent([String].self, forKey: .departments)
        referralSource = try container.decodeIfPresent(String.self, forKey: .referralSource)
        onboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .onboardingCompleted)
        onboardingVersion = try container.decodeIfPresent(Int.self, forKey: .onboardingVersion)
        styleQuizCompleted = try container.decodeIfPresent(Bool.self, forKey: .styleQuizCompleted)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        isPro = try container.decodeIfPresent(Bool.self, forKey: .isPro)
        pushEnabled = try container.decodeIfPresent(Bool.self, forKey: .pushEnabled)
        morningNotificationTime = try container.decodeIfPresent(String.self, forKey: .morningNotificationTime)
        timezone = try container.decodeIfPresent(String.self, forKey: .timezone)
        temperatureUnit = try container.decodeIfPresent(String.self, forKey: .temperatureUnit)
    }
}
