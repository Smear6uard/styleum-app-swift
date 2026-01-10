import SwiftUI

struct EmptyState: View {
    let icon: AppSymbol
    let headline: String
    let description: String
    var ctaLabel: String?
    var ctaAction: (() -> Void)?
    var useLogo: Bool = false

    // Animation state
    @State private var isFloating = false
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Animated illustration area
            ZStack {
                // Subtle gradient background circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppColors.brownPrimary.opacity(0.08),
                                AppColors.brownPrimary.opacity(0.02),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(hasAppeared ? 1 : 0.8)
                    .opacity(hasAppeared ? 1 : 0)

                // Logo or icon
                if useLogo {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .opacity(0.6)
                        .offset(y: isFloating ? -4 : 4)
                } else {
                    Circle()
                        .fill(AppColors.brownPrimary.opacity(0.1))
                        .frame(width: 88, height: 88)
                        .overlay(
                            Image(symbol: icon)
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(AppColors.brownPrimary)
                        )
                        .offset(y: isFloating ? -4 : 4)
                }
            }
            .animation(
                .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                value: isFloating
            )
            .onAppear {
                isFloating = true
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    hasAppeared = true
                }
            }

            // Text content with editorial styling
            VStack(spacing: AppSpacing.sm) {
                Text(headline)
                    .font(AppTypography.editorialSubhead)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 10)

                Text(description)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 8)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: hasAppeared)

            // CTA button with brown accent
            if let ctaLabel = ctaLabel, let ctaAction = ctaAction {
                Button(action: {
                    HapticManager.shared.medium()
                    ctaAction()
                }) {
                    Text(ctaLabel)
                        .font(AppTypography.labelLarge)
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(AppColors.brownPrimary)
                        .cornerRadius(AppSpacing.radiusMd)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, AppSpacing.sm)
                .opacity(hasAppeared ? 1 : 0)
                .scaleEffect(hasAppeared ? 1 : 0.9)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: hasAppeared)
            }
        }
        .padding(AppSpacing.xl)
    }
}

// MARK: - Preset Empty States

extension EmptyState {
    /// Empty wardrobe state with editorial copy
    static func wardrobe(onAdd: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: .wardrobe,
            headline: "Your closet awaits",
            description: "Start building your digital wardrobe. Add your favorite pieces to get personalized outfit suggestions.",
            ctaLabel: "Add First Piece",
            ctaAction: onAdd,
            useLogo: true
        )
    }

    /// No outfits generated yet
    static func outfits(onGenerate: @escaping () -> Void) -> EmptyState {
        EmptyState(
            icon: .styleMe,
            headline: "No looks yet",
            description: "Let's change that. Generate your first outfit and discover new ways to wear what you own.",
            ctaLabel: "Style Me",
            ctaAction: onGenerate
        )
    }

    /// No achievements unlocked
    static func achievements() -> EmptyState {
        EmptyState(
            icon: .achievements,
            headline: "Your journey begins",
            description: "Complete challenges and unlock achievements as you build your style.",
            useLogo: true
        )
    }

    /// Search returned no results
    static func searchEmpty(query: String) -> EmptyState {
        EmptyState(
            icon: .search,
            headline: "Nothing found",
            description: "No items match \"\(query)\". Try adjusting your search.",
            useLogo: false
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        EmptyState.wardrobe(onAdd: {})

        EmptyState(
            icon: .wardrobe,
            headline: "Your closet is empty",
            description: "Add items to your wardrobe to start getting personalized outfit suggestions.",
            ctaLabel: "Add First Item",
            ctaAction: {}
        )
    }
}
