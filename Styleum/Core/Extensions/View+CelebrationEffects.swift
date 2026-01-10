//
//  View+CelebrationEffects.swift
//  Styleum
//
//  Celebration effects for major moments - level ups, milestones, achievements
//

import SwiftUI

// MARK: - Shake Effect Modifier

/// A celebration shake effect for major milestones
struct CelebrationShakeModifier: ViewModifier {
    @Binding var trigger: Bool
    let intensity: CGFloat
    let duration: Double

    @State private var shakeOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: shakeOffset)
            .onChange(of: trigger) { _, shouldShake in
                if shouldShake {
                    performShake()
                }
            }
    }

    private func performShake() {
        let shakeDuration = duration / 6

        // Quick back-and-forth shake sequence
        withAnimation(.easeInOut(duration: shakeDuration)) {
            shakeOffset = intensity
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + shakeDuration) {
            withAnimation(.easeInOut(duration: shakeDuration)) {
                shakeOffset = -intensity
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + shakeDuration * 2) {
            withAnimation(.easeInOut(duration: shakeDuration)) {
                shakeOffset = intensity * 0.6
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + shakeDuration * 3) {
            withAnimation(.easeInOut(duration: shakeDuration)) {
                shakeOffset = -intensity * 0.6
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + shakeDuration * 4) {
            withAnimation(.easeInOut(duration: shakeDuration)) {
                shakeOffset = intensity * 0.3
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + shakeDuration * 5) {
            withAnimation(.easeInOut(duration: shakeDuration)) {
                shakeOffset = 0
            }
            // Reset trigger
            trigger = false
        }
    }
}

// MARK: - Glow Pulse Effect

struct GlowPulseModifier: ViewModifier {
    @Binding var trigger: Bool
    let color: Color
    let intensity: CGFloat

    @State private var glowRadius: CGFloat = 0
    @State private var glowOpacity: Double = 0

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(glowOpacity), radius: glowRadius)
            .onChange(of: trigger) { _, shouldPulse in
                if shouldPulse {
                    performPulse()
                }
            }
    }

    private func performPulse() {
        // Quick glow expand
        withAnimation(.easeOut(duration: 0.2)) {
            glowRadius = intensity
            glowOpacity = 0.6
        }

        // Sustain briefly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.4)) {
                glowRadius = intensity * 1.2
                glowOpacity = 0.3
            }
        }

        // Fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeIn(duration: 0.3)) {
                glowRadius = 0
                glowOpacity = 0
            }
            trigger = false
        }
    }
}

// MARK: - Bounce Pop Effect

struct BouncePopModifier: ViewModifier {
    @Binding var trigger: Bool
    let scale: CGFloat

    @State private var currentScale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(currentScale)
            .onChange(of: trigger) { _, shouldPop in
                if shouldPop {
                    performPop()
                }
            }
    }

    private func performPop() {
        // Quick scale up
        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
            currentScale = scale
        }

        // Bounce back
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                currentScale = 1.0
            }
            trigger = false
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Adds a celebration shake effect
    /// - Parameters:
    ///   - trigger: Binding that triggers the shake when set to true
    ///   - intensity: How far to shake (default 8 points)
    ///   - duration: Total duration of shake animation (default 0.4 seconds)
    func celebrationShake(
        _ trigger: Binding<Bool>,
        intensity: CGFloat = 8,
        duration: Double = 0.4
    ) -> some View {
        modifier(CelebrationShakeModifier(
            trigger: trigger,
            intensity: intensity,
            duration: duration
        ))
    }

    /// Adds a glow pulse effect for celebrations
    /// - Parameters:
    ///   - trigger: Binding that triggers the glow when set to true
    ///   - color: Color of the glow
    ///   - intensity: Radius of the glow (default 20 points)
    func celebrationGlow(
        _ trigger: Binding<Bool>,
        color: Color = .white,
        intensity: CGFloat = 20
    ) -> some View {
        modifier(GlowPulseModifier(
            trigger: trigger,
            color: color,
            intensity: intensity
        ))
    }

    /// Adds a bouncy pop effect
    /// - Parameters:
    ///   - trigger: Binding that triggers the pop when set to true
    ///   - scale: Maximum scale during pop (default 1.15)
    func celebrationPop(
        _ trigger: Binding<Bool>,
        scale: CGFloat = 1.15
    ) -> some View {
        modifier(BouncePopModifier(
            trigger: trigger,
            scale: scale
        ))
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var shakeTriggered = false
        @State private var glowTriggered = false
        @State private var popTriggered = false

        var body: some View {
            VStack(spacing: 40) {
                // Shake demo
                VStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 80, height: 80)
                        .celebrationShake($shakeTriggered)

                    Button("Shake") {
                        shakeTriggered = true
                    }
                }

                // Glow demo
                VStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 80, height: 80)
                        .celebrationGlow($glowTriggered, color: .orange)

                    Button("Glow") {
                        glowTriggered = true
                    }
                }

                // Pop demo
                VStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 80, height: 80)
                        .celebrationPop($popTriggered)

                    Button("Pop") {
                        popTriggered = true
                    }
                }
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
