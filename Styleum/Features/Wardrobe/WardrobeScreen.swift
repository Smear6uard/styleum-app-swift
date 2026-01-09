import SwiftUI

struct WardrobeScreen: View {
    @Environment(AppCoordinator.self) var coordinator
    @State private var wardrobeService = WardrobeService.shared
    @State private var tierManager = TierManager.shared
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
                        .font(.system(size: 28, weight: .bold, design: .serif))
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
                .staggeredAppearance(index: index)

            // Selection overlay
            if isSelectMode {
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedItems.contains(item.id) ? Color.clear : Color.black.opacity(0.3))

                // Checkmark for selected
                if selectedItems.contains(item.id) {
                    VStack {
                        HStack {
                            Circle()
                                .fill(AppColors.black)
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(10)
                }
            }
        }
        .onTapGesture {
            if isSelectMode {
                // Toggle selection
                withAnimation(AppAnimations.fast) {
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
                HapticManager.shared.light()
            } else {
                HapticManager.shared.light()
                coordinator.navigate(to: .itemDetail(itemId: item.id))
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            // Enter select mode
            withAnimation(AppAnimations.spring) {
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

// MARK: - Editorial Wardrobe Item Card (3:4 aspect ratio, SSENSE-style)
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
                let parallaxOffset = max(-10, min(10, (minY - 300) * 0.03))

                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: item.displayPhotoUrl ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.width * 4/3)
                                .clipped()
                                .offset(y: parallaxOffset)
                        case .failure:
                            errorPlaceholder
                        case .empty:
                            loadingPlaceholder
                        @unknown default:
                            loadingPlaceholder
                        }
                    }

                    // Wear count badge
                    if wearCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 9, weight: .semibold))
                            Text("\(wearCount)")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.6))
                        .clipShape(Capsule())
                        .padding(8)
                    }
                }
            }
            .aspectRatio(3/4, contentMode: .fit)
            .clipped()
            .cornerRadius(6)
            .background(Color(hex: "F8F8F8"))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
            )

            // Item info - always reserve space for consistent card heights
            Text(item.itemName ?? " ")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(item.itemName != nil ? AppColors.textPrimary : .clear)
                .lineLimit(1)
                .padding(.vertical, 10)
                .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
    }

    private var loadingPlaceholder: some View {
        CardImageSkeleton()
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
            .cornerRadius(6)
            .clipped()

            // Title placeholder
            RoundedRectangle(cornerRadius: 3)
                .fill(AppColors.backgroundSecondary)
                .frame(height: 12)
                .padding(.top, 10)
                .padding(.horizontal, 4)
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
