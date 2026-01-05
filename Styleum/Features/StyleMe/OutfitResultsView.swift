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

                        // Outfit Grid: 1 large + 3 small
                        OutfitGridView(
                            itemIds: outfit.wardrobeItemIds,
                            items: wardrobeService.items
                        )
                        .padding(.horizontal, AppSpacing.pageMargin)

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

                        // Refinement buttons
                        HStack(spacing: AppSpacing.sm) {
                            RefinementButton(label: "More casual", icon: "arrow.down", isLoading: isRegenerating) {
                                regenerateOutfit(with: .moreCasual)
                            }

                            RefinementButton(label: "More bold", icon: "sparkles", isLoading: isRegenerating) {
                                regenerateOutfit(with: .moreBold)
                            }
                        }
                        .padding(.horizontal, AppSpacing.pageMargin)

                        HStack(spacing: AppSpacing.sm) {
                            RefinementButton(label: "More formal", icon: "arrow.up", isLoading: isRegenerating) {
                                regenerateOutfit(with: .moreFormal)
                            }

                            RefinementButton(label: "Different colors", icon: "paintpalette", isLoading: isRegenerating) {
                                regenerateOutfit(with: .differentColors)
                            }
                        }
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

                        // Wear button
                        Button {
                            HapticManager.shared.success()
                            Task {
                                try? await outfitRepo.markAsWorn(outfit)
                                dismiss()
                            }
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
        AsyncImage(url: URL(string: item.photoUrl ?? "")) { phase in
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
