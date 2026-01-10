import SwiftUI

/// Confirmation view shown when user selects "Wear This Outfit"
/// Replaces immediate photo verification with a celebration + delayed reminder
struct WearConfirmationView: View {
    let outfit: ScoredOutfit
    let onConfirm: () -> Void
    let onCancel: () -> Void

    // Animation states
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var glowOpacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Success animation area
            VStack(spacing: 24) {
                // Animated checkmark with glow
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.green.opacity(0.3),
                                    Color.green.opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .opacity(glowOpacity)

                    // Main circle
                    Circle()
                        .fill(Color.green)
                        .frame(width: 80, height: 80)
                        .scaleEffect(checkmarkScale)

                    // Checkmark icon
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(checkmarkScale)
                        .opacity(checkmarkOpacity)
                }

                // Text content
                VStack(spacing: 12) {
                    Text("Great choice!")
                        .font(AppTypography.editorialHeadline)
                        .foregroundColor(AppColors.textPrimary)

                    Text("We'll remind you to snap a photo\nlater for bonus XP")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)

                    // XP preview
                    HStack(spacing: 16) {
                        xpBadge(amount: 10, label: "Base XP", color: AppColors.textPrimary)
                        xpBadge(amount: 15, label: "Photo bonus", color: Color(hex: "D4AF37"))
                    }
                    .padding(.top, 8)
                }
                .opacity(textOpacity)
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button {
                    HapticManager.shared.success()
                    onConfirm()
                } label: {
                    Text("Got it")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.textPrimary)
                        .cornerRadius(12)
                }

                Button {
                    HapticManager.shared.light()
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .opacity(buttonOpacity)
        }
        .background(AppColors.background)
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - XP Badge

    private func xpBadge(amount: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("+\(amount)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(AppColors.textMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(10)
    }

    // MARK: - Animation

    private func startAnimation() {
        HapticManager.shared.success()

        // Phase 1: Checkmark scales in (0-0.4s)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            checkmarkScale = 1
            checkmarkOpacity = 1
        }

        // Phase 2: Glow expands (0.1-0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.5)) {
                glowOpacity = 1
            }
        }

        // Phase 3: Text fades in (0.3-0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.4)) {
                textOpacity = 1
            }
        }

        // Phase 4: Buttons fade in (0.5-0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.35)) {
                buttonOpacity = 1
            }
        }
    }
}

// MARK: - Preview

#Preview {
    WearConfirmationView(
        outfit: ScoredOutfit(
            id: "preview",
            wardrobeItemIds: [],
            score: 85,
            whyItWorks: "Great combination",
            vibe: "Casual"
        ),
        onConfirm: {},
        onCancel: {}
    )
}
