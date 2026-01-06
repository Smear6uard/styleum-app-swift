import SwiftUI

struct OnboardingReferralSourceView: View {
    let onSelect: (String) -> Void
    let onSkip: () -> Void

    private let options: [(label: String, value: String, icon: String)] = [
        ("TikTok", "tiktok", "play.rectangle.fill"),
        ("Instagram", "instagram", "camera.fill"),
        ("Friend or Family", "friend", "person.2.fill"),
        ("App Store", "app_store", "apple.logo"),
        ("Other", "other", "ellipsis.circle.fill")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    HapticManager.shared.selection()
                    onSkip()
                }
                .font(AppTypography.labelMedium)
                .foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, AppSpacing.sm)

            // Header
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("One last thing")
                    .font(AppTypography.displayLarge)
                    .foregroundColor(AppColors.textPrimary)

                Text("How did you hear about Styleum?")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, AppSpacing.sm)

            // Options
            VStack(spacing: AppSpacing.sm) {
                ForEach(options, id: \.value) { option in
                    Button {
                        HapticManager.shared.selection()
                        onSelect(option.value)
                    } label: {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: option.icon)
                                .font(.system(size: 20))
                                .foregroundColor(AppColors.textPrimary)
                                .frame(width: 24)

                            Text(option.label)
                                .font(AppTypography.bodyLarge)
                                .foregroundColor(AppColors.textPrimary)

                            Spacer()
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppColors.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.top, AppSpacing.sm)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.pageMargin)
        .background(AppColors.background)
    }
}

#Preview {
    OnboardingReferralSourceView(
        onSelect: { _ in },
        onSkip: {}
    )
}
