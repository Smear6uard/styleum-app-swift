import SwiftUI

struct WardrobeScreen: View {
    @Environment(AppCoordinator.self) var coordinator
    @State private var wardrobeService = WardrobeService.shared
    @State private var selectedCategories: Set<String> = ["All"]

    @Namespace private var wardrobeNamespace

    let categories = ["All", "Tops", "Bottoms", "Shoes", "Outerwear", "Accessories"]

    private var filteredItems: [WardrobeItem] {
        if selectedCategories.contains("All") {
            return wardrobeService.items
        }
        return wardrobeService.items.filter { item in
            guard let category = item.category?.displayName else { return false }
            return selectedCategories.contains(category)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: AppSpacing.md) {
                HStack {
                    Text("My Wardrobe")
                        .font(AppTypography.headingLarge)

                    Spacer()

                    Text("\(wardrobeService.items.count)")
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, AppSpacing.pageMargin)

                // Add button - black CTA
                Button {
                    coordinator.present(.addItem)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Add to Closet")
                            .font(AppTypography.labelLarge)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColors.black)
                    .cornerRadius(AppSpacing.radiusMd)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, AppSpacing.pageMargin)

                // Underline tabs with multi-select
                UnderlineTabs(
                    tabs: categories,
                    selectedTabs: $selectedCategories,
                    allowMultiSelect: true
                )
            }
            .padding(.top, AppSpacing.md)

            // Content
            if wardrobeService.isLoading && wardrobeService.items.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if filteredItems.isEmpty {
                Spacer()
                EmptyState(
                    icon: .wardrobe,
                    headline: selectedCategories.contains("All") ? "Your closet is empty" : "No items in this category",
                    description: "Add items to your wardrobe to start getting outfit suggestions.",
                    ctaLabel: "Add First Item"
                ) {
                    coordinator.present(.addItem)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: AppSpacing.md),
                            GridItem(.flexible(), spacing: AppSpacing.md)
                        ],
                        spacing: AppSpacing.md
                    ) {
                        ForEach(filteredItems) { item in
                            WardrobeItemCard(item: item, namespace: wardrobeNamespace)
                                .onTapGesture {
                                    HapticManager.shared.light()
                                    coordinator.navigate(to: .itemDetail(itemId: item.id))
                                }
                        }
                    }
                    .padding(AppSpacing.pageMargin)
                }
                .refreshable {
                    HapticManager.shared.light()
                    await wardrobeService.fetchItems()
                }
            }
        }
        .background(AppColors.background)
        .navigationBarHidden(true)
        .task {
            await wardrobeService.fetchItems()
        }
    }
}

// MARK: - Wardrobe Item Card (fixed overflow)
struct WardrobeItemCard: View {
    let item: WardrobeItem
    var namespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image with proper containment - NO overflow
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
                        .overlay(ProgressView())
                @unknown default:
                    Rectangle()
                        .fill(AppColors.filterTagBg)
                }
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .clipped() // Prevent overflow
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.itemName ?? item.category?.displayName ?? "Item")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                if let brand = item.brand, !brand.isEmpty {
                    Text(brand)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

#Preview {
    WardrobeScreen()
        .environment(AppCoordinator())
}
