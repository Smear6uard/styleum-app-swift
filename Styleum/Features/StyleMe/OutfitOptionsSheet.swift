import SwiftUI

struct OutfitOptionsSheet: View {
    let outfitId: String
    @Environment(\.dismiss) private var dismiss
    @Environment(AppCoordinator.self) private var coordinator

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

                AppButton(label: "Share", variant: .secondary, icon: .share) {
                    // Share action
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
    }
}

#Preview {
    OutfitOptionsSheet(outfitId: "test-outfit")
        .environment(AppCoordinator())
}
