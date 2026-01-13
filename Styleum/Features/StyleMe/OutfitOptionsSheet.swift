import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct OutfitOptionsSheet: View {
    let outfitId: String
    @Environment(\.dismiss) private var dismiss
    @Environment(AppCoordinator.self) private var coordinator

    private let outfitRepo = OutfitRepository.shared
    private let wardrobeService = WardrobeService.shared

    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Handle indicator
            Capsule()
                .fill(AppColors.textMuted.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, AppSpacing.sm)

            Text("Outfit Options")
                .font(AppTypography.headingMedium)
                .padding(.top, AppSpacing.sm)

            VStack(spacing: AppSpacing.sm) {
                AppButton(label: "Save Outfit", icon: .likeFilled) {
                    HapticManager.shared.likeOutfit()
                    dismiss()
                }

                AppButton(
                    label: "Share",
                    variant: .secondary,
                    icon: .share
                ) {
                    HapticManager.shared.medium()
                    showShareSheet = true
                }

                AppButton(label: "Not for me", variant: .secondary) {
                    HapticManager.shared.skipOutfit()
                    dismiss()
                }
            }
            .padding(.horizontal, AppSpacing.pageMargin)

            Spacer()
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.hidden)
        .fullScreenCover(isPresented: $showShareSheet) {
            if let outfit = outfitRepo.sessionOutfits.first(where: { $0.id == outfitId }) {
                let itemIds = outfit.wardrobeItemIds
                let items = wardrobeService.items.filter { itemIds.contains($0.id) }

                ShareOptionsSheet(
                    outfit: outfit,
                    items: items,
                    onDismiss: {
                        showShareSheet = false
                        dismiss()
                    }
                )
            }
        }
    }
}

#Preview {
    OutfitOptionsSheet(outfitId: "test-outfit")
        .environment(AppCoordinator())
}
