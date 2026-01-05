import SwiftUI

enum AppButtonVariant {
    case primary    // Black background, white text
    case secondary  // White background, black border
    case tertiary   // No background, black text
    case danger     // Red background, white text
}

enum AppButtonSize {
    case small      // Height 40
    case medium     // Height 50
    case large      // Height 56

    var height: CGFloat {
        switch self {
        case .small: return 40
        case .medium: return 50
        case .large: return 56
        }
    }

    var font: Font {
        switch self {
        case .small: return AppTypography.labelMedium
        case .medium: return AppTypography.labelLarge
        case .large: return AppTypography.titleMedium
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 20
        case .large: return 22
        }
    }
}

struct AppButton: View {
    let label: String
    var variant: AppButtonVariant = .primary
    var size: AppButtonSize = .medium
    var icon: AppSymbol?
    var iconPosition: IconPosition = .leading
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var fullWidth: Bool = true
    let action: () -> Void

    enum IconPosition {
        case leading, trailing
    }

    private var backgroundColor: Color {
        if isDisabled { return AppColors.fillSecondary }
        switch variant {
        case .primary: return AppColors.black
        case .secondary: return .clear
        case .tertiary: return .clear
        case .danger: return AppColors.danger
        }
    }

    private var foregroundColor: Color {
        if isDisabled { return AppColors.textMuted }
        switch variant {
        case .primary: return .white
        case .secondary: return AppColors.textPrimary
        case .tertiary: return AppColors.textPrimary
        case .danger: return .white
        }
    }

    private var borderColor: Color {
        switch variant {
        case .secondary: return AppColors.border
        default: return .clear
        }
    }

    var body: some View {
        Button(action: {
            guard !isLoading && !isDisabled else { return }
            HapticManager.shared.buttonTap()
            action()
        }) {
            HStack(spacing: AppSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.9)
                } else {
                    if let icon = icon, iconPosition == .leading {
                        Image(symbol: icon)
                            .font(.system(size: size.iconSize, weight: .semibold))
                    }

                    Text(label)
                        .font(size.font)

                    if let icon = icon, iconPosition == .trailing {
                        Image(symbol: icon)
                            .font(.system(size: size.iconSize, weight: .semibold))
                    }
                }
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, AppSpacing.lg)
            .background(backgroundColor)
            .cornerRadius(AppSpacing.radiusMd)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                    .stroke(borderColor, lineWidth: variant == .secondary ? 1.5 : 0)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isLoading || isDisabled)
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppAnimations.fast, value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        AppButton(label: "Primary Button", variant: .primary) {}
        AppButton(label: "Secondary Button", variant: .secondary) {}
        AppButton(label: "With Icon", icon: .add) {}
        AppButton(label: "Loading", isLoading: true) {}
        AppButton(label: "Disabled", isDisabled: true) {}
        AppButton(label: "Danger", variant: .danger) {}
        AppButton(label: "Small", size: .small, fullWidth: false) {}
    }
    .padding()
}
