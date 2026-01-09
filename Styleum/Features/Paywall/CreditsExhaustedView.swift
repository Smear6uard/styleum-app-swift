import SwiftUI

/// Paywall shown when user runs out of Style Me credits
struct CreditsExhaustedView: View {
    @Environment(\.dismiss) var dismiss
    let creditsUsed: Int
    let creditsLimit: Int
    let daysUntilReset: Int
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.brownPrimary)

            VStack(spacing: 8) {
                Text("You're styling a lot this month")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("You've used \(creditsUsed) of \(creditsLimit) Style Me credits. They refresh in \(daysUntilReset) day\(daysUntilReset == 1 ? "" : "s").")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 12) {
                // Primary CTA
                Button {
                    HapticManager.shared.medium()
                    dismiss()
                    onUpgrade()
                } label: {
                    Text("Go Unlimited")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                }

                // Wait option
                Button {
                    HapticManager.shared.light()
                    dismiss()
                } label: {
                    Text("I'll wait \(daysUntilReset) day\(daysUntilReset == 1 ? "" : "s")")
                        .font(AppTypography.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Spacer()
        }
        .padding(32)
        .background(AppColors.background)
    }
}

#Preview {
    CreditsExhaustedView(
        creditsUsed: 5,
        creditsLimit: 5,
        daysUntilReset: 12,
        onUpgrade: { print("Upgrade tapped") }
    )
}
