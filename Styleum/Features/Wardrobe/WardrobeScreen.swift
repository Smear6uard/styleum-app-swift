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
            // Editorial Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("My Wardrobe")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(AppColors.textPrimary)

                    Text("\(wardrobeService.items.count) pieces")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                // Circular add button
                Button {
                    HapticManager.shared.medium()
                    coordinator.present(.addItem)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(AppColors.backgroundSecondary)
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, AppSpacing.pageMargin)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.sm)

            // Editorial underline filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(categories, id: \.self) { category in
                        let isSelected = selectedCategories.contains(category)
                        VStack(spacing: 6) {
                            Text(category)
                                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textMuted)

                            // Underline indicator
                            Rectangle()
                                .fill(isSelected ? AppColors.textPrimary : Color.clear)
                                .frame(height: 1.5)
                        }
                        .onTapGesture {
                            // Single tap = select only this category
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategories = [category]
                            }
                        }
                        .onLongPressGesture(minimumDuration: 0.3) {
                            // Long press = toggle in multi-select
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedCategories.contains(category) {
                                    selectedCategories.remove(category)
                                    if selectedCategories.isEmpty {
                                        selectedCategories = ["All"]
                                    }
                                } else {
                                    selectedCategories.remove("All")
                                    selectedCategories.insert(category)
                                }
                            }
                            HapticManager.shared.light()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, AppSpacing.md)

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
                            GridItem(.flexible(), spacing: 14),
                            GridItem(.flexible(), spacing: 14)
                        ],
                        alignment: .center,
                        spacing: 16
                    ) {
                        ForEach(filteredItems) { item in
                            WardrobeItemCard(item: item, namespace: wardrobeNamespace)
                                .onTapGesture {
                                    HapticManager.shared.light()
                                    coordinator.navigate(to: .itemDetail(itemId: item.id))
                                }
                        }
                    }
                    .padding(.horizontal, AppSpacing.pageMargin)
                    .padding(.bottom, AppSpacing.xl)
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

// MARK: - Editorial Wardrobe Item Card (3:4 aspect ratio, SSENSE-style)
struct WardrobeItemCard: View {
    let item: WardrobeItem
    var namespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image container with DEFINED bounds, then clip
            GeometryReader { geo in
                AsyncImage(url: URL(string: item.displayPhotoUrl ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.width * 4/3)
                            .clipped()
                    case .failure:
                        errorPlaceholder
                    case .empty:
                        loadingPlaceholder
                    @unknown default:
                        loadingPlaceholder
                    }
                }
            }
            .aspectRatio(3/4, contentMode: .fit)
            .clipped()
            .cornerRadius(6)  // Subtle radius on image only
            .background(Color(hex: "F8F8F8"))  // Clean near-white for transparent images

            // Item info - minimal, below image
            Text(item.itemName ?? item.category?.displayName ?? "Item")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
                .padding(.vertical, 10)
                .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)  // Soft diffuse shadow for depth
        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)  // Tight shadow for definition
    }

    private var loadingPlaceholder: some View {
        Rectangle()
            .fill(Color(hex: "F8F8F8"))
            .overlay(ProgressView().tint(AppColors.textMuted))
    }

    private var errorPlaceholder: some View {
        Rectangle()
            .fill(Color(hex: "F8F8F8"))
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.textMuted)
            )
    }
}

#Preview {
    WardrobeScreen()
        .environment(AppCoordinator())
}
