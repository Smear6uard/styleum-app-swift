//
//  ReferralCelebrationView.swift
//  Styleum
//
//  Celebration view shown when a referral completes (friend joins).
//

import SwiftUI

struct ReferralCelebrationView: View {
    @Environment(\.dismiss) private var dismiss
    let daysEarned: Int

    // Animation states
    @State private var showBadge = false
    @State private var showIcon = false
    @State private var showGlow = false
    @State private var showText = false
    @State private var showButton = false
    @State private var particles: [Particle] = []

    // Colors
    private let accentColor = AppColors.brownPrimary
    private let accentLight = Color(hex: "8B7355")

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dark overlay
                Color.black.opacity(0.85)
                    .ignoresSafeArea()

                // Confetti layer
                ConfettiOverlay(screenSize: geo.size)

                // Particle burst layer
                ForEach(particles) { particle in
                    ParticleView(particle: particle)
                }

                // Content
                VStack(spacing: AppSpacing.lg) {
                    Spacer()

                    // Badge with glow
                    ZStack {
                        // Glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [accentColor.opacity(0.4), .clear]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 140
                                )
                            )
                            .frame(width: 280, height: 280)
                            .opacity(showGlow ? 1 : 0)
                            .blur(radius: 20)

                        // Badge circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "1A1A1A"), .black],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 140, height: 140)
                            .shadow(color: accentColor.opacity(0.5), radius: showGlow ? 30 : 10, y: 0)
                            .scaleEffect(showBadge ? 1 : 0.5)
                            .opacity(showBadge ? 1 : 0)

                        // Icon
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(accentColor)
                            .scaleEffect(showIcon ? 1 : 0.3)
                            .opacity(showIcon ? 1 : 0)
                    }

                    // Text content
                    VStack(spacing: AppSpacing.sm) {
                        Text("REFERRAL COMPLETE")
                            .font(AppTypography.kicker)
                            .foregroundColor(accentLight)
                            .opacity(showText ? 1 : 0)
                            .offset(y: showText ? 0 : 10)

                        Text("Your friend joined!")
                            .font(AppTypography.editorialHeadline)
                            .foregroundColor(.white)
                            .opacity(showText ? 1 : 0)
                            .offset(y: showText ? 0 : 10)

                        Text("You've earned \(daysEarned) days of Pro")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(.white.opacity(0.7))
                            .opacity(showText ? 1 : 0)
                            .offset(y: showText ? 0 : 10)
                    }

                    Spacer()

                    // Continue button
                    Button {
                        HapticManager.shared.light()
                        dismiss()
                    } label: {
                        Text("Awesome!")
                            .font(AppTypography.labelLarge)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [accentLight, accentColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(AppSpacing.radiusMd)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, AppSpacing.pageMargin)
                    .opacity(showButton ? 1 : 0)
                    .offset(y: showButton ? 0 : 20)

                    Spacer()
                        .frame(height: AppSpacing.xl)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Haptic burst
        HapticManager.shared.achievementUnlock()

        // Badge scale in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
            showBadge = true
        }

        // Icon scale in (slight delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                showIcon = true
            }
        }

        // Glow fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.6)) {
                showGlow = true
            }
        }

        // Emit particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            emitParticles()
        }

        // Text content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.4)) {
                showText = true
            }
        }

        // Button
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(.easeOut(duration: 0.35)) {
                showButton = true
            }
        }
    }

    private func emitParticles() {
        let particleCount = 16
        let colors: [Color] = [accentColor, accentLight, AppColors.success, .white]

        for i in 0..<particleCount {
            let angle = Double(i) * (360.0 / Double(particleCount))
            let velocity = CGFloat.random(in: 60...120)
            let particle = Particle(
                color: colors[i % colors.count],
                angle: angle,
                velocity: velocity,
                size: CGFloat.random(in: 6...12)
            )
            particles.append(particle)
        }
    }
}

// MARK: - Confetti Overlay (uses GeometryReader size)

private struct ConfettiOverlay: View {
    let screenSize: CGSize
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var confettiTimer: Timer?

    private let colors: [Color] = [
        AppColors.brownPrimary,
        Color(hex: "8B7355"),
        AppColors.success,
        .white
    ]

    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                ConfettiPieceView(piece: piece, screenHeight: screenSize.height)
            }
        }
        .onAppear {
            startConfetti()
        }
        .onDisappear {
            confettiTimer?.invalidate()
            confettiTimer = nil
        }
    }

    private func startConfetti() {
        confettiTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if confettiPieces.count < 100 {
                let piece = ConfettiPiece(
                    color: colors.randomElement()!,
                    startX: CGFloat.random(in: 0...screenSize.width),
                    size: CGFloat.random(in: 6...12)
                )
                confettiPieces.append(piece)
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Confetti Piece

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let startX: CGFloat
    let size: CGFloat
    let rotation: Double = .random(in: 0...360)
    let duration: Double = .random(in: 2.5...4.0)
    let drift: CGFloat = .random(in: -30...30)
}

private struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let screenHeight: CGFloat

    @State private var offset: CGFloat = -20
    @State private var opacity: Double = 1

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size * 1.5)
            .rotationEffect(.degrees(piece.rotation))
            .position(x: piece.startX + piece.drift, y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.linear(duration: piece.duration)) {
                    offset = screenHeight + 50
                }
                withAnimation(.linear(duration: piece.duration).delay(piece.duration * 0.8)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Particle

private struct Particle: Identifiable {
    let id = UUID()
    let color: Color
    let angle: Double
    let velocity: CGFloat
    let size: CGFloat
}

private struct ParticleView: View {
    let particle: Particle

    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1

    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                let radians = particle.angle * .pi / 180
                let endX = cos(radians) * particle.velocity
                let endY = sin(radians) * particle.velocity

                withAnimation(.easeOut(duration: 0.8)) {
                    offset = CGSize(width: endX, height: endY)
                    opacity = 0
                }
            }
    }
}

// MARK: - Referral Celebration Modifier

#if os(iOS)
struct ReferralCelebrationModifier: ViewModifier {
    @State private var showCelebration = false
    @State private var daysEarned = 7

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $showCelebration) {
                ReferralCelebrationView(daysEarned: daysEarned)
            }
            .onReceive(NotificationCenter.default.publisher(for: .referralCompleted)) { notification in
                if let days = notification.userInfo?["daysEarned"] as? Int {
                    daysEarned = days
                }
                showCelebration = true
            }
    }
}
#else
struct ReferralCelebrationModifier: ViewModifier {
    @State private var showCelebration = false
    @State private var daysEarned = 7

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showCelebration) {
                ReferralCelebrationView(daysEarned: daysEarned)
            }
            .onReceive(NotificationCenter.default.publisher(for: .referralCompleted)) { notification in
                if let days = notification.userInfo?["daysEarned"] as? Int {
                    daysEarned = days
                }
                showCelebration = true
            }
    }
}
#endif

extension View {
    /// Adds referral completion celebration overlay
    func referralCelebration() -> some View {
        self.modifier(ReferralCelebrationModifier())
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let referralCompleted = Notification.Name("referralCompleted")
}

// MARK: - Preview

#Preview {
    ReferralCelebrationView(daysEarned: 7)
}
