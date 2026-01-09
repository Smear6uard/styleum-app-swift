import Foundation

/// Converts any error into a user-friendly message suitable for display.
/// Provides consistent, helpful error messages across the app.
enum UserFriendlyError {

    /// Converts any error to a user-friendly message
    static func message(for error: Error) -> String {
        // Check if error already has a friendly description
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }

        // Parse common error patterns from the description
        let description = error.localizedDescription.lowercased()

        // Network errors
        if description.contains("network") ||
           description.contains("connection") ||
           description.contains("offline") ||
           description.contains("internet") ||
           description.contains("timed out") ||
           description.contains("could not connect") {
            return "Can't connect right now. Check your internet and try again."
        }

        // Auth errors
        if description.contains("unauthorized") ||
           description.contains("authentication") ||
           description.contains("not authenticated") ||
           description.contains("sign in") ||
           description.contains("login") {
            return "Please sign in to continue."
        }

        if description.contains("session expired") ||
           description.contains("token expired") {
            return "Your session has expired. Please sign in again."
        }

        // Rate limiting
        if description.contains("rate limit") ||
           description.contains("too many") ||
           description.contains("try again later") {
            return "You're doing that too fast. Take a breather and try again."
        }

        // Permission errors
        if description.contains("permission") ||
           description.contains("denied") ||
           description.contains("forbidden") ||
           description.contains("not allowed") {
            return "You don't have permission to do that."
        }

        // Not found
        if description.contains("not found") ||
           description.contains("does not exist") ||
           description.contains("couldn't find") {
            return "We couldn't find what you're looking for."
        }

        // Server errors
        if description.contains("server") ||
           description.contains("500") ||
           description.contains("503") ||
           description.contains("502") {
            return "Our servers are having a moment. Please try again shortly."
        }

        // Image/file errors
        if description.contains("image") ||
           description.contains("photo") ||
           description.contains("file") {
            if description.contains("too large") || description.contains("size") {
                return "That image is too large. Try a smaller one."
            }
            if description.contains("format") || description.contains("type") {
                return "We can't use that image format. Try a JPG or PNG."
            }
            return "There was a problem with the image. Please try another."
        }

        // Validation errors
        if description.contains("invalid") {
            if description.contains("email") {
                return "Please enter a valid email address."
            }
            if description.contains("code") || description.contains("otp") {
                return "That code doesn't look right. Double-check and try again."
            }
            return "Something doesn't look right. Please check your input."
        }

        // Decoding errors
        if description.contains("decoding") ||
           description.contains("parsing") ||
           description.contains("json") {
            return "We received unexpected data. Please try again."
        }

        // Default fallback
        return "Something went wrong. Please try again."
    }

    /// Returns a title appropriate for the error type
    static func title(for error: Error) -> String {
        let description = error.localizedDescription.lowercased()

        if description.contains("network") ||
           description.contains("connection") ||
           description.contains("internet") {
            return "No Connection"
        }

        if description.contains("unauthorized") ||
           description.contains("sign in") ||
           description.contains("session") {
            return "Sign In Required"
        }

        if description.contains("permission") ||
           description.contains("denied") {
            return "Access Denied"
        }

        if description.contains("rate limit") ||
           description.contains("too many") {
            return "Slow Down"
        }

        if description.contains("server") {
            return "Server Issue"
        }

        return "Oops"
    }

    /// Returns an appropriate SF Symbol for the error type
    static func icon(for error: Error) -> String {
        let description = error.localizedDescription.lowercased()

        if description.contains("network") ||
           description.contains("connection") ||
           description.contains("internet") {
            return "wifi.slash"
        }

        if description.contains("unauthorized") ||
           description.contains("sign in") ||
           description.contains("session") {
            return "person.crop.circle.badge.exclamationmark"
        }

        if description.contains("permission") ||
           description.contains("denied") {
            return "lock.fill"
        }

        if description.contains("rate limit") ||
           description.contains("too many") {
            return "hourglass"
        }

        if description.contains("server") {
            return "server.rack"
        }

        if description.contains("not found") {
            return "magnifyingglass"
        }

        return "exclamationmark.triangle.fill"
    }

    /// Suggests a recovery action for the error
    static func recoveryAction(for error: Error) -> RecoveryAction? {
        let description = error.localizedDescription.lowercased()

        if description.contains("network") ||
           description.contains("connection") ||
           description.contains("internet") {
            return .retry
        }

        if description.contains("unauthorized") ||
           description.contains("sign in") ||
           description.contains("session expired") {
            return .signIn
        }

        if description.contains("rate limit") ||
           description.contains("too many") {
            return .wait
        }

        if description.contains("server") {
            return .retry
        }

        return .retry
    }

    enum RecoveryAction {
        case retry
        case signIn
        case wait
        case dismiss

        var buttonTitle: String {
            switch self {
            case .retry: return "Try Again"
            case .signIn: return "Sign In"
            case .wait: return "Got It"
            case .dismiss: return "OK"
            }
        }
    }
}

// MARK: - Error Extension

extension Error {
    /// Returns a user-friendly message for this error
    var userFriendlyMessage: String {
        UserFriendlyError.message(for: self)
    }

    /// Returns a user-friendly title for this error
    var userFriendlyTitle: String {
        UserFriendlyError.title(for: self)
    }

    /// Returns an appropriate icon for this error
    var errorIcon: String {
        UserFriendlyError.icon(for: self)
    }
}
