import SwiftUI

enum AppColors {
    // Warm Brown Accents - editorial, fashion-forward (primary brand accent)
    static let brownPrimary = Color(red: 0.18, green: 0.14, blue: 0.11)    // #2E241C
    static let brownSecondary = Color(red: 0.24, green: 0.20, blue: 0.16)  // #3D3329
    static let brownLight = Color(red: 0.35, green: 0.30, blue: 0.26)      // #594D42

    // Slate aliases → Brown (backward compatibility)
    // These now map to brown tones instead of gray-blue slate
    static let slate = brownSecondary       // was #6F7C86
    static let slateDark = brownPrimary     // was #3F474F
    static let slateLight = brownLight      // was #9BA5AE

    // Primary
    static let black = Color(hex: "111111")
    static let white = Color.white

    // Backgrounds - Semantic (auto dark mode)
    static let background = Color(uiColor: .systemBackground)
    static let backgroundSecondary = Color(uiColor: .secondarySystemBackground)
    static let backgroundTertiary = Color(uiColor: .tertiarySystemBackground)
    static let inputBackground = Color(hex: "F7F7F7")

    // Grouped backgrounds (for settings, lists)
    static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    static let groupedBackgroundSecondary = Color(uiColor: .secondarySystemGroupedBackground)

    // Text - Semantic (auto dark mode)
    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let textTertiary = Color(uiColor: .tertiaryLabel)
    static let textMuted = Color(uiColor: .placeholderText)

    // Fixed colors (don't change with dark mode)
    static let textPrimaryFixed = Color(hex: "111111")
    static let textSecondaryFixed = Color(hex: "4B5563")
    static let textMutedFixed = Color(hex: "6B7280")

    // UI Elements
    static let border = Color(uiColor: .separator)
    static let borderLight = Color(uiColor: .opaqueSeparator)
    static let filterTagBg = Color(hex: "F3F4F6")
    static let fill = Color(uiColor: .systemFill)
    static let fillSecondary = Color(uiColor: .secondarySystemFill)

    // Semantic Colors
    static let danger = Color(hex: "B42318")
    static let success = Color(hex: "059669")
    static let warning = Color(hex: "D97706")
    static let info = Color(hex: "0EA5E9")

    // Dark Bottom Sheet (fixed dark)
    static let darkSheet = Color(hex: "111111")
    static let darkSheetSecondary = Color(hex: "1A1A1A")
    static let darkSheetTertiary = Color(hex: "3F474F")
    static let darkSheetMuted = Color(hex: "9CA3AF")

    // Materials for blur effects
    static let thinMaterial: SwiftUI.Material = .ultraThinMaterial
    static let regularMaterial: SwiftUI.Material = .regularMaterial
    static let thickMaterial: SwiftUI.Material = .thickMaterial
}

// MARK: - Gradient Presets
extension AppColors {
    static let shimmerGradient = LinearGradient(
        colors: [.clear, .white.opacity(0.4), .clear],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let fadeGradient = LinearGradient(
        colors: [.black.opacity(0), .black.opacity(0.6)],
        startPoint: .top,
        endPoint: .bottom
    )
}
