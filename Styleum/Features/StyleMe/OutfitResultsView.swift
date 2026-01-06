import SwiftUI

struct OutfitResultsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppCoordinator.self) private var coordinator
    @State private var wardrobeService = WardrobeService.shared
    @State private var outfitRepo = OutfitRepository.shared
    @State private var shareService = ShareService.shared

    @State private var currentIndex = 0
    @State private var isSaved = false
    @State private var showingRefinement = false
    @State private var isRegenerating = false

    // New state for enhanced features
    @State private var showVerifySheet = false
    @State private var showRegenerateSheet = false
    @State private var showXPToast = false
    @State private var xpAmount = 0
    @State private var isXPBonus = false
    @State private var tapScale: CGFloat = 1.0

    private var currentOutfit: ScoredOutfit? {
        guard currentIndex < outfitRepo.todaysOutfits.count else { return nil }
        return outfitRepo.todaysOutfits[currentIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    HapticManager.shared.light()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                if !outfitRepo.todaysOutfits.isEmpty {
                    Text("\(currentIndex + 1) of \(outfitRepo.todaysOutfits.count)")
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                // Share button
                Button {
                    shareOutfit()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .disabled(shareService.isSharing)

                // Save button
                Button {
                    HapticManager.shared.medium()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isSaved.toggle()
                    }
                } label: {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSaved ? AppColors.danger : AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, AppSpacing.sm)

            if let outfit = currentOutfit {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // AI Headline
                        VStack(spacing: AppSpacing.xs) {
                            Text(outfit.aiHeadline)
                                .font(AppTypography.headingMedium)
                                .foregroundColor(AppColors.textPrimary)
                                .multilineTextAlignment(.center)

                            // Weather context
                            HStack(spacing: 6) {
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                                Text("Perfect for 72°F and sunny")
                                    .font(AppTypography.bodySmall)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)

                        // Outfit Grid: 1 large + 3 small with tap navigation
                        OutfitGridView(
                            itemIds: outfit.wardrobeItemIds,
                            items: wardrobeService.items
                        )
                        .scaleEffect(tapScale)
                        .padding(.horizontal, AppSpacing.pageMargin)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            handleTapNavigation(at: location)
                        }

                        // Why it works
                        if !outfit.whyItWorks.isEmpty {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text("WHY IT WORKS")
                                    .font(AppTypography.kicker)
                                    .foregroundColor(AppColors.textMuted)
                                    .tracking(1)

                                Text(outfit.whyItWorks)
                                    .font(AppTypography.bodyMedium)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AppSpacing.pageMargin)
                        }

                        // Regenerate button (opens sheet)
                        Button {
                            HapticManager.shared.light()
                            showRegenerateSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Try a different look")
                                    .font(AppTypography.labelMedium)
                            }
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.filterTagBg)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, AppSpacing.pageMargin)
                    }
                    .padding(.vertical, AppSpacing.md)
                }

                // Bottom actions
                VStack(spacing: AppSpacing.sm) {
                    // Main action buttons
                    HStack(spacing: AppSpacing.sm) {
                        // Dislike button
                        Button {
                            HapticManager.shared.warning()
                            skipToNext()
                        } label: {
                            Image(systemName: "hand.thumbsdown")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                                .frame(width: 56, height: 56)
                                .background(AppColors.filterTagBg)
                                .clipShape(Circle())
                        }

                        // Skip button
                        Button {
                            HapticManager.shared.light()
                            skipToNext()
                        } label: {
                            Text("Skip")
                                .font(AppTypography.labelMedium)
                                .foregroundColor(AppColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(AppColors.filterTagBg)
                                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                        }

                        // Wear button - opens verify sheet
                        Button {
                            HapticManager.shared.medium()
                            showVerifySheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Wear This")
                                    .font(AppTypography.labelMedium)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppColors.black)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                        }
                    }
                }
                .padding(AppSpacing.pageMargin)
                .background(
                    Rectangle()
                        .fill(AppColors.background)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -4)
                )
            } else {
                // Empty state
                Spacer()
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(AppColors.textMuted)

                    Text("No outfits generated yet")
                        .font(AppTypography.titleMedium)
                        .foregroundColor(AppColors.textPrimary)

                    Text("Go back and tap Style Me to generate outfits")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(AppSpacing.xl)
                Spacer()
            }
        }
        .background(AppColors.background)
        .overlay(alignment: .top) {
            if showXPToast {
                XPToast(amount: xpAmount, isBonus: isXPBonus, isShowing: $showXPToast)
                    .padding(.top, 60)
            }
        }
        .sheet(isPresented: $showVerifySheet) {
            if let outfit = currentOutfit {
                VerifyOutfitSheet(
                    outfit: outfit,
                    onVerify: { image in
                        handleVerifiedWear(image: image)
                    },
                    onSkip: {
                        handleUnverifiedWear()
                    }
                )
            }
        }
        .sheet(isPresented: $showRegenerateSheet) {
            if let outfit = currentOutfit {
                RegenerateSheet(
                    currentOutfit: outfit,
                    isPro: false, // TODO: Wire up actual Pro status check
                    onRegenerate: { feedback in
                        regenerateOutfit(with: feedback)
                    },
                    onUpgrade: {
                        coordinator.navigate(to: .subscription)
                    }
                )
            }
        }
    }

    // MARK: - Tap Navigation

    private func handleTapNavigation(at location: CGPoint) {
        let screenWidth = UIScreen.main.bounds.width
        let tapX = location.x

        // Left 40% = previous, Right 60% = next
        let threshold = screenWidth * 0.4

        if tapX < threshold {
            goToPrevious()
        } else {
            goToNext()
        }
    }

    private func goToPrevious() {
        guard currentIndex > 0 else { return }
        HapticManager.shared.selection()
        animateTap {
            currentIndex -= 1
            isSaved = false
        }
    }

    private func goToNext() {
        guard currentIndex < outfitRepo.todaysOutfits.count - 1 else { return }
        HapticManager.shared.selection()
        animateTap {
            currentIndex += 1
            isSaved = false
        }
    }

    private func animateTap(_ action: @escaping () -> Void) {
        withAnimation(.easeInOut(duration: 0.1)) {
            tapScale = 0.97
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
                tapScale = 1.0
            }
        }
    }

    // MARK: - Wear Actions

    private func handleVerifiedWear(image: UIImage) {
        guard let outfit = currentOutfit else { return }

        Task {
            // Upload image and mark as worn
            // For now, we'll just mark as worn without the photo URL
            // In production, upload image first then pass URL
            try? await outfitRepo.markAsWorn(outfit, photoUrl: nil)

            await MainActor.run {
                // Show 2x XP toast
                xpAmount = 50
                isXPBonus = true
                showXPToast = true

                // Dismiss after toast
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    dismiss()
                }
            }
        }
    }

    private func handleUnverifiedWear() {
        guard let outfit = currentOutfit else { return }

        Task {
            try? await outfitRepo.markAsWorn(outfit)

            await MainActor.run {
                // Show 1x XP toast
                xpAmount = 25
                isXPBonus = false
                showXPToast = true

                // Dismiss after toast
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    dismiss()
                }
            }
        }
    }

    private func skipToNext() {
        if currentIndex < outfitRepo.todaysOutfits.count - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentIndex += 1
                isSaved = false
            }
        }
    }

    private func regenerateOutfit(with feedback: FeedbackType) {
        guard let outfit = currentOutfit else { return }

        isRegenerating = true
        HapticManager.shared.medium()

        Task {
            // Regenerate with feedback (learning is handled by API)
            if let newOutfit = await outfitRepo.regenerateWithFeedback(
                currentOutfit: outfit,
                feedback: feedback
            ) {
                await MainActor.run {
                    // Replace current outfit with new one
                    var outfits = outfitRepo.todaysOutfits
                    if currentIndex < outfits.count {
                        outfits[currentIndex] = newOutfit
                        outfitRepo.todaysOutfits = outfits
                    }
                    isSaved = false
                    isRegenerating = false
                }
            } else {
                await MainActor.run {
                    isRegenerating = false
                }
            }
        }
    }

    private func shareOutfit() {
        guard let outfit = currentOutfit else { return }

        // Get the wardrobe items for this outfit
        let outfitItems = outfit.wardrobeItemIds.compactMap { id in
            wardrobeService.items.first { $0.id == id }
        }

        // Get the top view controller for presenting the share sheet
        guard let topVC = UIApplication.shared.topViewController else {
            print("OutfitResultsView: Could not find top view controller")
            return
        }

        HapticManager.shared.light()

        Task {
            await shareService.shareOutfit(
                outfit: outfit,
                items: outfitItems,
                occasion: outfit.occasion,
                from: topVC
            )
        }
    }
}

// MARK: - Outfit Grid View (1 large + 3 small)
struct OutfitGridView: View {
    let itemIds: [String]
    let items: [WardrobeItem]

    private func item(for id: String) -> WardrobeItem? {
        items.first { $0.id == id }
    }

    var body: some View {
        let displayItems = itemIds.prefix(4).compactMap { item(for: $0) }

        if displayItems.isEmpty {
            RoundedRectangle(cornerRadius: AppSpacing.radiusLg)
                .fill(AppColors.filterTagBg)
                .frame(height: 300)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.textMuted)
                )
        } else {
            HStack(spacing: AppSpacing.sm) {
                // Large image (first item)
                if let first = displayItems.first {
                    OutfitItemImage(item: first)
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                }

                // Small images (remaining items)
                if displayItems.count > 1 {
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(Array(displayItems.dropFirst().prefix(3)), id: \.id) { item in
                            OutfitItemImage(item: item)
                                .frame(height: 88)
                        }
                    }
                    .frame(width: 100)
                }
            }
        }
    }
}

// MARK: - Outfit Item Image
struct OutfitItemImage: View {
    let item: WardrobeItem

    var body: some View {
        AsyncImage(url: URL(string: item.displayPhotoUrl ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                Rectangle()
                    .fill(AppColors.filterTagBg)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(AppColors.textMuted)
                    )
            case .empty:
                Rectangle()
                    .fill(AppColors.filterTagBg)
                    .modifier(ShimmerModifier())
            @unknown default:
                Rectangle()
                    .fill(AppColors.filterTagBg)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
    }
}

// MARK: - Refinement Button
struct RefinementButton: View {
    let label: String
    let icon: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(AppColors.textSecondary)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                    Text(label)
                        .font(AppTypography.labelSmall)
                }
            }
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppColors.filterTagBg)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isLoading)
    }
}

// MARK: - ScoredOutfit Extension
extension ScoredOutfit {
    var aiHeadline: String {
        // Use the headline from AI if available, otherwise generate a fallback
        if let headline = headline, !headline.isEmpty {
            return headline
        }
        // Fallback based on vibe or occasion
        if let vibe = vibe, !vibe.isEmpty {
            return "\(vibe) vibes for your day"
        }
        if let occasion = occasion, !occasion.isEmpty {
            return "Perfect for \(occasion)"
        }
        return "Stylish look for today"
    }
}

#Preview {
    OutfitResultsView()
        .environment(AppCoordinator())
}
