import SwiftUI

/// Celebratory toast/mini-modal when user completes their daily XP goal.
/// Triggered via NotificationCenter when GamificationService detects goal completion.
struct DailyGoalCelebrationView: View {
    @Binding var isPresented: Bool

    // Animation states
    @State private var iconScale: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    private let accentColor = Color(hex: "10B981")  // Emerald green

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Celebration card
            VStack(spacing: 20) {
                // Checkmark icon with glow
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .blur(radius: 10)

                    Circle()
                        .fill(accentColor)
                        .frame(width: 72, height: 72)

                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(iconScale)

                // Text content
                VStack(spacing: 8) {
                    Text("DAILY GOAL")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)
                        .foregroundColor(accentColor)

                    Text("Complete!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("You've hit your XP goal for today.\nKeep the momentum going!")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .opacity(textOpacity)

                // Continue button
                Button {
                    dismiss()
                } label: {
                    Text("Keep Going")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.black)
                        .frame(width: 180)
                        .padding(.vertical, 14)
                        .background(accentColor)
                        .cornerRadius(AppSpacing.radiusMd)
                }
                .opacity(buttonOpacity)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1F1F1F"))
            )
            .padding(.horizontal, 40)
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        HapticManager.shared.success()

        // Icon scales in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            iconScale = 1
        }

        // Text fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                textOpacity = 1
            }
        }

        // Button appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.3)) {
                buttonOpacity = 1
            }
        }
    }

    private func dismiss() {
        HapticManager.shared.light()
        withAnimation(.easeOut(duration: 0.2)) {
            isPresented = false
        }
    }
}

// MARK: - View Modifier

struct DailyGoalCelebrationModifier: ViewModifier {
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .dailyGoalComplete)) { _ in
                isPresented = true
            }
            .fullScreenCover(isPresented: $isPresented) {
                DailyGoalCelebrationView(isPresented: $isPresented)
                    .background(Color.clear)
            }
    }
}

extension View {
    /// Adds daily goal celebration overlay triggered by notification
    func dailyGoalCelebration() -> some View {
        self.modifier(DailyGoalCelebrationModifier())
    }
}

// MARK: - Preview

#Preview {
    DailyGoalCelebrationView(isPresented: .constant(true))
}
