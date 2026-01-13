import SwiftUI

struct StyleMeSkeletonView: View {
    // Animation states
    @State private var logoOpacity: Double = 0.4
    @State private var logoScale: CGFloat = 1.0
    @State private var currentPhase: GenerationPhase = .analyzing
    @State private var phaseTimer: Timer?
    @State private var dotTimer: Timer?
    @State private var dotIndex: Int = 0

    // Generation phases with contextual messaging
    enum GenerationPhase: CaseIterable {
        case analyzing
        case matching
        case styling
        case finalizing

        var message: String {
            switch self {
            case .analyzing: return "Analyzing your wardrobe"
            case .matching: return "Finding perfect combinations"
            case .styling: return "Adding finishing touches"
            case .finalizing: return "Almost ready"
            }
        }

        var duration: Double {
            switch self {
            case .analyzing: return 2.0
            case .matching: return 3.0
            case .styling: return 2.5
            case .finalizing: return 2.0
            }
        }

        var next: GenerationPhase {
            switch self {
            case .analyzing: return .matching
            case .matching: return .styling
            case .styling: return .finalizing
            case .finalizing: return .finalizing // Stay on last phase
            }
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()

                // Skeleton outfit card
                VStack(spacing: 20) {
                    // Main outfit image skeleton
                    SkeletonRect(height: 280)
                        .cornerRadius(AppSpacing.radiusLg)

                    // Item thumbnails row skeleton
                    HStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonRect(width: 64, height: 64)
                                .cornerRadius(AppSpacing.radiusSm)
                        }
                    }

                    // Text skeletons
                    VStack(spacing: 10) {
                        SkeletonRect(width: 220, height: 22)
                            .cornerRadius(AppSpacing.radiusTiny)
                        SkeletonRect(width: 160, height: 16)
                            .cornerRadius(AppSpacing.radiusTiny)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Loading message at bottom with logo and phase-based messaging
                VStack(spacing: 20) {
                    // Breathing logo with scale pulse
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .opacity(logoOpacity)
                        .scaleEffect(logoScale)

                    // Phase-based message with animated dots
                    VStack(spacing: 8) {
                        HStack(spacing: 2) {
                            Text(currentPhase.message)
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textPrimary)
                                .contentTransition(.numericText())

                            // Animated dots
                            HStack(spacing: 3) {
                                ForEach(0..<3, id: \.self) { index in
                                    Circle()
                                        .fill(AppColors.textSecondary)
                                        .frame(width: 4, height: 4)
                                        .opacity(dotIndex >= index ? 1.0 : 0.3)
                                }
                            }
                            .padding(.leading, 2)
                        }

                        // Progress indicator
                        progressIndicator
                    }
                }
                .padding(.bottom, 60)
            }

            // Subtle watermark in bottom-right corner
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .opacity(0.1)
                        .padding(AppSpacing.pageMargin)
                }
            }
        }
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            stopAnimations()
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(GenerationPhase.allCases, id: \.self) { phase in
                Capsule()
                    .fill(phaseColor(for: phase))
                    .frame(width: isCurrentPhase(phase) ? 24 : 8, height: 4)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPhase)
            }
        }
    }

    private func phaseColor(for phase: GenerationPhase) -> Color {
        let phases = GenerationPhase.allCases
        guard let currentIndex = phases.firstIndex(of: currentPhase),
              let phaseIndex = phases.firstIndex(of: phase) else {
            return AppColors.fill
        }

        if phaseIndex < currentIndex {
            return AppColors.textPrimary  // Completed
        } else if phaseIndex == currentIndex {
            return AppColors.textPrimary  // Current
        } else {
            return AppColors.fill.opacity(0.5)  // Upcoming
        }
    }

    private func isCurrentPhase(_ phase: GenerationPhase) -> Bool {
        phase == currentPhase
    }

    // MARK: - Animations

    private func startAnimations() {
        // Logo breathing animation
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            logoOpacity = 0.8
            logoScale = 1.03
        }

        // Dot animation (cycles 0, 1, 2, 0, 1, 2...)
        dotTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                dotIndex = (dotIndex + 1) % 4
            }
        }

        // Phase progression
        scheduleNextPhase()
    }

    private func scheduleNextPhase() {
        let delay = currentPhase.duration
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
            let nextPhase = currentPhase.next
            if nextPhase != currentPhase {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPhase = nextPhase
                }
                HapticManager.shared.soft()
                scheduleNextPhase()
            }
        }
    }

    private func stopAnimations() {
        phaseTimer?.invalidate()
        phaseTimer = nil
        dotTimer?.invalidate()
        dotTimer = nil
    }
}

// MARK: - Skeleton Rectangle

struct SkeletonRect: View {
    var width: CGFloat? = nil
    let height: CGFloat

    @State private var isAnimating = false

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        AppColors.fill.opacity(isAnimating ? 0.3 : 0.5),
                        AppColors.fill.opacity(isAnimating ? 0.5 : 0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .animation(
                .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    ZStack {
        // Same background as StyleMeScreen
        LinearGradient(
            colors: [
                Color(hex: "E8E4DF"),
                Color(hex: "F5F3F0"),
                Color(hex: "FAFAF8")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        StyleMeSkeletonView()
    }
}
