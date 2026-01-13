import Foundation

/// Collected data during onboarding flow
struct OnboardingUserData {
    var firstName: String = ""
    var department: String = ""  // "womenswear" or "menswear" (single-select)
    var heightCategory: String? = nil  // "short", "average", "tall"
    var skinUndertone: String? = nil   // "warm", "cool", "neutral"
    var likedStyleIds: [String] = []
    var dislikedStyleIds: [String] = []
    var referralSource: String? = nil
    var notificationHour: Int? = nil  // nil = skipped, will default to 9 AM

    /// Check if minimum required data is collected
    var isComplete: Bool {
        !firstName.isEmpty && !department.isEmpty
    }
}
