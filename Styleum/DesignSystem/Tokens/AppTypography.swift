import SwiftUI

enum AppTypography {

    // MARK: - Clash Display (Editorial Headlines)

    /// Editorial display font for hero headlines
    /// Use for primary screen headers, greeting text, feature headlines
    static func editorial(_ size: CGFloat, weight: ClashWeight = .semibold) -> Font {
        .custom(weight.fontName, size: size)
    }

    /// Alias for editorial() - backwards compatibility
    static func clashDisplay(_ size: CGFloat, weight: ClashWeight = .semibold) -> Font {
        editorial(size, weight: weight)
    }

    /// Editorial italic for emphasis within headlines (e.g., "Define Your *Style*")
    static func editorialItalic(_ size: CGFloat, weight: ClashWeight = .medium) -> Font {
        // Clash Display doesn't have italics, so we use the font and apply italic modifier
        .custom(weight.fontName, size: size).italic()
    }

    /// Alias for editorialItalic() - backwards compatibility
    static func clashDisplayItalic(_ size: CGFloat, weight: ClashWeight = .medium) -> Font {
        editorialItalic(size, weight: weight)
    }

    /// Clash Display weight options
    enum ClashWeight {
        case extralight
        case light
        case regular
        case medium
        case semibold
        case bold

        var fontName: String {
            switch self {
            case .extralight: return "ClashDisplay-Extralight"
            case .light: return "ClashDisplay-Light"
            case .regular: return "ClashDisplay-Regular"
            case .medium: return "ClashDisplay-Medium"
            case .semibold: return "ClashDisplay-Semibold"
            case .bold: return "ClashDisplay-Bold"
            }
        }
    }

    // MARK: - Letter Spacing (Tracking) Presets

    /// Loose tracking for uppercase kickers and labels
    static let trackingLoose: CGFloat = 2.0

    /// Normal tracking for body text
    static let trackingNormal: CGFloat = 0.3

    /// Tight tracking for large display text
    static let trackingTight: CGFloat = -0.5

    // MARK: - Editorial Display Presets

    /// Hero greeting (32pt light) - "Good morning, Sarah"
    static let editorialHero = editorial(32, weight: .light)

    /// Primary headline (28pt semibold) - Screen titles
    static let editorialHeadline = editorial(28, weight: .semibold)

    /// Secondary headline (24pt medium) - Section headers
    static let editorialSubhead = editorial(24, weight: .medium)

    /// Tertiary headline (20pt medium) - Card titles
    static let editorialTitle = editorial(20, weight: .medium)

    // MARK: - System Fonts (Body & UI)

    static let displayLarge = Font.system(size: 32, weight: .bold)
    static let displayMedium = Font.system(size: 28, weight: .bold)
    static let displaySmall = Font.system(size: 24, weight: .bold)
    static let headingLarge = Font.system(size: 24, weight: .bold)
    static let headingMedium = Font.system(size: 20, weight: .bold)
    static let headingSmall = Font.system(size: 18, weight: .semibold)
    static let titleLarge = Font.system(size: 17, weight: .semibold)
    static let titleMedium = Font.system(size: 15, weight: .semibold)
    static let titleSmall = Font.system(size: 14, weight: .semibold)
    static let bodyLarge = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 15, weight: .regular)
    static let bodySmall = Font.system(size: 14, weight: .regular)
    static let labelLarge = Font.system(size: 15, weight: .semibold)
    static let labelMedium = Font.system(size: 14, weight: .medium)
    static let labelSmall = Font.system(size: 13, weight: .medium)
    static let caption = Font.system(size: 12, weight: .regular)
    static let numberLarge = Font.system(size: 28, weight: .bold)
    static let numberMedium = Font.system(size: 20, weight: .semibold)

    // MARK: - Kicker (Uppercase Labels)

    /// Kicker style for section labels - use with .kerning(trackingLoose) and .textCase(.uppercase)
    static let kicker = Font.system(size: 11, weight: .semibold)

    /// Editorial kicker using Clash Display
    static let editorialKicker = editorial(12, weight: .medium)
}

// MARK: - View Modifier for Editorial Kicker Style

extension View {
    /// Applies editorial kicker styling: uppercase, loose tracking
    func kickerStyle() -> some View {
        self
            .font(AppTypography.kicker)
            .kerning(AppTypography.trackingLoose)
            .textCase(.uppercase)
            .foregroundColor(AppColors.textSecondary)
    }

    /// Applies editorial headline tracking
    func editorialTracking() -> some View {
        self.kerning(AppTypography.trackingTight)
    }
}
