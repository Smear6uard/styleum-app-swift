import SwiftUI

struct OutfitDetailScreen: View {
    let outfitId: String
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Outfit preview placeholder
                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                    .fill(AppColors.filterTagBg)
                    .aspectRatio(0.75, contentMode: .fit)
                    .overlay(
                        Text("Outfit Preview")
                            .foregroundColor(AppColors.textMuted)
                    )

                // Outfit info
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Today's Look")
                        .font(AppTypography.headingMedium)

                    Text("Perfect for a sunny day")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Items in outfit
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("ITEMS")
                        .font(AppTypography.kicker)
                        .foregroundColor(AppColors.textMuted)
                        .tracking(1)

                    ForEach(0..<3, id: \.self) { _ in
                        HStack(spacing: AppSpacing.md) {
                            RoundedRectangle(cornerRadius: AppSpacing.radiusSm)
                                .fill(AppColors.filterTagBg)
                                .frame(width: 60, height: 60)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Item Name")
                                    .font(AppTypography.titleSmall)
                                Text("Category")
                                    .font(AppTypography.bodySmall)
                                    .foregroundColor(AppColors.textSecondary)
                            }

                            Spacer()
                        }
                    }
                }

                // Actions
                VStack(spacing: AppSpacing.sm) {
                    AppButton(label: "Wear This Today", icon: .checkmark) {
                        HapticManager.shared.success()
                    }

                    AppButton(label: "Save Outfit", variant: .secondary, icon: .likeFilled) {
                        HapticManager.shared.likeOutfit()
                    }
                }
            }
            .padding(AppSpacing.pageMargin)
        }
        .background(AppColors.background)
        .navigationTitle("Outfit")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        OutfitDetailScreen(outfitId: "test-outfit")
            .environment(AppCoordinator())
    }
}
