import SwiftUI

/// Celebration overlay when user marks an outfit as worn.
/// Shows XP flying up, confetti burst, and triggers toast.
struct WearOutfitCelebration: View {
    let xpAmount: Int
    let origin: CGPoint  // Button position for animation origin
    @Binding var isActive: Bool

    @State private var xpScale: CGFloat = 0
    @State private var xpOpacity: Double = 1
    @State private var xpOffset: CGFloat = 0
    @State private var particles: [WearParticle] = []
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0
    @State private var rippleScale: CGFloat = 0.5
    @State private var rippleOpacity: Double = 0.8

    private let colors: [Color] = [
        AppColors.success,
        AppColors.warning,
        Color(hex: "8B5CF6"),
        .white
    ]

    var body: some View {
        ZStack {
            // Ripple effect
            Circle()
                .stroke(AppColors.success.opacity(0.5), lineWidth: 3)
                .frame(width: 100, height: 100)
                .scaleEffect(rippleScale)
                .opacity(rippleOpacity)
                .position(origin)

            // Particles
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(x: origin.x + particle.x, y: origin.y + particle.y)
                    .opacity(particle.opacity)
            }

            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(AppColors.success)
                .scaleEffect(checkmarkScale)
                .opacity(checkmarkOpacity)
                .position(origin)

            // Flying XP
            HStack(spacing: 4) {
                Text("+\(xpAmount)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("XP")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(AppColors.success)
            .clipShape(Capsule())
            .shadow(color: AppColors.success.opacity(0.4), radius: 8, y: 2)
            .scaleEffect(xpScale)
            .opacity(xpOpacity)
            .offset(y: xpOffset)
            .position(origin)
        }
        .allowsHitTesting(false)
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        HapticManager.shared.success()

        // 1. Ripple expands
        withAnimation(.easeOut(duration: 0.5)) {
            rippleScale = 2.5
            rippleOpacity = 0
        }

        // 2. Checkmark appears
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            checkmarkScale = 1
            checkmarkOpacity = 1
        }

        // 3. Create particle burst
        createParticles()

        // 4. XP appears and floats up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                xpScale = 1
            }
        }

        // 5. Checkmark fades
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.2)) {
                checkmarkOpacity = 0
            }
        }

        // 6. XP floats up to header
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.6)) {
                xpOffset = -200
                xpOpacity = 0
            }
        }

        // 7. Complete and dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            isActive = false
        }
    }

    private func createParticles() {
        for i in 0..<12 {
            let angle = (Double(i) / 12.0) * 2 * .pi
            let velocity = Double.random(in: 40...80)
            let particle = WearParticle(
                id: i,
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 4...10),
                x: 0,
                y: 0,
                opacity: 1
            )
            particles.append(particle)

            let finalX = CGFloat(cos(angle) * velocity)
            let finalY = CGFloat(sin(angle) * velocity)

            withAnimation(.easeOut(duration: 0.6)) {
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

private struct WearParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
}

// MARK: - Animated Wear Button

/// Button that shows celebration when pressed.
struct WearOutfitButton: View {
    let onWear: () -> Void

    @State private var showCelebration = false
    @State private var buttonPosition: CGPoint = .zero
    @State private var isPressed = false

    var body: some View {
        GeometryReader { geo in
            Button {
                // Capture button position
                let frame = geo.frame(in: .global)
                buttonPosition = CGPoint(x: frame.midX, y: frame.midY)

                // Trigger celebration
                showCelebration = true
                onWear()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 18, weight: .semibold))

                    Text("Wear This")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.black)
                .cornerRadius(AppSpacing.radiusMd)
                .scaleEffect(isPressed ? 0.96 : 1)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        withAnimation(.spring(response: 0.2)) {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.2)) {
                            isPressed = false
                        }
                    }
            )
        }
        .frame(height: 50)
        .overlay {
            if showCelebration {
                WearOutfitCelebration(
                    xpAmount: 10,
                    origin: buttonPosition,
                    isActive: $showCelebration
                )
            }
        }
    }
}

// MARK: - Simple Wear Celebration Overlay

/// Simplified celebration that can be triggered from anywhere.
struct WearCelebrationOverlay: View {
    @Binding var isShowing: Bool
    let xpAmount: Int

    @State private var confettiActive = false
    @State private var textScale: CGFloat = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        if isShowing {
            ZStack {
                // Confetti
                if confettiActive {
                    MiniConfetti()
                }

                // XP text
                VStack(spacing: 4) {
                    Text("Looking great!")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))

                    HStack(spacing: 4) {
                        Text("+\(xpAmount)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("XP")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.success)
                        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
                )
                .scaleEffect(textScale)
                .opacity(textOpacity)
            }
            .onAppear {
                HapticManager.shared.success()

                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    textScale = 1
                    textOpacity = 1
                }

                confettiActive = true

                // Auto-dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        textOpacity = 0
                        textScale = 0.9
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isShowing = false
                    }
                }
            }
        }
    }
}

// MARK: - Mini Confetti

private struct MiniConfetti: View {
    @State private var pieces: [MiniConfettiPiece] = []

    private let colors: [Color] = [
        AppColors.success,
        AppColors.warning,
        Color(hex: "8B5CF6"),
        .white,
        AppColors.info
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    Circle()
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size)
                        .position(x: piece.x, y: piece.y)
                        .opacity(piece.opacity)
                }
            }
            .onAppear {
                createPieces(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func createPieces(in size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2

        for i in 0..<20 {
            let angle = Double.random(in: 0...(2 * .pi))
            let velocity = Double.random(in: 60...150)
            let piece = MiniConfettiPiece(
                id: i,
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 4...8),
                x: centerX,
                y: centerY,
                opacity: 1
            )
            pieces.append(piece)

            let finalX = centerX + CGFloat(cos(angle) * velocity)
            let finalY = centerY + CGFloat(sin(angle) * velocity) + 40 // Gravity

            withAnimation(.easeOut(duration: Double.random(in: 0.8...1.2))) {
                if let index = pieces.firstIndex(where: { $0.id == i }) {
                    pieces[index].x = finalX
                    pieces[index].y = finalY
                    pieces[index].opacity = 0
                }
            }
        }
    }
}

private struct MiniConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
}

// MARK: - Previews

#Preview("Wear Button") {
    VStack {
        Spacer()

        WearOutfitButton {
            print("Outfit worn!")
        }
        .padding(.horizontal, 20)

        Spacer()
    }
    .background(AppColors.background)
}

#Preview("Celebration Overlay") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        WearCelebrationOverlay(isShowing: .constant(true), xpAmount: 10)
    }
}
