import SwiftUI

struct StyleMeScreen: View {
    @Environment(AppCoordinator.self) var coordinator
    @State private var wardrobeService = WardrobeService.shared
    @State private var outfitRepo = OutfitRepository.shared
    @State private var api = StyleumAPI.shared
    @State private var tierManager = TierManager.shared
    @State private var usageLimits: UsageLimits?

    // Progress bar state
    @State private var generationProgress: CGFloat = 0
    @State private var progressTimer: Timer?

    // Animation state
    @State private var hasAppeared = false

    // Paywall state
    @State private var showCreditsExhausted = false

    // Entrance ceremony state
    @State private var showEntranceCeremony = false
    @State private var entranceCeremonyComplete = false

    // MARK: - Computed State Properties

    private var isLoading: Bool { outfitRepo.isGenerating }
    private var hasError: Bool { outfitRepo.error != nil }
    private var hasOutfits: Bool { !outfitRepo.sessionOutfits.isEmpty }

    private var isRateLimited: Bool {
        if let error = outfitRepo.error as? APIError,
           case .rateLimited = error {
            return true
        }
        return false
    }

    var body: some View {
        ZStack {
            // Background: Neutral editorial gradient
            editorialGradient
                .ignoresSafeArea()

            // State-based content
            if isLoading {
                // Show skeleton loading state while generating
                StyleMeSkeletonView()
            } else if isRateLimited {
                // Show rate limit specific view with upgrade option
                StyleMeRateLimitedView(error: outfitRepo.error as? APIError) {
                    generateOutfit()
                } onUpgrade: {
                    coordinator.navigate(to: .subscription)
                }
            } else if hasError {
                // Show error state with retry
                StyleMeErrorView(error: outfitRepo.error) {
                    generateOutfit()
                }
            } else if hasOutfits {
                // Show results inline - no popup
                // Note: OutfitResultsView is shown inline, not as fullScreenCover
                OutfitResultsView(isInlineMode: true)
            } else {
                // Default: show "Style Me" content
                defaultStyleMeContent
            }
        }
        .navigationBarHidden(true)
        .onChange(of: outfitRepo.isGenerating) { _, isGenerating in
            if isGenerating {
                startProgress()
            } else {
                stopProgress()
            }
        }
        .task {
            await tierManager.refresh()
            await wardrobeService.fetchItems()
            await fetchLimits()
        }
        .onAppear {
            withAnimation {
                hasAppeared = true
            }
        }
        .fullScreenCover(isPresented: $showEntranceCeremony) {
            StyleMeEntranceCeremony(isComplete: $entranceCeremonyComplete)
                .onChange(of: entranceCeremonyComplete) { _, complete in
                    if complete {
                        showEntranceCeremony = false
                        startActualGeneration()
                    }
                }
        }
        .sheet(isPresented: $showCreditsExhausted) {
            if let usage = tierManager.tierInfo?.usage {
                CreditsExhaustedView(
                    creditsUsed: usage.styleCreditsUsed,
                    creditsLimit: usage.styleCreditsLimit,
                    daysUntilReset: usage.daysUntilReset,
                    onUpgrade: {
                        coordinator.navigate(to: .subscription)
                    }
                )
                .presentationDetents([.medium])
            } else {
                // Fallback if tierInfo not loaded (shouldn't happen with guard above)
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading...")
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    print("[StyleMe] Sheet opened with nil tierInfo - dismissing")
                    showCreditsExhausted = false
                }
            }
        }
    }

    // MARK: - Time-Based Greeting

    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<21:
            return "Good evening"
        default:
            return "Good night"
        }
    }

    // MARK: - Editorial Gradient

    private var editorialGradient: some View {
        // Warm stone → off-white (COS/Totême aesthetic)
        LinearGradient(
            colors: [
                Color(hex: "E8E4DF"),  // Warm stone at top
                Color(hex: "F5F3F0"),  // Transition
                Color(hex: "FAFAF8")   // Near-white at bottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Default Style Me Content

    private var defaultStyleMeContent: some View {
        VStack(spacing: 0) {
            Spacer()

            // Core content - centered, confident
            VStack(spacing: 20) {
                // Time-based greeting
                Text(timeBasedGreeting)
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .kerning(0.5)

                // Weather context - subtle, integrated
                if let weather = outfitRepo.currentWeather ?? outfitRepo.preGeneratedWeather {
                    Text("\(Int(weather.tempFahrenheit))° and \(weather.condition.lowercased())")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textMuted)
                }

                // Main headline - clear, confident
                VStack(spacing: 6) {
                    Text("What should I")
                        .font(AppTypography.editorialHero)
                    Text("wear today?")
                        .font(AppTypography.editorialHero)
                }
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 10)
            .animation(.easeOut(duration: 0.5), value: hasAppeared)

            Spacer()

            // CTA area
            VStack(spacing: 16) {
                // Primary button - confident, not heavy
                Button {
                    generateOutfit()
                } label: {
                    Text("Style Me")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.textPrimary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)

                // Customize - secondary, subtle
                Button {
                    HapticManager.shared.light()
                    coordinator.present(.customizeStyleMe)
                } label: {
                    Text("Customize")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.bottom, 50)
        }
    }

    // MARK: - Actions

    private func generateOutfit() {
        print("[StyleMe] Generate button tapped")
        print("[StyleMe] tierInfo: \(String(describing: tierManager.tierInfo))")
        print("[StyleMe] isPro: \(tierManager.isPro), creditsRemaining: \(tierManager.styleCreditsRemaining)")
        HapticManager.shared.medium()

        // Don't check credits if tier info hasn't loaded yet
        // Backend will validate credits anyway
        if tierManager.tierInfo != nil {
            // Check if user has credits remaining (free tier only)
            if !tierManager.isPro && tierManager.styleCreditsRemaining <= 0 {
                showCreditsExhausted = true
                return
            }
        }

        // Show entrance ceremony first (ritual moment)
        entranceCeremonyComplete = false
        showEntranceCeremony = true
    }

    /// Called after entrance ceremony completes - starts the actual generation
    private func startActualGeneration() {
        // Clear previous outfits so hasOutfits is false during generation
        // This ensures skeleton shows instead of previous results
        outfitRepo.clearSessionOutfits()

        // Ensure any lingering fullScreenCover is dismissed
        if coordinator.activeFullScreen == .outfitResults {
            coordinator.dismissFullScreen()
        }

        // Start background generation - skeleton will show automatically via isLoading
        print("[StyleMe] Starting background generation...")
        Task {
            await outfitRepo.generateFreshOutfits(preferences: nil)

            // Update credits after generation completes
            tierManager.decrementStyleCredits()
            await tierManager.refresh()
            await fetchLimits()

            print("[StyleMe] Generation complete. Outfits: \(outfitRepo.sessionOutfits.count)")
            // Results will show inline automatically via hasOutfits state
        }
    }

    private func fetchLimits() async {
        do {
            usageLimits = try await api.getLimits()
        } catch {
            print("Failed to fetch limits: \(error)")
        }
    }

    // MARK: - Progress Animation

    private func startProgress() {
        generationProgress = 0
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            if generationProgress < 0.9 {
                generationProgress += (0.9 - generationProgress) * 0.04
            }
        }
    }

    private func stopProgress() {
        progressTimer?.invalidate()
        progressTimer = nil
        withAnimation(.easeOut(duration: 0.15)) {
            generationProgress = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            generationProgress = 0
        }
    }
}

// MARK: - Style Quotes

enum StyleQuotes {
    static let quotes = [
        "Style is a way to say who you are without speaking.",
        "Fashion fades, style is eternal.",
        "Elegance is the only beauty that never fades.",
        "What you wear is how you present yourself to the world.",
        "Dress like you're already there.",
        "Simplicity is the keynote of all true elegance.",
        "The best style is the one you don't notice.",
        "Style is knowing who you are.",
        "Elegance is elimination.",
        "Fashion is instant language.",
        "People will stare. Make it worth their while.",
        "Dress for the life you want.",
        "Create your own style. Let it be unique.",
        "Style is the only thing you can't buy.",
        "When in doubt, wear black.",
        "Clothes mean nothing until someone lives in them.",
        "Buy less, choose well, make it last.",
        "Life is too short to wear boring clothes.",
        "The joy of dressing is an art.",
        "Style is the perfection of a point of view.",
        "Less is more.",
        "Quality over quantity, always."
    ]

    static var todaysQuote: String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % quotes.count
        return quotes[index]
    }
}

#Preview {
    StyleMeScreen()
        .environment(AppCoordinator())
}
