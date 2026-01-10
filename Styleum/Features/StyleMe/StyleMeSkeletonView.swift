import SwiftUI

struct StyleMeSkeletonView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Skeleton outfit card
            VStack(spacing: 20) {
                // Main outfit image skeleton
                SkeletonRect(height: 280)
                    .cornerRadius(16)

                // Item thumbnails row skeleton
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonRect(width: 64, height: 64)
                            .cornerRadius(10)
                    }
                }

                // Text skeletons
                VStack(spacing: 10) {
                    SkeletonRect(width: 220, height: 22)
                        .cornerRadius(4)
                    SkeletonRect(width: 160, height: 16)
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Loading message at bottom
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.1)
                    .tint(AppColors.textSecondary)

                Text("Creating your looks...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.bottom, 60)
        }
    }
}

// MARK: - Skeleton Rectangle

struct SkeletonRect: View {
    var width: CGFloat? = nil
    let height: CGFloat

    @State private var isAnimating = false

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        AppColors.fill.opacity(isAnimating ? 0.3 : 0.5),
                        AppColors.fill.opacity(isAnimating ? 0.5 : 0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .animation(
                .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    ZStack {
        // Same background as StyleMeScreen
        LinearGradient(
            colors: [
                Color(hex: "E8E4DF"),
                Color(hex: "F5F3F0"),
                Color(hex: "FAFAF8")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        StyleMeSkeletonView()
    }
}
