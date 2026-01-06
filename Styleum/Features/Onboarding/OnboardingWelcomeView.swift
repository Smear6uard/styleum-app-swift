import SwiftUI

/// Step 1: Welcome/Splash screen - Editorial black design
struct OnboardingWelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Wordmark
                Text("Styleum")
                    .font(AppTypography.clashDisplay(52))
                    .foregroundColor(.white)

                // Tagline - editorial serif italic
                Text("Dress like you're already there")
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 12)

                // Data disclaimer - builds trust
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13))
                    Text("Your wardrobe stays private")
                        .font(.system(size: 13))
                }
                .foregroundColor(.white.opacity(0.4))
                .padding(.top, 24)

                Spacer()

                // Get Started button - white on black
                Button {
                    HapticManager.shared.medium()
                    onContinue()
                } label: {
                    Text("Get Started")
                        .font(AppTypography.labelLarge)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, AppSpacing.pageMargin)
                .padding(.bottom, AppSpacing.xl)
            }
        }
    }
}

#Preview {
    OnboardingWelcomeView(onContinue: {})
}
