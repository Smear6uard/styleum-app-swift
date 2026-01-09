import SwiftUI

/// Paywall shown when user's streak is at risk and they're out of freezes
struct StreakAtRiskView: View {
    @Environment(\.dismiss) var dismiss
    let currentStreak: Int
    let freezesRemaining: Int
    let onUseFreeze: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Flame emoji
            Text("\u{1F525}")
                .font(.system(size: 64))

            VStack(spacing: 8) {
                Text("Your \(currentStreak)-day streak is at risk")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                if freezesRemaining == 0 {
                    Text("Life happens. Pro members get 5 streak freezes monthly.")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                } else {
                    Text("Use a streak freeze to protect your progress.")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                // Use freeze if available
                if freezesRemaining > 0 {
                    Button {
                        HapticManager.shared.medium()
                        onUseFreeze()
                        dismiss()
                    } label: {
                        Text("Use Streak Freeze (\(freezesRemaining) left)")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                    }
                }

                // Upgrade CTA
                Button {
                    HapticManager.shared.medium()
                    dismiss()
                    onUpgrade()
                } label: {
                    Text("Protect My Streak")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(freezesRemaining > 0 ? AppColors.textPrimary : AppColors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(freezesRemaining > 0 ? AppColors.backgroundSecondary : AppColors.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                }

                // Dismiss
                if freezesRemaining > 0 {
                    Button {
                        HapticManager.shared.light()
                        dismiss()
                    } label: {
                        Text("Let it break")
                            .font(AppTypography.labelMedium)
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
            }

            Spacer()
        }
        .padding(32)
        .background(AppColors.background)
    }
}

#Preview("No Freezes") {
    StreakAtRiskView(
        currentStreak: 14,
        freezesRemaining: 0,
        onUseFreeze: {},
        onUpgrade: { print("Upgrade tapped") }
    )
}

#Preview("Has Freezes") {
    StreakAtRiskView(
        currentStreak: 7,
        freezesRemaining: 2,
        onUseFreeze: { print("Freeze used") },
        onUpgrade: { print("Upgrade tapped") }
    )
}
