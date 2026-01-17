import SwiftUI

/// One-time onboarding sheet explaining free tier limits to new users
/// Minimal, editorial design aesthetic
struct TierOnboardingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tierManager = TierManager.shared
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Editorial headline
            VStack(spacing: 4) {
                Text("Your Free Plan")
                    .font(AppTypography.editorial(28, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Includes")
                    .font(AppTypography.editorialItalic(28, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(.bottom, 40)

            // Simple bullet list - no icons
            VStack(alignment: .leading, spacing: 16) {
                BulletPoint("30 wardrobe items")
                BulletPoint("2 daily outfit suggestions")
                BulletPoint("5 Style Me credits per month")
                BulletPoint("1 streak freeze per month")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)

            Spacer()
            Spacer()

            // Minimal CTA
            VStack(spacing: 16) {
                Button {
                    Task { await startStyling() }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Continue")
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSm))
                }
                .disabled(isLoading)

                Text("Upgrade anytime")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textMuted)
            }
        }
        .padding(.horizontal, AppSpacing.pageMargin)
        .padding(.vertical, 32)
        .background(AppColors.background)
        .interactiveDismissDisabled()
        .onAppear {
            // Safety: dismiss if user is actually Pro (shouldn't happen, but defensive)
            if tierManager.isPro {
                dismiss()
            }
        }
    }

    private func startStyling() async {
        isLoading = true
        defer { isLoading = false }

        await tierManager.markOnboardingSeen()
        HapticManager.shared.light()
        dismiss()
    }
}

// MARK: - Supporting Views

private struct BulletPoint: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("—")
                .foregroundStyle(AppColors.textMuted)

            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textPrimary)
        }
    }
}

// MARK: - Previews

#Preview {
    TierOnboardingSheet()
}
