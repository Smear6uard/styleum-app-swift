import SwiftUI

struct AIProcessingOverlay: View {
    @Binding var isVisible: Bool
    var messages: [String] = [
        "Analyzing your wardrobe...",
        "Matching colors and patterns...",
        "Finding perfect pairings...",
        "Checking weather compatibility...",
        "Finalizing your looks..."
    ]

    @State private var currentMessageIndex = 0
    @State private var pulseScale: CGFloat = 0.95
    @State private var rotation: Double = 0
    @State private var messageTimer: Timer?

    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                // Animated icon
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(AppColors.darkSheetTertiary, lineWidth: 3)
                        .frame(width: 80, height: 80)

                    // Spinning arc
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(rotation))

                    // Center icon
                    Image(symbol: .styleMe)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                        .scaleEffect(pulseScale)
                }

                // Rotating message
                Text(messages[currentMessageIndex])
                    .font(AppTypography.bodyLarge)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.3), value: currentMessageIndex)

                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<messages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentMessageIndex ? .white : AppColors.darkSheetTertiary)
                            .frame(width: 6, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: currentMessageIndex)
                    }
                }
            }
            .padding(AppSpacing.xxl)
        }
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            stopAnimations()
        }
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                startAnimations()
            } else {
                stopAnimations()
            }
        }
    }

    private func startAnimations() {
        // Rotation animation
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            rotation = 360
        }

        // Pulse animation
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.05
        }

        // Message rotation - store timer for cleanup
        messageTimer?.invalidate()
        messageTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation {
                currentMessageIndex = (currentMessageIndex + 1) % messages.count
            }
        }
    }

    private func stopAnimations() {
        messageTimer?.invalidate()
        messageTimer = nil
    }
}

// MARK: - Preview
#Preview {
    AIProcessingOverlay(isVisible: .constant(true))
}
