import SwiftUI

/// Shimmer overlay shown while wardrobe item is being processed by AI
struct ProcessingItemOverlay: View {
    @State private var shimmerOffset: CGFloat = -200
    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    var body: some View {
        ZStack {
            // Base shimmer background
            Rectangle()
                .fill(AppColors.backgroundSecondary)

            // Animated shimmer gradient
            if !reduceMotion {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.35), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
            } else {
                Rectangle()
                    .fill(Color.white.opacity(0.15))
            }

            // "Processing..." badge at bottom
            VStack {
                Spacer()
                Text("Processing...")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 12)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                shimmerOffset = 200
            }
        }
    }
}

#Preview {
    ProcessingItemOverlay()
        .aspectRatio(3/4, contentMode: .fit)
        .frame(width: 180)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}
