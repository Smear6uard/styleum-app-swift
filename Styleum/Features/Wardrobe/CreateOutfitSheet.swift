import SwiftUI

struct CreateOutfitSheet: View {
    @Environment(AppCoordinator.self) var coordinator
    @Environment(\.dismiss) private var dismiss
    @State private var wardrobeService = WardrobeService.shared

    let itemIds: [String]

    private var selectedItems: [WardrobeItem] {
        wardrobeService.items.filter { itemIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                // Header
                Text("Create Outfit")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.top, AppSpacing.lg)

                Text("You've selected \(selectedItems.count) pieces")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)

                // Selected items preview
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(selectedItems) { item in
                            AsyncImage(url: URL(string: item.displayPhotoUrl ?? "")) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure, .empty:
                                    Rectangle()
                                        .fill(AppColors.backgroundSecondary)
                                @unknown default:
                                    Rectangle()
                                        .fill(AppColors.backgroundSecondary)
                                }
                            }
                            .frame(width: 80, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal, AppSpacing.pageMargin)
                }
                .frame(height: 100)

                Spacer()

                // Coming soon message
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.textMuted)

                    Text("Outfit creation coming soon!")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("For now, use Style Me to generate outfits from your wardrobe.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)
                }

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        dismiss()
                        coordinator.switchTab(to: .styleMe)
                    } label: {
                        Text("Go to Style Me")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.black)
                            .cornerRadius(AppSpacing.radiusMd)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
                .padding(.horizontal, AppSpacing.pageMargin)
                .padding(.bottom, AppSpacing.lg)
            }
            .background(AppColors.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(AppColors.backgroundSecondary)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
}

#Preview {
    CreateOutfitSheet(itemIds: [])
        .environment(AppCoordinator())
}
