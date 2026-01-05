import SwiftUI

struct SplashView: View {
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.9

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.md) {
                // Clean wordmark - no icon
                Text("Styleum")
                    .font(.system(size: 36, weight: .semibold, design: .default))
                    .tracking(-0.5)
                    .foregroundColor(AppColors.textPrimary)

                // Optional subtle tagline
                Text("Style what you own")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textMuted)
            }
            .opacity(opacity)
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 1
                scale = 1
            }
        }
    }
}

#Preview {
    SplashView()
}
