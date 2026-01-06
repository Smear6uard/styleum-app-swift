import SwiftUI

/// Final step: Loading + Completion screen combined
struct OnboardingCompleteView: View {
    let firstName: String
    let onContinue: () -> Void

    @State private var isLoading = true
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if isLoading {
                // Loading state - minimal with rotating quote
                VStack(spacing: AppSpacing.lg) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(AppColors.textMuted)

                    Text("\u{201E}\(StyleQuotes.todaysQuote)\u{201C}")
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(AppColors.textMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, AppSpacing.xl)
                }
            } else {
                // Complete state - playful editorial
                VStack(spacing: AppSpacing.sm) {
                    Text("Looking good already.")
                        .font(AppTypography.clashDisplay(32))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Welcome to Styleum, \(firstName)")
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(AppColors.textSecondary)
                }
                .opacity(showContent ? 1 : 0)
            }

            Spacer()

            if !isLoading {
                // What's next section
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("WHAT'S NEXT")
                        .font(AppTypography.kicker)
                        .foregroundColor(AppColors.textMuted)
                        .tracking(1)

                    NextStepRow(icon: "tshirt", text: "Add your first clothing items")
                    NextStepRow(icon: "square.stack", text: "Get personalized outfit suggestions")
                }
                .padding(.horizontal, AppSpacing.pageMargin)
                .opacity(showContent ? 1 : 0)

                // Continue button
                Button {
                    print("🎉 [COMPLETE] ========== START STYLING BUTTON TAPPED ==========")
                    print("🎉 [COMPLETE] Timestamp: \(Date())")
                    print("🎉 [COMPLETE] isLoading: \(isLoading)")
                    print("🎉 [COMPLETE] showContent: \(showContent)")
                    print("🎉 [COMPLETE] Triggering haptic...")
                    HapticManager.shared.achievementUnlock()
                    print("🎉 [COMPLETE] Calling onContinue()...")
                    onContinue()
                    print("🎉 [COMPLETE] onContinue() returned")
                } label: {
                    Text("Start styling")
                        .font(AppTypography.labelLarge)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppColors.black)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, AppSpacing.pageMargin)
                .padding(.top, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xl)
                .opacity(showContent ? 1 : 0)
            }
        }
        .background(AppColors.background)
        .task {
            // Loading duration (backend calculates taste vector)
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeOut(duration: 0.3)) {
                isLoading = false
            }
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.easeIn(duration: 0.4)) {
                showContent = true
            }
        }
    }
}

/// Row showing next step with icon
struct NextStepRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 24)

            Text(text)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

#Preview {
    OnboardingCompleteView(
        firstName: "Sarah",
        onContinue: {}
    )
}
