import SwiftUI

struct StyleMeScreen: View {
    @Environment(AppCoordinator.self) var coordinator
    @State private var wardrobeService = WardrobeService.shared
    @State private var outfitRepo = OutfitRepository.shared
    @State private var notificationManager = NotificationManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header with weather top-left
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sun.max")
                        .font(.system(size: 14, weight: .medium))
                    Text("72° Sunny")
                    Text("·")
                    Text("San Francisco")
                }
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)

                Spacer()

                Button("Change") {
                    // Change location
                }
                .font(AppTypography.labelSmall)
                .foregroundColor(AppColors.slate)
            }
            .padding(.horizontal, AppSpacing.pageMargin)
            .padding(.top, AppSpacing.md)

            Spacer()

            // Main content
            VStack(spacing: AppSpacing.lg) {
                if outfitRepo.isGenerating {
                    GeneratingIndicator()
                        .padding(.bottom, AppSpacing.md)
                }

                Text("What should I\nwear today?")
                    .font(AppTypography.displayLarge)
                    .multilineTextAlignment(.center)

                Text("I'll pick something based on your weather,\nwardrobe, and style.")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: AppSpacing.sm) {
                    Button {
                        generateOutfit()
                    } label: {
                        Text(outfitRepo.isGenerating ? "Creating..." : "Style Me")
                            .font(AppTypography.labelLarge)
                            .foregroundColor(.white)
                            .frame(width: 200)
                            .frame(height: 50)
                            .background(AppColors.black)
                            .cornerRadius(AppSpacing.radiusMd)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(!wardrobeService.hasEnoughForOutfits || outfitRepo.isGenerating)
                    .opacity(wardrobeService.hasEnoughForOutfits && !outfitRepo.isGenerating ? 1 : 0.5)

                    Button("Customize") {
                        coordinator.present(.customizeStyleMe)
                    }
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.textSecondary)
                }
                .padding(.top, AppSpacing.md)

                if !wardrobeService.hasEnoughForOutfits {
                    Text("Add at least 1 top, 1 bottom, and shoes to get started")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.top, AppSpacing.sm)
                }
            }
            .padding(.horizontal, AppSpacing.xl)

            Spacer()

            // Daily quote at bottom
            VStack(spacing: 4) {
                Text("\u{201E}\(StyleQuotes.todaysQuote)\u{201C}")
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(AppColors.textMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background)
        .navigationBarHidden(true)
        .task {
            await wardrobeService.fetchItems()
        }
    }

    private func generateOutfit() {
        HapticManager.shared.medium()

        outfitRepo.generateOutfitsInBackground {
            if !outfitRepo.todaysOutfits.isEmpty {
                notificationManager.show(
                    .outfitReady {
                        coordinator.presentFullScreen(.outfitResults)
                    }
                )
            }
        }
    }
}

enum StyleQuotes {
    static let quotes = [
        "The best style is the one you don't notice.",
        "Dress like you're already famous.",
        "Style is a way to say who you are without speaking.",
        "Fashion fades, style is eternal.",
        "Elegance is elimination.",
        "Simplicity is the keynote of all true elegance.",
        "What you wear is how you present yourself to the world.",
        "Style is knowing who you are.",
        "Buy less, choose well, make it last.",
        "Dress for the life you want.",
        "Fashion is instant language.",
        "Style is the perfection of a point of view.",
        "The joy of dressing is an art.",
        "Create your own style. Let it be unique.",
        "When in doubt, wear black.",
        "People will stare. Make it worth their while.",
        "Fashion is what you buy, style is what you do with it.",
        "Life is too short to wear boring clothes.",
        "Style is the only thing you can't buy.",
        "The best color in the whole world is the one that looks good on you."
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
