import SwiftUI

/// Celebration modal shown after successfully repairing a streak.
struct StreakRepairedCelebrationView: View {
    let restoredStreak: Int
    let xpSpent: Int
    let onContinue: () -> Void
    @Binding var isPresented: Bool

    @State private var phase: Int = 0
    @State private var glow = false
    @State private var confettiOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            // Confetti particles (subtle)
            ConfettiParticles()
                .opacity(confettiOpacity)

            VStack(spacing: 32) {
                Spacer()

                // Fire emoji with glow animation
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppColors.warning.opacity(0.4),
                                    AppColors.warning.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(glow ? 1.15 : 1.0)

                    Text("🔥")
                        .font(.system(size: 80))
                        .scaleEffect(phase >= 1 ? 1 : 0.3)
                        .opacity(phase >= 1 ? 1 : 0)
                }

                // Text content
                VStack(spacing: 16) {
                    Text("STREAK RESTORED!")
                        .font(.system(size: 24, weight: .black))
                        .tracking(1.5)
                        .foregroundColor(.white)

                    Text("\(restoredStreak)-Day Streak")
                        .font(AppTypography.editorialHeadline)
                        .foregroundColor(AppColors.warning)

                    // XP spent indicator
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                        Text("-\(xpSpent) XP")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 4)
                }
                .multilineTextAlignment(.center)
                .opacity(phase >= 2 ? 1 : 0)

                Spacer()

                // Continue button
                Button {
                    HapticManager.shared.medium()
                    onContinue()
                    isPresented = false
                } label: {
                    Text("Let's Go!")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .cornerRadius(AppSpacing.radiusMd)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .opacity(phase >= 3 ? 1 : 0)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        HapticManager.shared.streakMilestone()

        // Start glow animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glow = true
        }

        // Sequence entrance animations
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.1)) {
            phase = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.4)) {
                phase = 2
                confettiOpacity = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                phase = 3
            }
        }

        // Fade out confetti after a moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 1.0)) {
                confettiOpacity = 0
            }
        }
    }
}

// MARK: - Confetti Particles

/// Simple confetti particle effect for celebration
private struct ConfettiParticles: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
            }
        }
    }

    private func generateParticles(in size: CGSize) {
        let colors: [Color] = [
            AppColors.warning,
            AppColors.success,
            Color.white,
            AppColors.info
        ]

        particles = (0..<30).map { _ in
            ConfettiParticle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height * 0.6)
                ),
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 4...10),
                opacity: Double.random(in: 0.3...0.8)
            )
        }

        // Animate particles falling
        for i in particles.indices {
            let delay = Double.random(in: 0...0.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeIn(duration: Double.random(in: 1.5...3.0))) {
                    if i < particles.count {
                        particles[i].position.y += 300
                        particles[i].opacity = 0
                    }
                }
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}

// MARK: - Preview

#Preview("Streak Repaired Celebration") {
    StreakRepairedCelebrationView(
        restoredStreak: 14,
        xpSpent: 500,
        onContinue: {},
        isPresented: .constant(true)
    )
}
