import SwiftUI

struct SwipeCard<Content: View>: View {
    let content: Content
    var onSwipeLeft: (() -> Void)?
    var onSwipeRight: (() -> Void)?
    var onSwipeUp: (() -> Void)?

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @GestureState private var isDragging = false

    private let swipeThreshold: CGFloat = 120
    private let maxRotation: Double = 12

    init(
        onSwipeLeft: (() -> Void)? = nil,
        onSwipeRight: (() -> Void)? = nil,
        onSwipeUp: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
        self.onSwipeUp = onSwipeUp
    }

    private var swipeProgress: CGFloat {
        min(abs(offset.width) / swipeThreshold, 1)
    }

    private var isSwipingRight: Bool {
        offset.width > 0
    }

    var body: some View {
        ZStack {
            content

            // Like overlay
            if isSwipingRight && swipeProgress > 0.1 {
                likeOverlay
                    .opacity(Double(swipeProgress))
            }

            // Skip overlay
            if !isSwipingRight && swipeProgress > 0.1 {
                skipOverlay
                    .opacity(Double(swipeProgress))
            }
        }
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .gesture(
            DragGesture()
                .updating($isDragging) { _, state, _ in
                    state = true
                }
                .onChanged { gesture in
                    offset = gesture.translation
                    rotation = Double(gesture.translation.width / 20).clamped(to: -maxRotation...maxRotation)

                    // Haptic at threshold
                    if abs(gesture.translation.width) >= swipeThreshold - 10 {
                        HapticManager.shared.swipeThreshold()
                    }
                }
                .onEnded { gesture in
                    handleSwipeEnd(gesture)
                }
        )
        .animation(isDragging ? nil : AppAnimations.spring, value: offset)
        .animation(isDragging ? nil : AppAnimations.spring, value: rotation)
    }

    private var likeOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Image(symbol: .likeFilled)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(AppColors.success)
                    .padding(AppSpacing.lg)
            }
            Spacer()
        }
    }

    private var skipOverlay: some View {
        VStack {
            HStack {
                Image(symbol: .close)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(AppColors.danger)
                    .padding(AppSpacing.lg)
                Spacer()
            }
            Spacer()
        }
    }

    private func handleSwipeEnd(_ gesture: DragGesture.Value) {
        let horizontalAmount = gesture.translation.width
        let verticalAmount = gesture.translation.height

        if abs(horizontalAmount) > swipeThreshold {
            // Horizontal swipe
            let direction: CGFloat = horizontalAmount > 0 ? 1 : -1

            withAnimation(.easeOut(duration: 0.3)) {
                offset = CGSize(width: direction * 500, height: offset.height)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if direction > 0 {
                    HapticManager.shared.likeOutfit()
                    onSwipeRight?()
                } else {
                    HapticManager.shared.skipOutfit()
                    onSwipeLeft?()
                }
            }
        } else if verticalAmount < -swipeThreshold {
            // Swipe up
            withAnimation(.easeOut(duration: 0.3)) {
                offset = CGSize(width: 0, height: -500)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onSwipeUp?()
            }
        } else {
            // Reset
            withAnimation(AppAnimations.spring) {
                offset = .zero
                rotation = 0
            }
        }
    }
}

// MARK: - Comparable Extension
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Preview
#Preview {
    SwipeCard(
        onSwipeLeft: { print("Skipped") },
        onSwipeRight: { print("Liked") }
    ) {
        RoundedRectangle(cornerRadius: 20)
            .fill(LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: 300, height: 400)
            .overlay(
                Text("Swipe Me!")
                    .font(.title)
                    .foregroundColor(.white)
            )
    }
}
