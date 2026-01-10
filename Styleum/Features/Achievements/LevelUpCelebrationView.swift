import SwiftUI

/// Full-screen celebration modal when user levels up.
/// Triggered via NotificationCenter when GamificationService detects a level increase.
struct LevelUpCelebrationView: View {
    let levelUpInfo: LevelUpInfo
    @Binding var isPresented: Bool

    // Animation phases
    @State private var phase: Int = 0
    @State private var particles: [LevelUpParticle] = []
    @State private var circleScale: CGFloat = 0
    @State private var levelScale: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var confettiActive = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Content
            VStack(spacing: 32) {
                Spacer()

                // Level badge with particles
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "8B5CF6").opacity(0.6),
                                    Color(hex: "8B5CF6").opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .opacity(glowOpacity)

                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.black, Color(hex: "1A1A1A")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(circleScale)
                        .shadow(color: Color(hex: "8B5CF6").opacity(0.5), radius: 30)

                    // Level number
                    VStack(spacing: 4) {
                        Text("LVL")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))

                        Text("\(levelUpInfo.newLevel)")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(levelScale)

                    // Particles
                    ForEach(particles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .offset(x: particle.x, y: particle.y)
                            .opacity(particle.opacity)
                    }
                }
                .frame(height: 240)

                // Text content
                VStack(spacing: 12) {
                    // Kicker
                    Text("LEVEL UP!")
                        .font(.system(size: 14, weight: .heavy))
                        .tracking(3)
                        .foregroundColor(Color(hex: "8B5CF6"))

                    // Level title
                    Text(levelUpInfo.levelTitle)
                        .font(AppTypography.editorial(32, weight: .bold))
                        .foregroundColor(.white)

                    // Motivation message
                    Text(motivationMessage)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(textOpacity)

                Spacer()

                // Continue button
                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .cornerRadius(AppSpacing.radiusMd)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .opacity(buttonOpacity)
            }

            // Continuous confetti
            if confettiActive {
                ConfettiOverlay()
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Motivation Messages

    private var motivationMessage: String {
        switch levelUpInfo.newLevel {
        case 2: return "You're just getting started. Keep exploring!"
        case 3: return "Building momentum. Your wardrobe is growing!"
        case 4: return "Style confidence is rising. Keep it up!"
        case 5: return "Halfway to double digits. You're on fire!"
        case 6...10: return "You're becoming a style expert!"
        case 11...15: return "Your fashion sense is truly impressive."
        case 16...20: return "A true style authority. Incredible!"
        case 21...30: return "You've achieved style icon status!"
        default: return "Legendary status achieved. You're unstoppable!"
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        HapticManager.shared.achievementUnlock()

        // Phase 1: Circle scales in with particles (0-0.4s)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
            circleScale = 1
        }
        createParticleBurst()

        // Phase 2: Level number scales in (0.2-0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                levelScale = 1
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

        // Phase 4: Button appears (0.6-0.9s)
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
            Color(hex: "8B5CF6"),
            AppColors.warning,
            AppColors.success,
            .white
        ]

        for i in 0..<16 {
            let angle = (Double(i) / 16.0) * 2 * .pi
            let velocity = Double.random(in: 60...120)
            let particle = LevelUpParticle(
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

// MARK: - Particle Model

private struct LevelUpParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
}

// MARK: - Confetti Overlay

private struct ConfettiOverlay: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var confettiTimer: Timer?

    private let colors: [Color] = [
        Color(hex: "8B5CF6"),
        AppColors.warning,
        AppColors.success,
        .white,
        AppColors.info
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
        confettiTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
            if confettiPieces.count > 100 {
                // Remove old pieces
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

        let piece = ConfettiPiece(
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

        // Animate falling
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

            // Fade out at end
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

private struct ConfettiPiece: Identifiable {
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

struct LevelUpCelebrationModifier: ViewModifier {
    @State private var levelUpInfo: LevelUpInfo?
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .levelUp)) { notification in
                if let info = notification.object as? LevelUpInfo {
                    levelUpInfo = info
                    isPresented = true
                }
            }
            .fullScreenCover(isPresented: $isPresented) {
                if let info = levelUpInfo {
                    LevelUpCelebrationView(levelUpInfo: info, isPresented: $isPresented)
                        .background(Color.clear)
                }
            }
    }
}

extension View {
    /// Adds level-up celebration overlay triggered by notification
    func levelUpCelebration() -> some View {
        self.modifier(LevelUpCelebrationModifier())
    }
}

// MARK: - Previews

#Preview("Level Up Celebration") {
    Color.gray
        .ignoresSafeArea()
        .overlay {
            LevelUpCelebrationView(
                levelUpInfo: LevelUpInfo(
                    newLevel: 12,
                    oldLevel: 11,
                    levelTitle: "Style Maven"
                ),
                isPresented: .constant(true)
            )
        }
}
