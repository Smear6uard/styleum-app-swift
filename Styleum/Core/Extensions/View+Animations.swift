import SwiftUI

// MARK: - Press Animation Modifier
struct PressAnimationModifier: ViewModifier {
    @State private var isPressed = false
    let scale: CGFloat
    let opacity: CGFloat

    init(scale: CGFloat = 0.97, opacity: CGFloat = 1.0) {
        self.scale = scale
        self.opacity = opacity
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .opacity(isPressed ? opacity : 1.0)
            .animation(AppAnimations.fast, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Lift Animation Modifier
struct LiftAnimationModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .offset(y: isPressed ? -2 : 0)
            .shadow(
                color: .black.opacity(isPressed ? 0.08 : 0.04),
                radius: isPressed ? 12 : 8,
                x: 0,
                y: isPressed ? 4 : 2
            )
            .animation(AppAnimations.springSnappy, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Staggered Appearance
struct StaggeredAppearance: ViewModifier {
    let index: Int
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(AppAnimations.staggered(index: index)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.4),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 400 - 200)
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    func pressAnimation(scale: CGFloat = 0.97, opacity: CGFloat = 1.0) -> some View {
        modifier(PressAnimationModifier(scale: scale, opacity: opacity))
    }

    func liftAnimation() -> some View {
        modifier(LiftAnimationModifier())
    }

    func staggeredAppearance(index: Int) -> some View {
        modifier(StaggeredAppearance(index: index))
    }

    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }

    func reduceMotion(_ reducedAnimation: Animation, normalAnimation: Animation) -> Animation {
        UIAccessibility.isReduceMotionEnabled ? reducedAnimation : normalAnimation
    }
}
