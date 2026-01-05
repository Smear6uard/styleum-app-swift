import SwiftUI

struct EmptyState: View {
    let icon: AppSymbol
    let headline: String
    let description: String
    var ctaLabel: String?
    var ctaAction: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Icon circle
            Circle()
                .fill(AppColors.slate.opacity(0.1))
                .frame(width: 88, height: 88)
                .overlay(
                    Image(symbol: icon)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(AppColors.slate)
                )

            // Text content
            VStack(spacing: AppSpacing.xs) {
                Text(headline)
                    .font(AppTypography.headingMedium)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            // CTA button
            if let ctaLabel = ctaLabel, let ctaAction = ctaAction {
                AppButton(
                    label: ctaLabel,
                    size: .medium,
                    fullWidth: false,
                    action: ctaAction
                )
                .padding(.top, AppSpacing.xs)
            }
        }
        .padding(AppSpacing.xl)
    }
}

// MARK: - Preview
#Preview {
    EmptyState(
        icon: .wardrobe,
        headline: "Your closet is empty",
        description: "Add items to your wardrobe to start getting personalized outfit suggestions.",
        ctaLabel: "Add First Item",
        ctaAction: {}
    )
}
