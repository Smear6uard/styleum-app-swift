import SwiftUI

/// A celebratory modal view shown when an achievement is unlocked.
/// Listens for `Notification.Name.achievementUnlocked` and presents itself.
struct AchievementCelebrationOverlay: View {
    @State private var unlockedAchievement: UnlockedAchievement?
    @State private var isPresented = false
    @State private var animationPhase = 0

    var body: some View {
        ZStack {
            if isPresented, let achievement = unlockedAchievement {
                // Dimmed background
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }

                // Celebration card
                VStack(spacing: AppSpacing.lg) {
                    // Icon with animation
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(rarityColor(achievement.rarity).opacity(0.3))
                            .frame(width: 120, height: 120)
                            .blur(radius: animationPhase > 0 ? 20 : 0)
                            .scaleEffect(animationPhase > 0 ? 1.2 : 0.8)

                        Circle()
                            .fill(AppColors.black)
                            .frame(width: 80, height: 80)
                            .shadow(color: rarityColor(achievement.rarity).opacity(0.5), radius: 20)

                        Image(systemName: achievement.iconName)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.white)
                            .scaleEffect(animationPhase > 1 ? 1.0 : 0.5)
                    }
                    .scaleEffect(animationPhase > 0 ? 1.0 : 0.3)

                    // Title
                    VStack(spacing: AppSpacing.xs) {
                        Text("ACHIEVEMENT UNLOCKED")
                            .font(AppTypography.kicker)
                            .foregroundColor(AppColors.textMuted)
                            .tracking(1)

                        Text(achievement.title)
                            .font(AppTypography.headingMedium)
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(animationPhase > 1 ? 1.0 : 0.0)

                    // Description
                    Text(achievement.description)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(animationPhase > 1 ? 1.0 : 0.0)

                    // Rarity badge
                    Text(achievement.rarity.uppercased())
                        .font(AppTypography.labelSmall)
                        .foregroundColor(rarityColor(achievement.rarity))
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(rarityColor(achievement.rarity).opacity(0.15))
                        .cornerRadius(AppSpacing.radiusSm)
                        .opacity(animationPhase > 1 ? 1.0 : 0.0)

                    // XP reward
                    if achievement.xpReward > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                            Text("+\(achievement.xpReward) XP")
                                .font(AppTypography.labelMedium)
                        }
                        .foregroundColor(Color(hex: "F59E0B"))
                        .opacity(animationPhase > 2 ? 1.0 : 0.0)
                    }

                    // Dismiss button
                    Button {
                        dismiss()
                    } label: {
                        Text("Awesome!")
                            .font(AppTypography.labelLarge)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppColors.black)
                            .cornerRadius(AppSpacing.radiusMd)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .opacity(animationPhase > 2 ? 1.0 : 0.0)
                    .padding(.top, AppSpacing.sm)
                }
                .padding(AppSpacing.xl)
                .background(AppColors.background)
                .cornerRadius(AppSpacing.radiusXl)
                .shadow(color: .black.opacity(0.3), radius: 30, y: 10)
                .padding(.horizontal, AppSpacing.xl)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isPresented)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: animationPhase)
        .onReceive(NotificationCenter.default.publisher(for: .achievementUnlocked)) { notification in
            if let achievement = notification.object as? UnlockedAchievement {
                show(achievement)
            }
        }
    }

    private func show(_ achievement: UnlockedAchievement) {
        unlockedAchievement = achievement
        isPresented = true
        animationPhase = 0

        // Haptic feedback
        HapticManager.shared.achievementUnlock()

        // Staggered animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animationPhase = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animationPhase = 2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animationPhase = 3
        }
    }

    private func dismiss() {
        withAnimation {
            isPresented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            unlockedAchievement = nil
            animationPhase = 0
        }
    }

    private func rarityColor(_ rarity: String) -> Color {
        switch rarity.lowercased() {
        case "common": return Color(hex: "9CA3AF")
        case "uncommon": return Color(hex: "10B981")
        case "rare": return Color(hex: "3B82F6")
        case "epic": return Color(hex: "8B5CF6")
        case "legendary": return Color(hex: "F59E0B")
        default: return Color(hex: "9CA3AF")
        }
    }
}

// MARK: - View Modifier for easy use

extension View {
    func achievementCelebration() -> some View {
        ZStack {
            self
            AchievementCelebrationOverlay()
        }
    }
}

#Preview {
    VStack {
        Text("Main Content")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.background)
    .achievementCelebration()
    .onAppear {
        // Simulate unlock after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let mockAchievement = UnlockedAchievement(
                id: "wardrobe_first",
                title: "First Thread",
                description: "Add your first item to your wardrobe",
                rarity: "common",
                iconName: "tshirt",
                xpReward: 10
            )
            NotificationCenter.default.post(
                name: .achievementUnlocked,
                object: mockAchievement
            )
        }
    }
}
