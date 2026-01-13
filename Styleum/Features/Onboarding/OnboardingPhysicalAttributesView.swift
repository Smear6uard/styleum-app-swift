import SwiftUI

/// Height category options based on department
enum HeightOption: String, CaseIterable, Identifiable {
    case short = "short"
    case average = "average"
    case tall = "tall"

    var id: String { rawValue }

    func label(for department: String) -> String {
        let isFeminine = department.lowercased().contains("women")
        switch self {
        case .short:
            return isFeminine ? "Under 5'4\"" : "Under 5'8\""
        case .average:
            return isFeminine ? "5'4\" – 5'8\"" : "5'8\" – 5'11\""
        case .tall:
            return isFeminine ? "5'8\"+" : "6'0\"+"
        }
    }
}

/// Skin undertone options
enum UndertoneOption: String, CaseIterable, Identifiable {
    case warm = "warm"
    case cool = "cool"
    case neutral = "neutral"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .warm: return "Warm"
        case .cool: return "Cool"
        case .neutral: return "Neutral"
        }
    }

    var subtitle: String {
        switch self {
        case .warm: return "Gold jewelry suits you"
        case .cool: return "Silver jewelry suits you"
        case .neutral: return "Both gold & silver work"
        }
    }
}

/// Onboarding screen for height and skin undertone selection
struct OnboardingPhysicalAttributesView: View {
    let department: String
    @Binding var heightCategory: String?
    @Binding var skinUndertone: String?
    let onContinue: () -> Void
    let onSkip: () -> Void

    private var canContinue: Bool {
        heightCategory != nil && skinUndertone != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    // Height Section
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Your height")
                            .font(AppTypography.headingMedium)
                            .foregroundColor(AppColors.textPrimary)

                        Text("Helps us suggest flattering proportions")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)

                        HStack(spacing: AppSpacing.sm) {
                            ForEach(HeightOption.allCases) { option in
                                SelectionCard(
                                    title: option.label(for: department),
                                    subtitle: nil,
                                    isSelected: heightCategory == option.rawValue,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            heightCategory = option.rawValue
                                        }
                                        HapticManager.shared.light()
                                    }
                                )
                            }
                        }
                    }
                    .padding(.top, AppSpacing.lg)

                    // Undertone Section
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Your skin undertone")
                            .font(AppTypography.headingMedium)
                            .foregroundColor(AppColors.textPrimary)

                        Text("Helps us suggest complementary colors")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)

                        HStack(spacing: AppSpacing.sm) {
                            ForEach(UndertoneOption.allCases) { option in
                                SelectionCard(
                                    title: option.label,
                                    subtitle: option.subtitle,
                                    isSelected: skinUndertone == option.rawValue,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            skinUndertone = option.rawValue
                                        }
                                        HapticManager.shared.light()
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.pageMargin)
            }

            Spacer()

            // Buttons
            VStack(spacing: AppSpacing.md) {
                Button {
                    HapticManager.shared.light()
                    onSkip()
                } label: {
                    Text("Skip")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textMuted)
                }

                Button {
                    HapticManager.shared.medium()
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(AppTypography.labelLarge)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(canContinue ? AppColors.black : AppColors.textMuted)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!canContinue)
            }
            .padding(.horizontal, AppSpacing.pageMargin)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background)
    }
}

// MARK: - Selection Card Component

private struct SelectionCard: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.labelMedium)
                    .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }

                // Checkmark indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(.top, AppSpacing.xs)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .padding(.horizontal, AppSpacing.sm)
            .background(isSelected ? AppColors.black : AppColors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                    .stroke(isSelected ? AppColors.black : AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("\(title)\(subtitle.map { ", \($0)" } ?? "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    OnboardingPhysicalAttributesView(
        department: "womenswear",
        heightCategory: .constant(nil),
        skinUndertone: .constant(nil),
        onContinue: {},
        onSkip: {}
    )
}
