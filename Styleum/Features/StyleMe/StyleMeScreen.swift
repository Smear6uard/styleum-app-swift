import SwiftUI

struct StyleMeScreen: View {
    @Environment(AppCoordinator.self) var coordinator
    @State private var wardrobeService = WardrobeService.shared
    @State private var outfitRepo = OutfitRepository.shared
    @State private var api = StyleumAPI.shared
    @State private var usageLimits: UsageLimits?

    // Progress bar state
    @State private var generationProgress: CGFloat = 0
    @State private var progressTimer: Timer?

    var body: some View {
        ZStack {
            // Background: Neutral editorial gradient
            editorialGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar at top (only during generation)
                if outfitRepo.isGenerating {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(AppColors.textPrimary)
                            .frame(width: geo.size.width * generationProgress, height: 2)
                            .animation(.linear(duration: 0.1), value: generationProgress)
                    }
                    .frame(height: 2)
                } else {
                    Color.clear.frame(height: 2)
                }

                Spacer()

                // Core content - centered, confident
                VStack(spacing: 24) {
                    // Weather context - subtle, integrated
                    if let weather = outfitRepo.currentWeather ?? outfitRepo.preGeneratedWeather {
                        Text("\(Int(weather.tempFahrenheit))° and \(weather.condition.lowercased())")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    // Main headline - clear, confident
                    VStack(spacing: 8) {
                        Text("What should I")
                            .font(.system(size: 32, weight: .light, design: .serif))
                        Text("wear today?")
                            .font(.system(size: 32, weight: .light, design: .serif))
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                }

                Spacer()

                // CTA area
                VStack(spacing: 16) {
                    // Primary button - confident, not heavy
                    Button {
                        generateOutfit()
                    } label: {
                        Text(outfitRepo.isGenerating ? "Styling..." : "Style Me")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.textPrimary)
                            .cornerRadius(12)
                    }
                    .disabled(outfitRepo.isGenerating)
                    .opacity(outfitRepo.isGenerating ? 0.7 : 1)
                    .padding(.horizontal, 24)

                    // Customize - secondary, subtle
                    Button {
                        coordinator.present(.customizeStyleMe)
                    } label: {
                        Text("Customize")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .disabled(outfitRepo.isGenerating)
                }
                .padding(.bottom, 50)
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
            await wardrobeService.fetchItems()
            await fetchLimits()
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

    // MARK: - Actions

    private func generateOutfit() {
        HapticManager.shared.medium()

        Task {
            await outfitRepo.generateFreshOutfits(preferences: nil)

            // Refresh credits after generation
            await fetchLimits()

            if !outfitRepo.sessionOutfits.isEmpty {
                coordinator.presentFullScreen(.outfitResults)
            }
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
