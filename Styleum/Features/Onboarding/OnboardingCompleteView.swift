import SwiftUI

/// Final step: Loading + Completion screen combined
struct OnboardingCompleteView: View {
    let firstName: String
    let onContinue: () -> Void

    @State private var isLoading = true
    @State private var showContent = false
    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if isLoading {
                // Loading state - minimal with rotating quote
                VStack(spacing: AppSpacing.lg) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(AppColors.textMuted)

                    Text("\u{201E}\(StyleQuotes.todaysQuote)\u{201C}")
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(AppColors.textMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, AppSpacing.xl)
                }
            } else {
                // Complete state - playful editorial
                VStack(spacing: AppSpacing.sm) {
                    Text("Looking good already.")
                        .font(AppTypography.clashDisplay(32))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Welcome to Styleum, \(firstName)")
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(AppColors.textSecondary)
                }
                .opacity(showContent ? 1 : 0)
            }

            Spacer()

            if !isLoading {
                // What's next section
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("WHAT'S NEXT")
                        .font(AppTypography.kicker)
                        .foregroundColor(AppColors.textMuted)
                        .tracking(1)

                    NextStepRow(icon: "tshirt", text: "Add your first clothing items")
                    NextStepRow(icon: "square.stack", text: "Get personalized outfit suggestions")
                }
                .padding(.horizontal, AppSpacing.pageMargin)
                .opacity(showContent ? 1 : 0)

                // Continue button
                Button {
                    print("🎉 [COMPLETE] ========== START STYLING BUTTON TAPPED ==========")
                    print("🎉 [COMPLETE] Timestamp: \(Date())")
                    print("🎉 [COMPLETE] isLoading: \(isLoading)")
                    print("🎉 [COMPLETE] showContent: \(showContent)")
                    print("🎉 [COMPLETE] Triggering haptic...")
                    HapticManager.shared.achievementUnlock()
                    print("🎉 [COMPLETE] Calling onContinue()...")
                    onContinue()
                    print("🎉 [COMPLETE] onContinue() returned")
                } label: {
                    Text("Start styling")
                        .font(AppTypography.labelLarge)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppColors.black)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, AppSpacing.pageMargin)
                .padding(.top, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xl)
                .opacity(showContent ? 1 : 0)
            }
        }
        .background(AppColors.background)
        .overlay {
            if showConfetti {
                OnboardingConfettiOverlay()
                    .allowsHitTesting(false)
            }
        }
        .task {
            // Loading duration (backend calculates taste vector)
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeOut(duration: 0.3)) {
                isLoading = false
            }

            // Start confetti with haptic
            HapticManager.shared.achievementUnlock()
            showConfetti = true

            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.easeIn(duration: 0.4)) {
                showContent = true
            }
        }
    }
}

// MARK: - Onboarding Confetti Overlay

private struct OnboardingConfettiOverlay: View {
    @State private var confettiPieces: [OnboardingConfettiPiece] = []
    @State private var confettiTimer: Timer?

    private let colors: [Color] = [
        AppColors.brownPrimary,
        Color(hex: "F59E0B"),  // Warm gold
        Color(hex: "10B981"),  // Emerald
        .white,
        Color(hex: "8B5CF6")   // Violet
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
    }

    private func startConfetti(in size: CGSize) {
        // Create initial burst
        for i in 0..<50 {
            createConfettiPiece(id: i, in: size, delay: Double(i) * 0.03)
        }

        // Continue for a few seconds
        var pieceId = 50
        confettiTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if pieceId > 150 {
                timer.invalidate()
                return
            }
            if confettiPieces.count > 80 {
                confettiPieces.removeFirst(10)
            }
            createConfettiPiece(id: pieceId, in: size, delay: 0)
            pieceId += 1
        }
    }

    private func createConfettiPiece(id: Int, in size: CGSize, delay: Double) {
        let startX = CGFloat.random(in: 0...size.width)
        let startY: CGFloat = -20
        let endY = size.height + 50

        let piece = OnboardingConfettiPiece(
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

private struct OnboardingConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let width: CGFloat
    let height: CGFloat
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    var opacity: Double
}

/// Row showing next step with icon
struct NextStepRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 24)

            Text(text)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

#Preview {
    OnboardingCompleteView(
        firstName: "Sarah",
        onContinue: {}
    )
}
