import SwiftUI

/// Step 1: Welcome/Splash screen - Editorial black design
struct OnboardingWelcomeView: View {
    let onContinue: () -> Void
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.95

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Wordmark
                Text("Styleum")
                    .font(AppTypography.clashDisplay(52))
                    .foregroundColor(.white)
                    .opacity(opacity)
                    .scaleEffect(scale)

                // Tagline - editorial serif italic
                Text("Dress like you're already there")
                    .font(.system(size: 17, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 12)
                    .opacity(opacity)
                    .offset(y: opacity == 0 ? 10 : 0)

                // Data disclaimer - builds trust
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13))
                    Text("Your wardrobe stays private")
                        .font(.system(size: 13))
                }
                .foregroundColor(.white.opacity(0.4))
                .padding(.top, 24)
                .opacity(opacity)
                .offset(y: opacity == 0 ? 10 : 0)

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
                .opacity(opacity)
                .offset(y: opacity == 0 ? 20 : 0)
            }
        }
        .onAppear {
            withAnimation(AppAnimations.springGentle.delay(0.1)) {
                opacity = 1
                scale = 1
            }
        }
    }
}

#Preview {
    OnboardingWelcomeView(onContinue: {})
}
