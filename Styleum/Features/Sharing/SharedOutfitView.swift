import SwiftUI

struct SharedOutfitView: View {
    let shareId: String

    @Environment(\.dismiss) private var dismiss
    @Environment(AppCoordinator.self) private var coordinator

    @State private var isLoading = true
    @State private var outfit: ScoredOutfit?
    @State private var items: [WardrobeItem] = []
    @State private var sharerName: String?
    @State private var errorMessage: String?

    private let api = StyleumAPI.shared
    private let authService = AuthService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if let outfit = outfit {
                    outfitContent(outfit)
                } else {
                    errorView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
        }
        .task {
            await loadSharedOutfit()
        }
    }

    // MARK: - Loading View
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading outfit...")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textMuted)
        }
    }

    // MARK: - Error View
    @ViewBuilder
    private var errorView: some View {
        VStack(spacing: 24) {
            Image(systemName: "tshirt.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textMuted)

            VStack(spacing: 8) {
                Text("Outfit Not Found")
                    .font(AppTypography.headingSmall)
                    .foregroundColor(AppColors.textPrimary)

                Text(errorMessage ?? "This outfit may have been removed or the link is invalid.")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textMuted)
                    .multilineTextAlignment(.center)
            }

            Button {
                dismiss()
                coordinator.switchTab(to: .styleMe)
            } label: {
                Text("Create Your Own Outfit")
                    .font(AppTypography.labelLarge)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.brownPrimary)
                    .cornerRadius(AppSpacing.radiusMd)
            }
            .padding(.horizontal, AppSpacing.pageMargin)
        }
        .padding()
    }

    // MARK: - Outfit Content
    @ViewBuilder
    private func outfitContent(_ outfit: ScoredOutfit) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header
                VStack(spacing: 4) {
                    if let name = sharerName {
                        Text(name)
                            .font(AppTypography.kicker)
                            .foregroundColor(AppColors.brownLight)
                            .tracking(1)
                    }

                    Text(outfit.headline ?? "Shared Outfit")
                        .font(AppTypography.displaySmall)
                        .foregroundColor(AppColors.textPrimary)

                    if let vibe = outfit.vibe {
                        Text(vibe)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textMuted)
                    }
                }
                .padding(.top, AppSpacing.md)

                // Score
                HStack(spacing: 8) {
                    Text("\(outfit.score)")
                        .font(.system(size: 48, weight: .light, design: .serif))
                        .foregroundColor(AppColors.brownPrimary)
                    Text("/ 100")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textMuted)
                }

                // Items grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(items) { item in
                        SharedItemCard(item: item)
                    }
                }
                .padding(.horizontal, AppSpacing.pageMargin)

                // Styling tip - only show if meaningful (not generic filler text)
                if let tip = outfit.stylingTip?.ifMeaningful {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("STYLING TIP")
                            .font(AppTypography.kicker)
                            .foregroundColor(AppColors.brownLight)
                            .tracking(1)
                        Text(tip)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.md)
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(AppSpacing.radiusMd)
                    .padding(.horizontal, AppSpacing.pageMargin)
                }

                Spacer(minLength: 100)
            }
        }
        .safeAreaInset(edge: .bottom) {
            ctaButton
        }
    }

    // MARK: - CTA Button
    @ViewBuilder
    private var ctaButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                if authService.isAuthenticated {
                    dismiss()
                    coordinator.switchTab(to: .styleMe)
                } else {
                    // Show sign up prompt or navigate to onboarding
                    dismiss()
                    coordinator.presentFullScreen(.onboarding)
                }
            } label: {
                Text(authService.isAuthenticated ? "Style Me Like This" : "Sign Up to Get Styled")
                    .font(AppTypography.labelLarge)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.brownPrimary)
                    .cornerRadius(AppSpacing.radiusMd)
            }
            .padding(.horizontal, AppSpacing.pageMargin)
            .padding(.vertical, AppSpacing.md)
        }
        .background(AppColors.background)
    }

    // MARK: - Load Data
    private func loadSharedOutfit() async {
        do {
            let response = try await api.getSharedOutfit(shareId: shareId)
            outfit = response.outfit
            items = response.items
            sharerName = response.sharerName
            isLoading = false
        } catch {
            print("Failed to load shared outfit: \(error)")
            errorMessage = "Could not load this outfit."
            isLoading = false
        }
    }
}

// MARK: - Shared Item Card

private struct SharedItemCard: View {
    let item: WardrobeItem

    var body: some View {
        VStack(spacing: 8) {
            // Item image
            AsyncImage(url: URL(string: item.displayPhotoUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(AppColors.backgroundSecondary)
                    .overlay(
                        Image(systemName: "tshirt")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.textMuted)
                    )
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSm))

            // Item info
            VStack(spacing: 2) {
                Text(item.itemName ?? item.category?.displayName ?? "Item")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                if let brand = item.brand {
                    Text(brand)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textMuted)
                        .lineLimit(1)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SharedOutfitView(shareId: "preview-share-id")
        .environment(AppCoordinator())
}
