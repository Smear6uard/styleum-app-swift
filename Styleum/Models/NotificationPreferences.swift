import Foundation

struct NotificationPreferences: Codable, Equatable {
    var pushEnabled: Bool
    var morningNotificationTime: String  // TIME format: "09:00:00"
    var timezone: String  // IANA format: "America/Los_Angeles"

    enum CodingKeys: String, CodingKey {
        case pushEnabled = "push_enabled"
        case morningNotificationTime = "morning_notification_time"
        case timezone
    }

    // MARK: - Computed Properties

    /// Extracts the hour component from the time string (e.g., "09:00:00" -> 9)
    var deliveryHour: Int {
        let components = morningNotificationTime.split(separator: ":")
        guard let hourString = components.first,
              let hour = Int(hourString) else {
            return 9  // Default to 9 AM
        }
        return hour
    }

    // MARK: - Helpers

    /// Creates a time string from an hour (e.g., 9 -> "09:00:00")
    static func timeString(from hour: Int) -> String {
        String(format: "%02d:00:00", hour)
    }

    /// Creates default preferences with current timezone
    static var `default`: NotificationPreferences {
        NotificationPreferences(
            pushEnabled: true,
            morningNotificationTime: "09:00:00",
            timezone: TimeZone.current.identifier
        )
    }
}
