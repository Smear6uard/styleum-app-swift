import SwiftUI

/// A brief ritual moment before outfit generation begins.
/// Creates anticipation and transforms Style Me from a feature into a daily ritual.
struct StyleMeEntranceCeremony: View {
    @Binding var isComplete: Bool

    // Animation states
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0
    @State private var kickerOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1

    // Particle burst
    @State private var particles: [CeremonyParticle] = []

    var body: some View {
        ZStack {
            // Warm gradient background
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

            // Content
            VStack(spacing: 32) {
                Spacer()

                // Logo with glow and particles
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppColors.textPrimary.opacity(0.08),
                                    AppColors.textPrimary.opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .opacity(glowOpacity)
                        .scaleEffect(pulseScale)

                    // Particles
                    ForEach(particles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .offset(x: particle.x, y: particle.y)
                            .opacity(particle.opacity)
                    }

                    // Logo
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                // Text content
                VStack(spacing: 12) {
                    // Kicker
                    Text("YOUR DAILY")
                        .font(.system(size: 12, weight: .semibold))
                        .kerning(AppTypography.trackingLoose)
                        .foregroundColor(AppColors.textSecondary)
                        .opacity(kickerOpacity)

                    // Title
                    Text("Style Ritual")
                        .font(AppTypography.editorial(32, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .opacity(titleOpacity)
                }

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            startCeremony()
        }
    }

    // MARK: - Animation Sequence

    private func startCeremony() {
        // Soft haptic to begin
        HapticManager.shared.soft()

        // Phase 1: Logo scales in (0-0.35s) - faster spring
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            logoScale = 1.0
            logoOpacity = 1
        }

        // Phase 2: Glow expands (0.08-0.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeOut(duration: 0.32)) {
                glowOpacity = 1
            }
            createParticleBurst()
        }

        // Phase 3: Kicker fades in (0.2-0.45s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.25)) {
                kickerOpacity = 1
            }
        }

        // Phase 4: Title fades in (0.35-0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.25)) {
                titleOpacity = 1
            }
        }

        // Phase 5: Gentle pulse (0.55-0.9s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeInOut(duration: 0.35)) {
                pulseScale = 1.05
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    pulseScale = 1.0
                }
            }
        }

        // Phase 6: Complete ceremony (1.2s total)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.2)) {
                isComplete = true
            }
        }
    }

    private func createParticleBurst() {
        let colors: [Color] = [
            AppColors.textPrimary.opacity(0.4),
            AppColors.textSecondary.opacity(0.3),
            Color(hex: "D4AF37").opacity(0.3),  // Subtle gold accent
            AppColors.textPrimary.opacity(0.2)
        ]

        for i in 0..<12 {
            let angle = (Double(i) / 12.0) * 2 * .pi
            let velocity = Double.random(in: 50...80)
            let particle = CeremonyParticle(
                id: i,
                color: colors.randomElement() ?? .gray,
                size: CGFloat.random(in: 4...8),
                x: 0,
                y: 0,
                opacity: 0.8
            )
            particles.append(particle)

            let finalX = CGFloat(cos(angle) * velocity)
            let finalY = CGFloat(sin(angle) * velocity)

            withAnimation(.easeOut(duration: 0.8)) {
                if let index = particles.firstIndex(where: { $0.id == i }) {
                    particles[index].x = finalX
                    particles[index].y = finalY
                    particles[index].opacity = 0
                }
            }
        }
    }
}

// MARK: - Particle Model

private struct CeremonyParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
}

// MARK: - Preview

#Preview {
    StyleMeEntranceCeremony(isComplete: .constant(false))
}
