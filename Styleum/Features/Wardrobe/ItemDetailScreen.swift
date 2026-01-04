import SwiftUI

struct ItemDetailScreen: View {
    let itemId: String
    @Environment(\.dismiss) var dismiss
    @State private var wardrobeService = WardrobeService.shared
    @State private var showDeleteConfirm = false

    private var item: WardrobeItem? {
        wardrobeService.items.first { $0.id == itemId }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Full-bleed image with overlay buttons
                ZStack(alignment: .top) {
                    if let photoUrl = item?.photoUrl {
                        AsyncImage(url: URL(string: photoUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(AppColors.filterTagBg)
                                .overlay(ProgressView())
                        }
                        .frame(height: 400)
                        .frame(maxWidth: .infinity)
                        .clipped()
                    }

                    // Nav overlay
                    HStack {
                        Button {
                            HapticManager.shared.light()
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }

                        Spacer()

                        Button {
                            Task {
                                try? await wardrobeService.toggleFavorite(id: itemId)
                                HapticManager.shared.medium()
                            }
                        } label: {
                            Image(systemName: item?.isFavorite ?? false ? "heart.fill" : "heart")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, AppSpacing.pageMargin)
                    .padding(.top, 60)
                }

                // Item name
                Text(item?.itemName ?? "Item")
                    .font(AppTypography.headingLarge)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.pageMargin)
                    .padding(.top, AppSpacing.lg)

                // Details section
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("DETAILS")
                            .font(AppTypography.kicker)
                            .foregroundColor(AppColors.textMuted)
                            .tracking(1)

                        Spacer()

                        Text("Tap to edit")
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textMuted)
                    }
                    .padding(.top, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.md)

                    // Editable detail rows
                    DetailEditRow(label: "Category", value: item?.category?.displayName ?? "—") {
                        // Edit category
                    }

                    DetailEditRow(label: "Color", value: item?.primaryColor ?? "—") {
                        // Edit color
                    }

                    DetailEditRow(label: "Style", value: item?.styleBucket ?? "—") {
                        // Edit style
                    }

                    DetailEditRow(label: "Formality", value: formalityLabel(item?.formality)) {
                        // Edit formality
                    }

                    DetailEditRow(label: "Brand", value: item?.brand ?? "—") {
                        // Edit brand
                    }

                    DetailEditRow(label: "Size", value: item?.size ?? "—") {
                        // Edit size
                    }

                    // Times worn (non-editable)
                    HStack {
                        Text("Times Worn")
                            .font(AppTypography.bodyMedium)
                        Spacer()
                        Text("\(item?.timesWorn ?? 0)")
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.vertical, 16)
                }
                .padding(.horizontal, AppSpacing.pageMargin)

                Spacer().frame(height: AppSpacing.xl)

                // Delete button at bottom
                Button {
                    showDeleteConfirm = true
                } label: {
                    Text("Delete Item")
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColors.danger)
                }
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .background(AppColors.background)
        .navigationBarHidden(true)
        .confirmationDialog("Delete Item", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                HapticManager.shared.warning()
                Task {
                    try? await wardrobeService.deleteItem(id: itemId)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This item will be permanently removed from your wardrobe.")
        }
    }

    private func formalityLabel(_ level: Int?) -> String {
        guard let level = level else { return "—" }
        switch level {
        case 1: return "Very casual"
        case 2: return "Casual"
        case 3: return "Smart casual"
        case 4: return "Business casual"
        case 5: return "Formal"
        default: return "—"
        }
    }
}

// MARK: - Detail Edit Row
struct DetailEditRow: View {
    let label: String
    let value: String
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            onTap()
        }) {
            HStack {
                Text(label)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Text(value)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textMuted)
            }
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)

        Divider()
    }
}

#Preview {
    ItemDetailScreen(itemId: "test")
}
