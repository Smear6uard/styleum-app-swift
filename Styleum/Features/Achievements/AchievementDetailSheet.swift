import SwiftUI

struct AchievementDetailSheet: View {
    let achievementId: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Handle indicator
            Capsule()
                .fill(AppColors.textMuted.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, AppSpacing.sm)

            // Achievement icon
            Circle()
                .fill(AppColors.slate.opacity(0.15))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(symbol: .star)
                        .font(.system(size: 36))
                        .foregroundColor(AppColors.slate)
                )

            // Title and description
            VStack(spacing: AppSpacing.xs) {
                Text("Achievement Name")
                    .font(AppTypography.headingMedium)

                Text("Complete this milestone to earn this achievement badge.")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppSpacing.lg)

            // Progress
            VStack(spacing: AppSpacing.sm) {
                HStack {
                    Text("Progress")
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text("3 / 10")
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColors.textPrimary)
                }

                ProgressBar(progress: 0.3)
            }
            .padding(.horizontal, AppSpacing.pageMargin)

            Spacer()

            // Close button
            AppButton(label: "Close", variant: .secondary) {
                dismiss()
            }
            .padding(.horizontal, AppSpacing.pageMargin)
            .padding(.bottom, AppSpacing.lg)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    AchievementDetailSheet(achievementId: "test-achievement")
}
