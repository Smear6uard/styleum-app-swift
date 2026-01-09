import SwiftUI

/// One-time onboarding sheet explaining free tier limits to new users
struct TierOnboardingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tierManager = TierManager.shared
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Welcome header
            VStack(spacing: 12) {
                Text("Welcome to Styleum!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Here's what you can do on the free plan")
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .multilineTextAlignment(.center)

            // Free tier limits
            VStack(alignment: .leading, spacing: 16) {
                FreeLimitRow(
                    icon: "tshirt",
                    text: "25 wardrobe items",
                    detail: "Add your favorite pieces"
                )

                FreeLimitRow(
                    icon: "sparkles",
                    text: "2 outfit suggestions daily",
                    detail: "Get styled each morning"
                )

                FreeLimitRow(
                    icon: "wand.and.stars",
                    text: "10 Style Me credits/month",
                    detail: "Let AI pick your look"
                )

                FreeLimitRow(
                    icon: "snowflake",
                    text: "1 streak freeze/month",
                    detail: "Protect your progress"
                )
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))

            Spacer()

            // CTA section
            VStack(spacing: 12) {
                Button {
                    Task { await startStyling() }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(AppColors.background)
                        } else {
                            Text("Start Styling")
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppColors.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                }
                .disabled(isLoading)

                Text("Upgrade anytime for unlimited access")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textMuted)
            }
        }
        .padding(.horizontal, AppSpacing.pageMargin)
        .padding(.vertical, 24)
        .background(AppColors.background)
        .interactiveDismissDisabled()
    }

    private func startStyling() async {
        isLoading = true
        defer { isLoading = false }

        await tierManager.markOnboardingSeen()
        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - Supporting Views

private struct FreeLimitRow: View {
    let icon: String
    let text: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppColors.brownPrimary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)

                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    TierOnboardingSheet()
}
