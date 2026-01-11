import SwiftUI

/// Full-screen celebration modal when user upgrades to Pro.
/// Shows confetti, crown animation, and list of unlocked features.
struct ProUpgradeCelebrationView: View {
    let trigger: UpgradeTrigger?
    let onDismiss: () -> Void

    /// Contextual subtitle based on WHY the user upgraded
    private var contextualSubtitle: String {
        guard let trigger = trigger else {
            return "Your style journey just got unlimited"
        }

        switch trigger {
        case .lockedOutfits:
            return "All your outfit options are now unlocked"
        case .capsuleComplete:
            return "Your full wardrobe is ready to explore"
        case .creditsExhausted:
            return "Unlimited styling, starting now"
        case .streakAtRisk:
            return "Your streak is safe with freezes"
        case .historyLocked:
            return "Your complete style history awaits"
        case .analyticsLocked:
            return "Deep wardrobe insights are yours"
        case .manual:
            return "Your style journey just got unlimited"
        }
    }

    // Animation phases
    @State private var crownScale: CGFloat = 0
    @State private var badgeScale: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var featuresOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var confettiActive = false
    @State private var particles: [ProParticle] = []

    // Gold/premium colors
    private let goldPrimary = Color(hex: "D4AF37")
    private let goldSecondary = Color(hex: "FFD700")
    private let goldDark = Color(hex: "B8860B")

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            // Content
            VStack(spacing: 28) {
                Spacer()

                // Crown badge with particles
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    goldPrimary.opacity(0.5),
                                    goldPrimary.opacity(0)
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
                                colors: [goldPrimary, goldDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(badgeScale)
                        .shadow(color: goldPrimary.opacity(0.6), radius: 30)

                    // Crown icon
                    Image(systemName: "crown.fill")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundStyle(.white)
                        .scaleEffect(crownScale)

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
                    Text("WELCOME TO")
                        .font(.system(size: 14, weight: .heavy))
                        .tracking(3)
                        .foregroundColor(goldPrimary)

                    // Title
                    Text("Styleum Pro")
                        .font(AppTypography.editorial(36, weight: .bold))
                        .foregroundColor(.white)

                    // Subtitle - contextual based on upgrade trigger
                    Text(contextualSubtitle)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .opacity(textOpacity)

                // Unlocked features
                VStack(spacing: 12) {
                    UnlockedFeatureRow(icon: "infinity", text: "Unlimited wardrobe items")
                    UnlockedFeatureRow(icon: "sparkles", text: "Unlimited Style Me")
                    UnlockedFeatureRow(icon: "chart.pie", text: "Wardrobe analytics")
                    UnlockedFeatureRow(icon: "snowflake", text: "Streak freezes")
                }
                .padding(.horizontal, 40)
                .opacity(featuresOpacity)

                Spacer()

                // Continue button
                Button {
                    dismiss()
                } label: {
                    Text("Start Exploring")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [goldSecondary, goldPrimary],
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
                ProConfettiOverlay()
            }
        }
        .onAppear {
            startAnimation()
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

        // Phase 2: Crown scales in (0.15-0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                crownScale = 1
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

        // Phase 4: Features fade in (0.6-0.9s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.4)) {
                featuresOpacity = 1
            }
        }

        // Phase 5: Button appears (0.8-1.1s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
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
            goldPrimary,
            goldSecondary,
            .white,
            goldDark
        ]

        for i in 0..<16 {
            let angle = (Double(i) / 16.0) * 2 * .pi
            let velocity = Double.random(in: 70...130)
            let particle = ProParticle(
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
        onDismiss()
    }
}

// MARK: - Particle Model

private struct ProParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
}

// MARK: - Unlocked Feature Row

private struct UnlockedFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.green)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))

            Spacer()
        }
    }
}

// MARK: - Confetti Overlay

private struct ProConfettiOverlay: View {
    @State private var confettiPieces: [ProConfettiPiece] = []
    @State private var confettiTimer: Timer?

    private let colors: [Color] = [
        Color(hex: "D4AF37"),  // Gold
        Color(hex: "FFD700"),  // Bright gold
        Color(hex: "B8860B"),  // Dark gold
        .white,
        Color(hex: "FFF8DC")   // Cornsilk
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
            .onDisappear {
                confettiTimer?.invalidate()
                confettiTimer = nil
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
        confettiTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
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

        let piece = ProConfettiPiece(
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

private struct ProConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let width: CGFloat
    let height: CGFloat
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    var opacity: Double
}

// MARK: - Preview

#Preview("From Credits Exhausted") {
    ProUpgradeCelebrationView(trigger: .creditsExhausted, onDismiss: {})
}

#Preview("From Locked Outfits") {
    ProUpgradeCelebrationView(trigger: .lockedOutfits, onDismiss: {})
}

#Preview("Manual Upgrade") {
    ProUpgradeCelebrationView(trigger: .manual, onDismiss: {})
}
