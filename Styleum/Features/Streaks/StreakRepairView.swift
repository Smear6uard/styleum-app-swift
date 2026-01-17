import SwiftUI

/// Modal shown when user can repair a broken streak by spending XP.
/// Appears within 24 hours of streak breaking.
struct StreakRepairView: View {
    @State private var gamificationService = GamificationService.shared
    let onRepairComplete: (Int, Int) -> Void  // (restoredStreak, xpSpent)
    let onStartFresh: () -> Void
    @Binding var isPresented: Bool

    @State private var phase: Int = 0
    @State private var isRepairing = false
    @State private var pulse = false

    /// Whether we're in critical time (under 6 hours)
    private var isCritical: Bool {
        gamificationService.hoursUntilRepairExpires < 6
    }

    /// Countdown text for repair window
    private var countdownText: String {
        let hours = gamificationService.hoursUntilRepairExpires
        if hours <= 1 {
            return "Less than 1 hour left!"
        } else {
            return "\(hours) hours left to repair"
        }
    }

    /// XP needed to afford repair
    private var xpNeeded: Int {
        max(0, gamificationService.repairCost - gamificationService.xp)
    }

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent dismiss by tapping outside
                }

            VStack(spacing: 24) {
                Spacer()

                // Broken heart emoji with animation
                ZStack {
                    // Glow
                    Circle()
                        .fill(AppColors.danger.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulse ? 1.1 : 1.0)

                    Text("💔")
                        .font(.system(size: 64))
                        .scaleEffect(phase >= 1 ? 1 : 0.5)
                        .opacity(phase >= 1 ? 1 : 0)
                }

                // Text content
                VStack(spacing: 12) {
                    Text("Your streak ended")
                        .font(AppTypography.editorialHeadline)
                        .foregroundColor(.white)

                    Text("Your \(gamificationService.previousStreak)-day streak was broken")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))

                    // Time pressure indicator
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(countdownText)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(isCritical ? AppColors.danger : AppColors.warning)
                    .padding(.top, 4)
                }
                .multilineTextAlignment(.center)
                .opacity(phase >= 2 ? 1 : 0)

                Spacer()

                // XP Balance display
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.warning)
                        Text("\(gamificationService.xp) XP")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    if !gamificationService.hasEnoughXPForRepair {
                        Text("Need \(xpNeeded) more XP")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.danger)
                    }
                }
                .opacity(phase >= 3 ? 1 : 0)

                // Buttons
                VStack(spacing: 12) {
                    // Repair button
                    Button {
                        repairStreak()
                    } label: {
                        HStack(spacing: 8) {
                            if isRepairing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.black))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 16, weight: .semibold))
                            }

                            Text("Repair for \(gamificationService.repairCost) XP")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(AppColors.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            gamificationService.hasEnoughXPForRepair
                                ? Color.white
                                : Color.white.opacity(0.3)
                        )
                        .cornerRadius(AppSpacing.radiusMd)
                    }
                    .disabled(!gamificationService.hasEnoughXPForRepair || isRepairing)

                    // Start fresh button
                    Button {
                        HapticManager.shared.light()
                        onStartFresh()
                        isPresented = false
                    } label: {
                        Text("Start Fresh")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white.opacity(0.1))
                            .cornerRadius(AppSpacing.radiusMd)
                    }
                    .disabled(isRepairing)
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
        HapticManager.shared.error()

        // Start pulse animation
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulse = true
        }

        // Sequence the entrance animations
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
            phase = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.4)) {
                phase = 2
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeOut(duration: 0.3)) {
                phase = 3
            }
        }
    }

    private func repairStreak() {
        guard gamificationService.hasEnoughXPForRepair else { return }

        HapticManager.shared.medium()
        isRepairing = true

        Task {
            let success = await gamificationService.repairStreak()

            await MainActor.run {
                isRepairing = false

                if success {
                    // Pass the restored streak info to callback
                    onRepairComplete(
                        gamificationService.currentStreak,
                        gamificationService.repairCost
                    )
                    isPresented = false
                } else {
                    // Show error feedback
                    HapticManager.shared.error()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Streak Repair - Can Afford") {
    StreakRepairView(
        onRepairComplete: { _, _ in },
        onStartFresh: {},
        isPresented: .constant(true)
    )
}

#Preview("Streak Repair - Cannot Afford") {
    StreakRepairView(
        onRepairComplete: { _, _ in },
        onStartFresh: {},
        isPresented: .constant(true)
    )
}
