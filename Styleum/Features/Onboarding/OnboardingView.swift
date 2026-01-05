import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let pages = [
        OnboardingPage(
            icon: .wardrobe,
            title: "Build Your Wardrobe",
            description: "Add your clothes by taking photos. We'll analyze colors, styles, and patterns automatically."
        ),
        OnboardingPage(
            icon: .styleMe,
            title: "Get Styled Daily",
            description: "Tell us the occasion and we'll suggest outfits based on weather, your schedule, and your style."
        ),
        OnboardingPage(
            icon: .achievements,
            title: "Track Your Style Journey",
            description: "Earn achievements, build streaks, and discover new ways to wear what you own."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    dismiss()
                }
                .font(AppTypography.labelMedium)
                .foregroundColor(AppColors.textSecondary)
            }
            .padding(AppSpacing.pageMargin)

            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Page indicator
            HStack(spacing: AppSpacing.xs) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? AppColors.textPrimary : AppColors.textMuted.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(AppAnimations.spring, value: currentPage)
                }
            }
            .padding(.vertical, AppSpacing.lg)

            // CTA
            AppButton(label: currentPage == pages.count - 1 ? "Get Started" : "Continue") {
                if currentPage < pages.count - 1 {
                    withAnimation(AppAnimations.spring) {
                        currentPage += 1
                    }
                } else {
                    dismiss()
                }
            }
            .padding(.horizontal, AppSpacing.pageMargin)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background)
    }
}

struct OnboardingPage {
    let icon: AppSymbol
    let title: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Icon
            Circle()
                .fill(AppColors.slate.opacity(0.1))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(symbol: page.icon)
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.slate)
                )

            // Text
            VStack(spacing: AppSpacing.md) {
                Text(page.title)
                    .font(AppTypography.headingLarge)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(AppTypography.bodyLarge)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppSpacing.xl)

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
