import SwiftUI

struct StyleMeScreen: View {
    @Environment(AppCoordinator.self) var coordinator
    @State private var wardrobeService = WardrobeService.shared
    @State private var outfitRepo = OutfitRepository.shared
    @State private var notificationManager = NotificationManager.shared
    @State private var profileService = ProfileService.shared
    @State private var locationService = LocationService.shared
    @State private var usageLimits: UsageLimits?
    @State private var api = StyleumAPI.shared

    /// Check if style quiz is complete
    private var isStyleQuizComplete: Bool {
        return profileService.currentProfile?.styleQuizCompleted == true
    }

    /// Check if user has credits remaining
    private var hasCreditsRemaining: Bool {
        guard let limits = usageLimits else { return true }
        return limits.creditsRemaining > 0
    }

    /// Check if user can generate (has items + credits)
    private var canGenerate: Bool {
        wardrobeService.hasEnoughForOutfits && hasCreditsRemaining && !outfitRepo.isGenerating
    }

    var body: some View {
        Group {
            if isStyleQuizComplete {
                styleMeContent
            } else {
                styleQuizLockedView
            }
        }
        .task {
            locationService.requestPermission()
            await profileService.fetchProfile()
        }
        .onAppear {
            print("🎨 [STYLEME] ========== STYLE ME SCREEN APPEARED ==========")
            print("🎨 [STYLEME] profileService.currentProfile exists: \(profileService.currentProfile != nil)")
            print("🎨 [STYLEME] styleQuizCompleted: \(profileService.currentProfile?.styleQuizCompleted.map { String($0) } ?? "nil")")
            print("🎨 [STYLEME] isStyleQuizComplete: \(isStyleQuizComplete)")
            print("🎨 [STYLEME] Will show: \(isStyleQuizComplete ? "styleMeContent" : "styleQuizLockedView")")
        }
        .onChange(of: profileService.currentProfile?.styleQuizCompleted) { oldValue, newValue in
            print("🎨 [STYLEME] ⚡️ styleQuizCompleted CHANGED: \(oldValue.map { String($0) } ?? "nil") -> \(newValue.map { String($0) } ?? "nil")")
        }
    }

    // MARK: - Weather Display

    @ViewBuilder
    private var weatherDisplay: some View {
        if let weather = outfitRepo.currentWeather {
            HStack(spacing: 6) {
                Image(systemName: weather.weatherSymbol)
                    .font(.system(size: 14, weight: .medium))
                Text("\(Int(weather.tempFahrenheit))° \(weather.condition)")
                if !locationService.locationName.isEmpty {
                    Text("·")
                    Text(locationService.locationName)
                }
            }
            .font(AppTypography.bodySmall)
            .foregroundColor(AppColors.textSecondary)
        } else {
            Text("Checking weather...")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textMuted)
        }
    }

    // MARK: - Locked State

    private var styleQuizLockedView: some View {
        VStack(spacing: 0) {
            // Weather header (top left)
            HStack {
                weatherDisplay
                Spacer()
            }
            .padding(.horizontal, AppSpacing.pageMargin)
            .padding(.top, AppSpacing.md)

            Spacer()

            // Main content
            VStack(spacing: AppSpacing.md) {
                // Subtle hanger icon
                Image(systemName: "hanger")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(AppColors.textMuted.opacity(0.6))
                    .padding(.bottom, AppSpacing.sm)

                VStack(spacing: AppSpacing.xs) {
                    Text("Complete Your")
                        .font(AppTypography.displayLarge)
                        .foregroundColor(AppColors.textPrimary)
                    Text("Style Profile")
                        .font(AppTypography.clashDisplayItalic(32))
                        .foregroundColor(AppColors.textPrimary)
                }

                Text("Take a quick style quiz so we can learn\nyour preferences and create personalized outfits.")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, AppSpacing.xs)

                Button {
                    HapticManager.shared.medium()
                    coordinator.presentFullScreen(.styleQuiz)
                } label: {
                    Text("Start Style Quiz")
                        .font(AppTypography.labelLarge)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppColors.black)
                        .cornerRadius(AppSpacing.radiusMd)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, AppSpacing.lg)
            }
            .padding(.horizontal, AppSpacing.pageMargin)

            Spacer()

            // Daily quote at bottom
            Text("\u{201E}\(StyleQuotes.todaysQuote)\u{201C}")
                .font(.system(size: 14, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(AppColors.textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background)
        .navigationBarHidden(true)
    }

    // MARK: - Main Content

    private var styleMeContent: some View {
        VStack(spacing: 0) {
            // Header with weather top-left, credits top-right
            HStack {
                weatherDisplay

                Spacer()

                // Credits badge (minimal)
                if let limits = usageLimits {
                    Text("\(limits.creditsRemaining)/\(limits.creditsTotal)")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(limits.creditsRemaining > 0 ? AppColors.textMuted : AppColors.danger)
                }
            }
            .padding(.horizontal, AppSpacing.pageMargin)
            .padding(.top, AppSpacing.md)

            // Pre-selected item banner (from "Style this piece" flow)
            if let preSelected = coordinator.preSelectedWardrobeItem {
                PreSelectedItemBanner(item: preSelected) {
                    coordinator.preSelectedWardrobeItem = nil
                }
                .padding(.top, AppSpacing.md)
            }

            Spacer()

            // Main content
            VStack(spacing: AppSpacing.lg) {
                if outfitRepo.isGenerating {
                    GeneratingIndicator()
                        .padding(.bottom, AppSpacing.sm)
                }

                VStack(spacing: AppSpacing.xs) {
                    Text("What should I")
                        .font(AppTypography.displayLarge)
                    Text("wear today?")
                        .font(AppTypography.clashDisplayItalic(32))
                }
                .multilineTextAlignment(.center)

                Text("I'll pick something based on your weather,\nwardrobe, and style.")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: AppSpacing.md) {
                    Button {
                        generateOutfit()
                    } label: {
                        Text(outfitRepo.isGenerating ? "Creating..." : "Style Me")
                            .font(AppTypography.labelLarge)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppColors.black)
                            .cornerRadius(AppSpacing.radiusMd)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(!canGenerate)
                    .opacity(canGenerate ? 1 : 0.5)

                    Button("Customize") {
                        coordinator.present(.customizeStyleMe)
                    }
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.textSecondary)
                }
                .padding(.top, AppSpacing.sm)

                // Helper messages
                if !wardrobeService.hasEnoughForOutfits {
                    Text("Add at least 1 top, 1 bottom, and shoes to get started")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textMuted)
                        .multilineTextAlignment(.center)
                } else if !hasCreditsRemaining {
                    VStack(spacing: AppSpacing.xs) {
                        Text("You've used all 5 free credits this month")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textMuted)

                        Button {
                            coordinator.navigate(to: .subscription)
                        } label: {
                            Text("Upgrade to Pro for 75 monthly generations")
                                .font(AppTypography.labelSmall)
                                .foregroundColor(AppColors.slate)
                                .underline()
                        }
                    }
                    .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, AppSpacing.pageMargin)

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
            await fetchLimits()
        }
    }

    private func fetchLimits() async {
        do {
            usageLimits = try await api.getLimits()
        } catch {
            print("Failed to fetch limits: \(error)")
        }
    }

    private func generateOutfit() {
        HapticManager.shared.medium()

        outfitRepo.generateOutfitsInBackground {
            // Refresh credits after generation
            Task {
                await fetchLimits()
            }

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
        // Classic fashion wisdom
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

        // Confidence and self-expression
        "People will stare. Make it worth their while.",
        "Dress for the life you want.",
        "Create your own style. Let it be unique.",
        "Style is the only thing you can't buy.",
        "When in doubt, wear black.",
        "Clothes mean nothing until someone lives in them.",
        "Fashion is about dressing according to what's fashionable. Style is more about being yourself.",
        "The dress must follow the body, not the body follow the dress.",
        "You can have anything you want in life if you dress for it.",
        "Fashion is what you buy, style is what you do with it.",

        // Timeless advice
        "Buy less, choose well, make it last.",
        "Life is too short to wear boring clothes.",
        "The joy of dressing is an art.",
        "Style is the perfection of a point of view.",
        "The best color in the whole world is the one that looks good on you.",
        "Dress shabbily and they remember the dress; dress impeccably and they remember the woman.",
        "Over the years I have learned that what is important in a dress is the woman who is wearing it.",
        "Fashion is about something that comes from within you.",
        "I don't design clothes. I design dreams.",
        "In difficult times, fashion is always outrageous.",

        // Modern wisdom
        "Style is very personal. It has nothing to do with fashion.",
        "One is never over-dressed or under-dressed with a little black dress.",
        "Give a girl the right shoes, and she can conquer the world.",
        "Fashion is the armor to survive the reality of everyday life.",
        "I firmly believe that with the right footwear one can rule the world.",
        "Trendy is the last stage before tacky.",
        "Playing dress-up begins at age five and never truly ends.",
        "A woman's dress should be like a barbed-wire fence: serving its purpose without obstructing the view.",
        "Fashion is not something that exists in dresses only.",
        "The difference between style and fashion is quality.",

        // Minimalist philosophy
        "Less is more.",
        "Quality over quantity, always.",
        "The perfect outfit doesn't exi— oh wait, there it is.",
        "Well-dressed is a beautiful form of politeness.",
        "Clothes aren't going to change the world. The women who wear them will.",
        "Every day is a fashion show and the world is your runway.",
        "Don't be into trends. Don't make fashion own you.",
        "Luxury is attention to detail, originality, and exclusivity.",
        "Style is something each of us already has. All we need to do is find it.",
        "Fashion is like eating, you shouldn't stick to the same menu."
    ]

    static var todaysQuote: String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % quotes.count
        return quotes[index]
    }
}

// MARK: - Pre-Selected Item Banner

struct PreSelectedItemBanner: View {
    let item: WardrobeItem
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // Thumbnail
            AsyncImage(url: URL(string: item.displayPhotoUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    Rectangle()
                        .fill(AppColors.filterTagBg)
                @unknown default:
                    Rectangle()
                        .fill(AppColors.filterTagBg)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text("Styling with")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.textMuted)
                Text(item.itemName ?? "Item")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                HapticManager.shared.light()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textMuted)
                    .frame(width: 28, height: 28)
                    .background(AppColors.filterTagBg)
                    .clipShape(Circle())
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
        .padding(.horizontal, AppSpacing.pageMargin)
    }
}

#Preview {
    StyleMeScreen()
        .environment(AppCoordinator())
}
