import SwiftUI

/// Paywall shown when user reaches wardrobe item limit
/// Uses positive framing: "Your capsule is complete"
struct CapsuleCompleteView: View {
    @Environment(\.dismiss) var dismiss
    let currentCount: Int
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Celebration icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("Your capsule is complete")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("You've curated \(currentCount) pieces — the perfect foundation for endless outfits.")
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
                    Text("Unlock Full Wardrobe")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                }

                // Secondary dismiss
                Button {
                    HapticManager.shared.light()
                    dismiss()
                } label: {
                    Text("I'm good with \(currentCount)")
                        .font(AppTypography.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            // Social proof
            Text("Most Styleum users upgrade around this point")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textMuted)
                .padding(.top, 8)

            Spacer()
        }
        .padding(32)
        .background(AppColors.background)
    }
}

#Preview {
    CapsuleCompleteView(
        currentCount: 30,
        onUpgrade: { print("Upgrade tapped") }
    )
}
