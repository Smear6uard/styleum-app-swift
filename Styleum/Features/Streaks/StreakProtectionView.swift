import SwiftUI

// MARK: - Streak At Risk Warning

/// Warning banner shown when streak is at risk (after 6pm with no activity today).
struct StreakAtRiskBanner: View {
    @State private var gamificationService = GamificationService.shared
    let onGenerateOutfit: () -> Void
    let onAddItem: () -> Void

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 12) {
            // Warning header
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.warning)
                    .scaleEffect(pulse ? 1.1 : 1.0)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Your \(gamificationService.currentStreak)-day streak is at risk!")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Do any activity to keep it alive")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textMuted)
                }

                Spacer()
            }

            // Quick action buttons
            HStack(spacing: 12) {
                Button {
                    HapticManager.shared.medium()
                    onGenerateOutfit()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Generate Outfit")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColors.black)
                    .cornerRadius(AppSpacing.radiusSm)
                }

                Button {
                    HapticManager.shared.medium()
                    onAddItem()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add Item")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColors.backgroundTertiary)
                    .cornerRadius(AppSpacing.radiusSm)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                .fill(AppColors.warning.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                        .stroke(AppColors.warning.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Streak Freeze Prompt

/// Modal shown when user returns after missing a day.
struct StreakFreezePromptView: View {
    let streakCount: Int
    let freezesRemaining: Int
    let onUseFreeze: () -> Void
    let onStartOver: () -> Void
    @Binding var isPresented: Bool

    @State private var phase: Int = 0

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent dismiss by tapping outside
                }

            VStack(spacing: 24) {
                // Emoji
                Text("😱")
                    .font(.system(size: 64))
                    .opacity(phase >= 1 ? 1 : 0)
                    .scaleEffect(phase >= 1 ? 1 : 0.5)

                // Text content
                VStack(spacing: 8) {
                    Text("You broke your \(streakCount)-day streak!")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text("Use a streak freeze to restore it?")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                }
                .multilineTextAlignment(.center)
                .opacity(phase >= 2 ? 1 : 0)

                // Buttons
                VStack(spacing: 12) {
                    // Use freeze button
                    if freezesRemaining > 0 {
                        Button {
                            HapticManager.shared.success()
                            onUseFreeze()
                            isPresented = false
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "snowflake")
                                    .font(.system(size: 16, weight: .semibold))

                                Text("Use Freeze (\(freezesRemaining) left)")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(AppColors.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white)
                            .cornerRadius(AppSpacing.radiusMd)
                        }
                    }

                    // Start over button
                    Button {
                        HapticManager.shared.light()
                        onStartOver()
                        isPresented = false
                    } label: {
                        Text(freezesRemaining > 0 ? "Start Over" : "Start Fresh")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white.opacity(0.1))
                            .cornerRadius(AppSpacing.radiusMd)
                    }
                }
                .padding(.horizontal, 32)
                .opacity(phase >= 3 ? 1 : 0)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        HapticManager.shared.error()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.65).delay(0.1)) {
            phase = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                phase = 2
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                phase = 3
            }
        }
    }
}

// MARK: - Streak Lost View

/// Emotional impact screen when streak is lost and cannot be restored.
struct StreakLostView: View {
    let lostStreakCount: Int
    let onContinue: () -> Void
    @Binding var isPresented: Bool

    @State private var heartBroken = false
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            // Dark background
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Broken heart animation
                ZStack {
                    // Glow
                    Circle()
                        .fill(AppColors.danger.opacity(0.2))
                        .frame(width: 160, height: 160)

                    Text("💔")
                        .font(.system(size: 72))
                        .scaleEffect(heartBroken ? 1 : 0.8)
                        .opacity(heartBroken ? 1 : 0)
                }

                // Text
                VStack(spacing: 12) {
                    Text("Streak Lost")
                        .font(AppTypography.editorialHeadline)
                        .foregroundColor(.white)

                    Text("Your \(lostStreakCount)-day streak has ended.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))

                    Text("Don't give up! Start building again.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .multilineTextAlignment(.center)
                .opacity(textOpacity)

                Spacer()

                // Continue button
                Button {
                    HapticManager.shared.medium()
                    onContinue()
                    isPresented = false
                } label: {
                    Text("Let's Go")
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
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        HapticManager.shared.error()

        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
            heartBroken = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.4)) {
                textOpacity = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeOut(duration: 0.3)) {
                buttonOpacity = 1
            }
        }
    }
}

// MARK: - Streak Restored Celebration

/// Quick celebration when streak is successfully restored.
struct StreakRestoredToast: View {
    let streakCount: Int
    @Binding var isShowing: Bool

    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        if isShowing {
            HStack(spacing: 12) {
                Image(systemName: "snowflake")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.info)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Streak Restored!")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Text("\(streakCount)-day streak saved")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.warning)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.black)
                    .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
            )
            .padding(.horizontal, 20)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                HapticManager.shared.success()

                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                    scale = 1
                    opacity = 1
                }

                // Auto-dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        opacity = 0
                        scale = 0.95
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isShowing = false
                    }
                }
            }
        }
    }
}

// MARK: - Streak Protection Modifier

/// View modifier that monitors streak state and shows appropriate prompts.
struct StreakProtectionModifier: ViewModifier {
    @State private var gamificationService = GamificationService.shared
    @State private var showFreezePrompt = false
    @State private var showStreakLost = false
    @State private var showRestoredToast = false
    @State private var lostStreakCount = 0

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .streakAtRisk)) { _ in
                // Handled by StreakAtRiskBanner in HomeScreen
            }
            .onReceive(NotificationCenter.default.publisher(for: .streakRestored)) { _ in
                showRestoredToast = true
            }
            .fullScreenCover(isPresented: $showFreezePrompt) {
                StreakFreezePromptView(
                    streakCount: gamificationService.currentStreak,
                    freezesRemaining: gamificationService.streakFreezes,
                    onUseFreeze: {
                        Task {
                            await gamificationService.useStreakFreeze()
                        }
                    },
                    onStartOver: {
                        // Just dismiss - streak is already lost
                    },
                    isPresented: $showFreezePrompt
                )
                .background(Color.clear)
            }
            .fullScreenCover(isPresented: $showStreakLost) {
                StreakLostView(
                    lostStreakCount: lostStreakCount,
                    onContinue: {},
                    isPresented: $showStreakLost
                )
                .background(Color.clear)
            }
            .overlay(alignment: .top) {
                StreakRestoredToast(
                    streakCount: gamificationService.currentStreak,
                    isShowing: $showRestoredToast
                )
                .padding(.top, 60)
            }
    }
}

extension View {
    /// Adds streak protection prompts and celebrations.
    func streakProtection() -> some View {
        self.modifier(StreakProtectionModifier())
    }
}

// MARK: - Previews

#Preview("Streak At Risk") {
    StreakAtRiskBanner(
        onGenerateOutfit: {},
        onAddItem: {}
    )
    .padding()
    .background(AppColors.background)
}

#Preview("Freeze Prompt") {
    StreakFreezePromptView(
        streakCount: 7,
        freezesRemaining: 2,
        onUseFreeze: {},
        onStartOver: {},
        isPresented: .constant(true)
    )
}

#Preview("Streak Lost") {
    StreakLostView(
        lostStreakCount: 14,
        onContinue: {},
        isPresented: .constant(true)
    )
}

#Preview("Restored Toast") {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        StreakRestoredToast(
            streakCount: 7,
            isShowing: .constant(true)
        )
    }
}
