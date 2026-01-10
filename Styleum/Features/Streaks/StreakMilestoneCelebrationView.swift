import SwiftUI

/// Full-screen celebration modal when user reaches a streak milestone.
/// Triggered via NotificationCenter when StreakService detects a milestone.
struct StreakMilestoneCelebrationView: View {
    let milestone: StreakMilestoneInfo
    @Binding var isPresented: Bool

    // Animation phases
    @State private var flameScale: CGFloat = 0
    @State private var badgeScale: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var confettiActive = false
    @State private var particles: [StreakParticle] = []

    // Flame colors
    private let flamePrimary = Color(hex: "FF6B35")
    private let flameSecondary = Color(hex: "FF9F1C")
    private let flameDark = Color(hex: "E63946")

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Content
            VStack(spacing: 28) {
                Spacer()

                // Flame badge with particles
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    flamePrimary.opacity(0.5),
                                    flamePrimary.opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 140
                            )
                        )
                        .frame(width: 280, height: 280)
                        .opacity(glowOpacity)

                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [flameSecondary, flameDark],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(badgeScale)
                        .shadow(color: flamePrimary.opacity(0.6), radius: 30)

                    // Streak number
                    VStack(spacing: 2) {
                        Text("\(milestone.days)")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundColor(.white)

                        Text("DAYS")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .scaleEffect(flameScale)

                    // Particles
                    ForEach(particles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .offset(x: particle.x, y: particle.y)
                            .opacity(particle.opacity)
                    }
                }
                .frame(height: 280)

                // Text content
                VStack(spacing: 12) {
                    // Kicker
                    Text("STREAK MILESTONE!")
                        .font(.system(size: 14, weight: .heavy))
                        .tracking(3)
                        .foregroundColor(flamePrimary)

                    // Title
                    Text(milestone.label)
                        .font(AppTypography.editorial(36, weight: .bold))
                        .foregroundColor(.white)

                    // Motivation message
                    Text(motivationMessage)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .opacity(textOpacity)

                Spacer()

                // Continue button
                Button {
                    dismiss()
                } label: {
                    Text("Keep the Fire Going")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [flameSecondary, flamePrimary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(AppSpacing.radiusMd)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .opacity(buttonOpacity)
            }

            // Confetti overlay
            if confettiActive {
                StreakConfettiOverlay()
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Motivation Messages

    private var motivationMessage: String {
        switch milestone.days {
        case 7:
            return "A full week! You're building a real habit."
        case 14:
            return "Two weeks strong! Consistency is your superpower."
        case 30:
            return "A whole month! You're officially committed."
        case 60:
            return "Two months of style excellence. Incredible!"
        case 90:
            return "A full quarter! You've mastered the art of consistency."
        case 365:
            return "One year! You're a true style legend."
        default:
            return "You're on fire! Keep the momentum going."
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        HapticManager.shared.achievementUnlock()

        // Phase 1: Badge scales in (0-0.4s)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
            badgeScale = 1
        }
        createParticleBurst()

        // Phase 2: Number scales in (0.15-0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                flameScale = 1
            }
            withAnimation(.easeOut(duration: 0.6)) {
                glowOpacity = 1
            }
        }

        // Phase 3: Text fades in (0.4-0.7s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.4)) {
                textOpacity = 1
            }
        }

        // Phase 4: Button appears (0.65-0.95s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(.easeOut(duration: 0.35)) {
                buttonOpacity = 1
            }
        }

        // Start confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            confettiActive = true
        }
    }

    private func createParticleBurst() {
        let colors: [Color] = [
            flamePrimary,
            flameSecondary,
            .white,
            flameDark
        ]

        for i in 0..<16 {
            let angle = (Double(i) / 16.0) * 2 * .pi
            let velocity = Double.random(in: 70...130)
            let particle = StreakParticle(
                id: i,
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 6...12),
                x: 0,
                y: 0,
                opacity: 1
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

    private func dismiss() {
        HapticManager.shared.light()

        withAnimation(.easeOut(duration: 0.25)) {
            isPresented = false
        }
    }
}

// MARK: - Supporting Types

struct StreakMilestoneInfo {
    let days: Int
    let label: String
    let icon: String
}

// MARK: - Particle Model

private struct StreakParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
}

// MARK: - Confetti Overlay

private struct StreakConfettiOverlay: View {
    @State private var confettiPieces: [StreakConfettiPiece] = []

    private let colors: [Color] = [
        Color(hex: "FF6B35"),  // Orange
        Color(hex: "FF9F1C"),  // Yellow-orange
        Color(hex: "E63946"),  // Red
        .white,
        Color(hex: "FFD166")   // Gold
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(confettiPieces) { piece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color)
                        .frame(width: piece.width, height: piece.height)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(x: piece.x, y: piece.y)
                        .opacity(piece.opacity)
                }
            }
            .onAppear {
                startConfetti(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func startConfetti(in size: CGSize) {
        // Create initial batch
        for i in 0..<40 {
            createConfettiPiece(id: i, in: size, delay: Double(i) * 0.05)
        }

        // Create continuous stream
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            if confettiPieces.count > 100 {
                confettiPieces.removeFirst(10)
            }
            let newId = confettiPieces.count + Int.random(in: 1000...9999)
            createConfettiPiece(id: newId, in: size, delay: 0)
        }
    }

    private func createConfettiPiece(id: Int, in size: CGSize, delay: Double) {
        let startX = CGFloat.random(in: 0...size.width)
        let startY: CGFloat = -20
        let endY = size.height + 50

        let piece = StreakConfettiPiece(
            id: id,
            color: colors.randomElement() ?? .white,
            width: CGFloat.random(in: 6...12),
            height: CGFloat.random(in: 12...20),
            x: startX,
            y: startY,
            rotation: Double.random(in: 0...360),
            opacity: 1
        )

        confettiPieces.append(piece)

        let fallDuration = Double.random(in: 2.5...4.0)
        let drift = CGFloat.random(in: -30...30)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.linear(duration: fallDuration)) {
                if let index = confettiPieces.firstIndex(where: { $0.id == id }) {
                    confettiPieces[index].y = endY
                    confettiPieces[index].x += drift
                    confettiPieces[index].rotation += Double.random(in: 180...720)
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + fallDuration * 0.8) {
                withAnimation(.easeOut(duration: fallDuration * 0.2)) {
                    if let index = confettiPieces.firstIndex(where: { $0.id == id }) {
                        confettiPieces[index].opacity = 0
                    }
                }
            }
        }
    }
}

private struct StreakConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let width: CGFloat
    let height: CGFloat
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    var opacity: Double
}

// MARK: - View Modifier

struct StreakMilestoneCelebrationModifier: ViewModifier {
    @State private var milestoneInfo: StreakMilestoneInfo?
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .streakMilestoneReached)) { notification in
                if let info = notification.object as? StreakMilestoneInfo {
                    milestoneInfo = info
                    isPresented = true
                }
            }
            .fullScreenCover(isPresented: $isPresented) {
                if let info = milestoneInfo {
                    StreakMilestoneCelebrationView(milestone: info, isPresented: $isPresented)
                        .background(Color.clear)
                }
            }
    }
}

extension View {
    /// Adds streak milestone celebration overlay triggered by notification
    func streakMilestoneCelebration() -> some View {
        self.modifier(StreakMilestoneCelebrationModifier())
    }
}

// MARK: - Preview

#Preview {
    StreakMilestoneCelebrationView(
        milestone: StreakMilestoneInfo(days: 7, label: "Week Warrior", icon: "flame"),
        isPresented: .constant(true)
    )
}
