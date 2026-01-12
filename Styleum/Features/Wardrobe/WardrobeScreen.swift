import SwiftUI
import Kingfisher

struct WardrobeScreen: View {
    @Environment(AppCoordinator.self) var coordinator
    // Use direct singleton reference instead of @State for shared services
    private let wardrobeService = WardrobeService.shared
    private let tierManager = TierManager.shared
    @State private var selectedCategories: Set<String> = ["All"]

    // Quick actions state
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var sortOption: SortOption = .dateAdded

    // Multi-select state
    @State private var isSelectMode = false
    @State private var selectedItems: Set<String> = []

    // Paywall state
    @State private var showCapsuleComplete = false

    // Animation state
    @State private var itemsAppeared = false

    @Namespace private var wardrobeNamespace

    let categories = ["All", "Tops", "Bottoms", "Shoes", "Outerwear", "Accessories"]

    enum SortOption: String, CaseIterable {
        case dateAdded = "Date Added"
        case mostWorn = "Most Worn"
        case color = "Color"
        case brand = "Brand"
    }

    private var filteredItems: [WardrobeItem] {
        var items = wardrobeService.items

        // Category filter
        if !selectedCategories.contains("All") {
            items = items.filter { item in
                guard let category = item.category?.displayName else { return false }
                return selectedCategories.contains(category)
            }
        }

        // Search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            items = items.filter { item in
                (item.itemName?.lowercased().contains(query) ?? false) ||
                (item.brand?.lowercased().contains(query) ?? false) ||
                (item.primaryColor?.lowercased().contains(query) ?? false) ||
                (item.category?.displayName.lowercased().contains(query) ?? false)
            }
        }

        // Sort
        switch sortOption {
        case .dateAdded:
            items.sort { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        case .mostWorn:
            items.sort { ($0.wearCount ?? $0.timesWorn) > ($1.wearCount ?? $1.timesWorn) }
        case .color:
            items.sort { ($0.primaryColor ?? "") < ($1.primaryColor ?? "") }
        case .brand:
            items.sort { ($0.brand ?? "zzz") < ($1.brand ?? "zzz") }
        }

        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            // Editorial Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("My Wardrobe")
                        .font(AppTypography.editorialHeadline)
                        .foregroundColor(AppColors.textPrimary)

                    // Tier-aware item counter
                    if let usage = tierManager.tierInfo?.usage {
                        WardrobeCounter(
                            current: usage.wardrobeItems,
                            limit: usage.wardrobeLimit,
                            isPro: tierManager.isPro
                        )
                    } else {
                        Text("\(wardrobeService.items.count) pieces")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    // Search button
                    Button {
                        withAnimation(AppAnimations.spring) {
                            isSearching.toggle()
                            if !isSearching {
                                searchText = ""
                            }
                        }
                        HapticManager.shared.light()
                    } label: {
                        Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 40, height: 40)
                            .background(isSearching ? AppColors.backgroundTertiary : AppColors.backgroundSecondary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel(isSearching ? "Close search" : "Search wardrobe")
                    .accessibilityHint("Filter items by name, brand, or color")

                    // Sort menu
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                sortOption = option
                                HapticManager.shared.selection()
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 40, height: 40)
                            .background(AppColors.backgroundSecondary)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Sort wardrobe")
                    .accessibilityHint("Currently sorted by \(sortOption.rawValue)")

                    // Add button (gated by tier)
                    Button {
                        HapticManager.shared.medium()
                        if tierManager.canAddItem {
                            coordinator.present(.addItem)
                        } else {
                            showCapsuleComplete = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 40, height: 40)
                            .background(AppColors.backgroundSecondary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel("Add item")
                    .accessibilityHint("Add a new clothing item to your wardrobe")
                }
            }
            .padding(.horizontal, AppSpacing.pageMargin)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.sm)

            // Expandable search field
            if isSearching {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textMuted)

                    TextField("Search wardrobe...", text: $searchText)
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textPrimary)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            HapticManager.shared.light()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.textMuted)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(AppSpacing.radiusSm)
                .padding(.horizontal, AppSpacing.pageMargin)
                .padding(.bottom, AppSpacing.sm)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Editorial underline filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(categories, id: \.self) { category in
                        let isSelected = selectedCategories.contains(category)
                        VStack(spacing: 6) {
                            Text(category)
                                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textMuted)

                            // Underline indicator - brown accent
                            Rectangle()
                                .fill(isSelected ? AppColors.brownPrimary : Color.clear)
                                .frame(height: 2.5)
                        }
                        .onTapGesture {
                            // Single tap = select only this category
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategories = [category]
                            }
                            HapticManager.shared.selection()
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
                // Skeleton loading grid
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 14),
                            GridItem(.flexible(), spacing: 14)
                        ],
                        alignment: .center,
                        spacing: 16
                    ) {
                        ForEach(0..<6, id: \.self) { _ in
                            WardrobeItemSkeleton()
                        }
                    }
                    .padding(.horizontal, AppSpacing.pageMargin)
                    .padding(.bottom, AppSpacing.xl)
                }
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
                        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                            wardrobeGridItem(item: item, index: index)
                        }
                    }
                    .padding(.horizontal, AppSpacing.pageMargin)
                    .padding(.bottom, AppSpacing.xl)
                }
                .refreshable {
                    HapticManager.shared.light()
                    await wardrobeService.fetchItems()
                }
                .onAppear {
                    // Trigger staggered entrance animation
                    if !itemsAppeared {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            itemsAppeared = true
                        }
                    }
                }
                .onChange(of: filteredItems.count) { _, _ in
                    // Reset animation when items change significantly
                    itemsAppeared = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        itemsAppeared = true
                    }
                }
            }
        }
        .background(AppColors.background)
        .navigationBarHidden(true)
        .task {
            await tierManager.refresh()
            await wardrobeService.fetchItems()
        }
        .sheet(isPresented: $showCapsuleComplete) {
            CapsuleCompleteView(
                currentCount: wardrobeService.items.count,
                onUpgrade: {
                    coordinator.navigate(to: .subscription)
                }
            )
            .presentationDetents([.medium])
        }
        .overlay(alignment: .bottom) {
            // Floating action bar for multi-select
            if isSelectMode {
                VStack(spacing: 0) {
                    Divider()

                    HStack(spacing: 16) {
                        // Cancel button
                        Button {
                            withAnimation(AppAnimations.spring) {
                                isSelectMode = false
                                selectedItems.removeAll()
                            }
                            HapticManager.shared.light()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                                .frame(width: 40, height: 40)
                                .background(AppColors.backgroundSecondary)
                                .clipShape(Circle())
                        }

                        Text("\(selectedItems.count) selected")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)

                        Spacer()

                        // Action buttons when 2+ items selected
                        if selectedItems.count >= 2 {
                            Button {
                                // Style with these - navigate to Style Me with pre-selected items
                                coordinator.switchTab(to: .styleMe)
                                // TODO: Pass selected items to Style Me screen
                                exitSelectMode()
                            } label: {
                                Text("Style")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(AppColors.backgroundSecondary)
                                    .cornerRadius(AppSpacing.radiusSm)
                            }

                            Button {
                                // Create outfit flow
                                coordinator.present(.createOutfit(itemIds: Array(selectedItems)))
                                exitSelectMode()
                            } label: {
                                Text("Create Outfit")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(AppColors.black)
                                    .cornerRadius(AppSpacing.radiusSm)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.pageMargin)
                    .padding(.vertical, 12)
                    .background(AppColors.background)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Grid Item View Builder

    @ViewBuilder
    private func wardrobeGridItem(item: WardrobeItem, index: Int) -> some View {
        ZStack {
            WardrobeItemCard(item: item, namespace: wardrobeNamespace)
                .opacity(itemsAppeared ? 1 : 0)
                .offset(y: itemsAppeared ? 0 : 20)
                .animation(AppAnimations.staggeredFast(index: index), value: itemsAppeared)

            // Selection overlay - matches new card radius
            if isSelectMode {
                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                    .fill(selectedItems.contains(item.id) ? Color.clear : Color.black.opacity(0.35))
                    .animation(AppAnimations.fast, value: selectedItems.contains(item.id))

                // Checkmark for selected
                if selectedItems.contains(item.id) {
                    VStack {
                        HStack {
                            Circle()
                                .fill(AppColors.black)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(12)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelectMode {
                // Toggle selection
                withAnimation(AppAnimations.springSnappy) {
                    if selectedItems.contains(item.id) {
                        selectedItems.remove(item.id)
                        // Exit select mode if no items selected
                        if selectedItems.isEmpty {
                            isSelectMode = false
                        }
                    } else {
                        selectedItems.insert(item.id)
                    }
                }
                HapticManager.shared.selection()
            } else {
                HapticManager.shared.light()
                coordinator.navigate(to: .itemDetail(itemId: item.id))
            }
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            // Enter select mode - slightly faster
            withAnimation(AppAnimations.springSnappy) {
                isSelectMode = true
                selectedItems.insert(item.id)
            }
            HapticManager.shared.medium()
        }
    }

    private func exitSelectMode() {
        withAnimation(AppAnimations.spring) {
            isSelectMode = false
            selectedItems.removeAll()
        }
    }
}

// MARK: - Editorial Wardrobe Item Card (3:4 aspect ratio, Premium)
struct WardrobeItemCard: View {
    let item: WardrobeItem
    var namespace: Namespace.ID

    private var wearCount: Int {
        item.wearCount ?? item.timesWorn
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image container with parallax and wear count badge
            GeometryReader { geo in
                let minY = geo.frame(in: .global).minY
                let parallaxOffset = max(-15, min(15, (minY - 300) * 0.04))

                ZStack(alignment: .topTrailing) {
                    // Use Kingfisher for proper caching, deduplication, and memory management
                    if let urlString = item.displayPhotoUrl,
                       !urlString.isEmpty,
                       let url = URL(string: urlString) {
                        KFImage(url)
                            .placeholder {
                                loadingPlaceholder
                            }
                            .onFailure { _ in }
                            .fade(duration: 0.25)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.width * 4/3)
                            .clipped()
                            .offset(y: parallaxOffset)
                            .matchedGeometryEffect(id: "itemImage-\(item.id)", in: namespace)
                    } else {
                        // No valid URL - show logo placeholder immediately
                        fallbackPlaceholder
                            .matchedGeometryEffect(id: "itemImage-\(item.id)", in: namespace)
                    }

                    // Wear count badge - refined
                    if wearCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10, weight: .semibold))
                            Text("\(wearCount)")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.7))
                        .clipShape(Capsule())
                        .padding(10)
                    }
                }
            }
            .aspectRatio(3/4, contentMode: .fit)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                    .fill(Color(hex: "FAFAFA"))
            )

            // Item info - Bug Fix: Always show name or category fallback
            VStack(alignment: .leading, spacing: 2) {
                // Always show a name - use category as fallback, then "Unnamed"
                Text(item.itemName ?? item.category?.displayName ?? "Unnamed")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                // Category sublabel - always show if we have category (even without name)
                if let category = item.category {
                    Text(category.rawValue.capitalized)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 2)
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
        // Triple-layer shadow for depth
        .shadow(color: .black.opacity(0.03), radius: 1, y: 1)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .shadow(color: .black.opacity(0.03), radius: 20, y: 8)
    }

    private var loadingPlaceholder: some View {
        CardImageSkeleton()
    }

    private var errorPlaceholder: some View {
        RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
            .fill(Color(hex: "F5F5F5"))
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(AppColors.textMuted.opacity(0.5))
            )
    }

    // Bug Fix: Proper fallback placeholder with app logo for missing URLs
    private var fallbackPlaceholder: some View {
        RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
            .fill(Color(hex: "F5F5F5"))
            .overlay(
                Image(.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .opacity(0.3)
            )
    }
}

// MARK: - Wardrobe Item Skeleton

struct WardrobeItemSkeleton: View {
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image placeholder with shimmer
            ZStack {
                Rectangle()
                    .fill(AppColors.backgroundSecondary)

                // Shimmer effect
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
            }
            .aspectRatio(3/4, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))

            // Title placeholder
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.backgroundSecondary)
                    .frame(height: 14)

                RoundedRectangle(cornerRadius: 3)
                    .fill(AppColors.backgroundSecondary.opacity(0.6))
                    .frame(width: 60, height: 10)
            }
            .padding(.top, 10)
            .padding(.horizontal, 2)
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1.2)
                .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 200
            }
        }
    }
}

#Preview {
    WardrobeScreen()
        .environment(AppCoordinator())
}
