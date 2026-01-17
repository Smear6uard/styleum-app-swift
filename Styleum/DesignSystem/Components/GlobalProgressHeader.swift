import SwiftUI

/// Persistent global header showing streak, XP progress, and level.
/// Displayed on all main screens to keep users aware of their progress.
struct GlobalProgressHeader: View {
    @State private var gamificationService = GamificationService.shared
    @State private var isExpanded = false
    @State private var animatedProgress: Double = 0

    // Pulse animation for streak flame
    @State private var flamePulse = false

    // Bounce animation for streak increment
    @State private var streakBounce = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
                HapticManager.shared.light()
            } label: {
                mainContent
            }
            .buttonStyle(.plain)

            // Expanded stats panel
            if isExpanded {
                expandedStats
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .background(AppColors.background)
        .onAppear {
            // Animate progress bar fill
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animatedProgress = gamificationService.levelProgress
            }
            // Start flame pulse
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                flamePulse = true
            }
        }
        .onChange(of: gamificationService.levelProgress) { _, newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = newValue
            }
        }
        .onChange(of: gamificationService.currentStreak) { oldValue, newValue in
            if newValue > oldValue && oldValue > 0 {
                // Streak increased - trigger bounce animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    streakBounce = true
                }
                // Reset after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    streakBounce = false
                }
                HapticManager.shared.success()
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        HStack(spacing: 16) {
            // Streak section
            streakSection

            // XP Progress bar
            xpProgressSection

            // Level badge
            levelSection
        }
        .padding(.horizontal, AppSpacing.pageMargin)
        .padding(.vertical, 10)
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        HStack(spacing: 6) {
            // Flame icon with pulse
            Image(systemName: gamificationService.currentStreak > 0 ? "flame.fill" : "flame")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(gamificationService.currentStreak > 0 ? AppColors.warning : AppColors.textMuted)
                .scaleEffect(flamePulse && gamificationService.currentStreak > 0 ? 1.1 : 1.0)

            VStack(alignment: .leading, spacing: 0) {
                Text("\(gamificationService.currentStreak)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .scaleEffect(streakBounce ? 1.3 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: streakBounce)

                Text("streak")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(AppColors.textMuted)
                    .textCase(.uppercase)
            }
        }
        .frame(minWidth: 50)
    }

    // MARK: - XP Progress Section

    private var xpProgressSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(AppColors.backgroundTertiary)
                        .frame(height: 8)

                    // Progress fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.slate, AppColors.slateDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * animatedProgress), height: 8)
                }
            }
            .frame(height: 8)

            // XP text
            Text("\(gamificationService.xpInCurrentLevel)/\(gamificationService.xpForNextLevel - gamificationService.xpForCurrentLevel) XP")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppColors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Level Section

    private var levelSection: some View {
        VStack(spacing: 2) {
            Text("LVL")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(AppColors.textMuted)
                .textCase(.uppercase)

            Text("\(gamificationService.level)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(minWidth: 44, minHeight: 44)
        .background(
            Circle()
                .fill(AppColors.backgroundSecondary)
                .subtleShadow()
        )
    }

    // MARK: - Expanded Stats

    private var expandedStats: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(spacing: 0) {
                // Daily Goal Progress
                dailyGoalStatItem

                Divider()
                    .frame(height: 32)

                // Best streak
                statItem(
                    icon: "flame.fill",
                    value: "\(gamificationService.longestStreak)",
                    label: "Best Streak",
                    color: AppColors.warning
                )

                Divider()
                    .frame(height: 32)

                // Total XP
                statItem(
                    icon: "star.fill",
                    value: formatXP(gamificationService.xp),
                    label: "Total XP",
                    color: Color(hex: "8B5CF6")
                )

                Divider()
                    .frame(height: 32)

                // Freezes
                statItem(
                    icon: "snowflake",
                    value: "\(gamificationService.streakFreezes)",
                    label: "Freezes",
                    color: AppColors.info
                )
            }
            .padding(.horizontal, AppSpacing.pageMargin)
            .padding(.bottom, 12)
        }
        .background(AppColors.background)
    }

    // MARK: - Daily Goal Stat Item

    private var dailyGoalStatItem: some View {
        VStack(spacing: 4) {
            // Icon with checkmark if complete
            ZStack {
                Image(systemName: "target")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(gamificationService.dailyGoalComplete ? AppColors.success : AppColors.warning)

                if gamificationService.dailyGoalComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.success)
                        .offset(x: 8, y: -6)
                }
            }

            // Progress text
            Text("\(gamificationService.dailyXPEarned)/\(gamificationService.dailyGoalXP)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(gamificationService.dailyGoalComplete ? AppColors.success : AppColors.textPrimary)

            Text(gamificationService.dailyGoalComplete ? "Goal Done!" : "Daily Goal")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(gamificationService.dailyGoalComplete ? AppColors.success : AppColors.textMuted)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(AppColors.textMuted)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatXP(_ xp: Int) -> String {
        if xp >= 10000 {
            return String(format: "%.1fk", Double(xp) / 1000)
        } else if xp >= 1000 {
            return "\(xp / 1000).\(xp % 1000 / 100)k"
        }
        return "\(xp)"
    }
}

// MARK: - Compact Version (for smaller spaces)

struct CompactProgressHeader: View {
    @State private var gamificationService = GamificationService.shared

    var body: some View {
        HStack(spacing: 12) {
            // Streak
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(gamificationService.currentStreak > 0 ? AppColors.warning : AppColors.textMuted)

                Text("\(gamificationService.currentStreak)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
            }

            // Divider
            Circle()
                .fill(AppColors.textMuted)
                .frame(width: 3, height: 3)

            // Level + XP
            HStack(spacing: 4) {
                Text("L\(gamificationService.level)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)

                Text("\(gamificationService.xpInCurrentLevel) XP")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textMuted)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AppColors.backgroundSecondary)
        )
    }
}

// MARK: - Progress Header Modifier

struct GlobalProgressHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            GlobalProgressHeader()
            content
        }
    }
}

extension View {
    /// Adds the global progress header above this view
    func withGlobalProgressHeader() -> some View {
        self.modifier(GlobalProgressHeaderModifier())
    }
}

// MARK: - Previews

#Preview("Global Progress Header") {
    VStack {
        GlobalProgressHeader()

        Spacer()

        Text("Content below header")
    }
    .background(AppColors.background)
}

#Preview("Compact Header") {
    VStack {
        CompactProgressHeader()

        Spacer()
    }
    .padding()
    .background(AppColors.background)
}
