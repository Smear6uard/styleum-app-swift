import SwiftUI

/// Card displaying daily challenges with progress bars and claim buttons.
/// Features pulsing claim buttons and confetti on completion.
struct DailyChallengesCard: View {
    /// Optional callback when a challenge is tapped (for navigation to complete it)
    var onChallengeTapped: ((DailyChallenge) -> Void)?

    @State private var gamificationService = GamificationService.shared
    @State private var isExpanded = true
    @State private var claimingChallengeId: String?
    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            headerRow
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, 12)

            if isExpanded {
                // Challenges list
                VStack(spacing: 0) {
                    ForEach(gamificationService.dailyChallenges) { challenge in
                        DailyChallengeRow(
                            challenge: challenge,
                            isClaiming: claimingChallengeId == challenge.id,
                            onClaim: {
                                claimChallenge(challenge)
                            },
                            onTap: {
                                // Navigate to complete challenge if not yet complete
                                if !challenge.isCompleted && !challenge.isClaimable {
                                    onChallengeTapped?(challenge)
                                }
                            }
                        )

                        if challenge.id != gamificationService.dailyChallenges.last?.id {
                            Divider()
                                .padding(.horizontal, AppSpacing.md)
                        }
                    }
                }

                // Reset timer
                if let timeUntilReset = gamificationService.timeUntilReset {
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 11, weight: .medium))

                        Text("Resets in \(timeUntilReset)")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(AppColors.textMuted)
                    .padding(.top, 12)
                    .padding(.bottom, AppSpacing.md)
                }
            }
        }
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusMd)
        .overlay {
            // Confetti overlay on all complete
            if showConfetti {
                ConfettiBurst()
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack {
            // Title
            Text("DAILY GOALS")
                .font(AppTypography.kicker)
                .foregroundColor(AppColors.textMuted)

            Spacer()

            // Progress dots
            HStack(spacing: 6) {
                ForEach(0..<gamificationService.totalChallengesCount, id: \.self) { index in
                    Circle()
                        .fill(index < gamificationService.completedChallengesCount ? AppColors.black : AppColors.backgroundTertiary)
                        .frame(width: 8, height: 8)
                }

                Text("\(gamificationService.completedChallengesCount)/\(gamificationService.totalChallengesCount)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }

            // Expand/collapse button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
                HapticManager.shared.light()
            } label: {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textMuted)
                    .frame(width: 28, height: 28)
                    .background(AppColors.background)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Actions

    private func claimChallenge(_ challenge: DailyChallenge) {
        guard challenge.isClaimable else { return }

        claimingChallengeId = challenge.id
        HapticManager.shared.medium()

        Task {
            let success = await gamificationService.claimChallenge(challenge)
            claimingChallengeId = nil

            if success {
                // Check if all challenges now complete
                if gamificationService.allChallengesComplete {
                    triggerAllCompleteConfetti()
                }
            }
        }
    }

    private func triggerAllCompleteConfetti() {
        HapticManager.shared.achievementUnlock()
        showConfetti = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            showConfetti = false
        }
    }
}

// MARK: - Daily Challenge Row

struct DailyChallengeRow: View {
    let challenge: DailyChallenge
    let isClaiming: Bool
    let onClaim: () -> Void
    var onTap: (() -> Void)?

    @State private var claimButtonPulse = false
    @State private var animatedProgress: Double = 0

    var body: some View {
        Button {
            onTap?()
        } label: {
            rowContent
        }
        .buttonStyle(.plain)
        .disabled(challenge.isCompleted || challenge.isClaimable)
    }

    private var challengeColor: Color {
        challenge.type?.color ?? AppColors.textPrimary
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: challenge.iconName ?? "star.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(challenge.isCompleted ? AppColors.success : challengeColor)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(challenge.isCompleted ? AppColors.success.opacity(0.15) : challengeColor.opacity(0.12))
                )

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                Text(challenge.description)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            // Progress or claim button
            if challenge.isCompleted {
                // Completed state
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.success)

                    Text("+\(challenge.xpReward)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.success)
                }
            } else if challenge.isClaimable {
                // Ready to claim
                Button {
                    onClaim()
                } label: {
                    HStack(spacing: 4) {
                        Text("CLAIM")
                            .font(.system(size: 11, weight: .bold))

                        Text("+\(challenge.xpReward)")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColors.success)
                    .clipShape(Capsule())
                    .scaleEffect(claimButtonPulse ? 1.05 : 1.0)
                }
                .disabled(isClaiming)
                .opacity(isClaiming ? 0.6 : 1)
            } else {
                // In progress
                VStack(alignment: .trailing, spacing: 4) {
                    Text(challenge.progressText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppColors.backgroundTertiary)
                                .frame(height: 5)

                            Capsule()
                                .fill(challengeColor)
                                .frame(width: max(5, geo.size.width * animatedProgress), height: 5)
                        }
                    }
                    .frame(width: 60, height: 5)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onAppear {
            // Animate progress
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                animatedProgress = challenge.progressPercent
            }
            // Start pulse for claimable
            if challenge.isClaimable {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    claimButtonPulse = true
                }
            }
        }
        .onChange(of: challenge.progressPercent) { _, newValue in
            withAnimation(.easeOut(duration: 0.4)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Confetti Burst

struct ConfettiBurst: View {
    @State private var particles: [ConfettiParticle] = []

    private let colors: [Color] = [
        AppColors.success,
        AppColors.warning,
        Color(hex: "8B5CF6"),
        AppColors.info,
        AppColors.black
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .offset(x: particle.x, y: particle.y)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func createParticles(in size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2

        for i in 0..<30 {
            let angle = Double.random(in: 0...(2 * .pi))
            let velocity = Double.random(in: 100...200)
            let particle = ConfettiParticle(
                id: i,
                color: colors.randomElement() ?? .black,
                size: CGFloat.random(in: 4...10),
                x: centerX,
                y: centerY,
                opacity: 1
            )
            particles.append(particle)

            // Animate outward
            let finalX = centerX + CGFloat(cos(angle) * velocity)
            let finalY = centerY + CGFloat(sin(angle) * velocity)

            withAnimation(.easeOut(duration: 1.2)) {
                if let index = particles.firstIndex(where: { $0.id == i }) {
                    particles[index].x = finalX
                    particles[index].y = finalY + 100 // Gravity effect
                    particles[index].opacity = 0
                }
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
}

// MARK: - Previews

#Preview("Daily Challenges Card") {
    VStack {
        DailyChallengesCard()
            .padding()
    }
    .background(AppColors.background)
}
