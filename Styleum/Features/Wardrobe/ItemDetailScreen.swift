import SwiftUI

struct ItemDetailScreen: View {
    let itemId: String
    @Environment(\.dismiss) var dismiss
    @Environment(AppCoordinator.self) var coordinator
    @State private var wardrobeService = WardrobeService.shared
    @State private var showDeleteConfirm = false
    @State private var showEditSheet = false

    // Hero entrance animation state
    @State private var heroAppeared = false
    @State private var contentAppeared = false

    private var item: WardrobeItem? {
        wardrobeService.items.first { $0.id == itemId }
    }

    // Warm gray background for image area
    private let imageBackground = Color(hex: "F5F5F3")

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Hero Image Area
                    ZStack(alignment: .topTrailing) {
                        // Background
                        imageBackground
                            .frame(height: geometry.size.height * 0.55)

                        // Item image - centered with padding + hero animation
                        if let photoUrl = item?.displayPhotoUrl {
                            AsyncImage(url: URL(string: photoUrl)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .scaleEffect(heroAppeared ? 1 : 0.92)
                                        .opacity(heroAppeared ? 1 : 0)
                                case .failure:
                                    Image(systemName: "photo")
                                        .font(.system(size: 48))
                                        .foregroundColor(AppColors.textMuted)
                                case .empty:
                                    CardImageSkeleton()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .padding(AppSpacing.xl)
                            .frame(height: geometry.size.height * 0.55)
                        }

                        // Close button - top right
                        Button {
                            HapticManager.shared.light()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                        }
                        .padding(AppSpacing.pageMargin)
                        .padding(.top, 50)
                        .opacity(heroAppeared ? 1 : 0)
                    }

                // MARK: - Content Below Image
                VStack(spacing: AppSpacing.xs) {
                    // Item name - centered, editorial
                    Text(item?.itemName ?? "Item")
                        .font(AppTypography.clashDisplay(28))
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    // Subtitle: Category · Material
                    subtitleView
                }
                .padding(.top, AppSpacing.lg)
                .padding(.horizontal, AppSpacing.pageMargin)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 16)

                // MARK: - Primary CTA
                Button {
                    guard let item = item else { return }
                    HapticManager.shared.medium()
                    coordinator.styleThisPiece(item)
                    dismiss()
                } label: {
                    Text("Style this piece")
                        .font(AppTypography.labelLarge)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppColors.black)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, AppSpacing.pageMargin)
                .padding(.top, AppSpacing.xl)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 12)

                // MARK: - Whisper Stats (only if > 0)
                if item?.timesWorn ?? 0 > 0 {
                    Text("Worn \(item?.timesWorn ?? 0) time\(item?.timesWorn == 1 ? "" : "s")")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textMuted)
                        .padding(.top, AppSpacing.lg)
                        .opacity(contentAppeared ? 1 : 0)
                }

                // MARK: - Edit & Delete Links
                HStack(spacing: AppSpacing.md) {
                    Button("Edit") {
                        HapticManager.shared.selection()
                        showEditSheet = true
                    }
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.textSecondary)

                    Text("·")
                        .foregroundColor(AppColors.textMuted)

                    Button("Delete") {
                        HapticManager.shared.warning()
                        showDeleteConfirm = true
                    }
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.textSecondary)
                }
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
                .opacity(contentAppeared ? 1 : 0)
            }
        }
        }
        .background(AppColors.background)
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
        .onAppear {
            // Staggered hero entrance animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                heroAppeared = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15)) {
                contentAppeared = true
            }
        }
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
        .sheet(isPresented: $showEditSheet) {
            ItemEditSheet(itemId: itemId)
        }
    }

    // MARK: - Subtitle View
    @ViewBuilder
    private var subtitleView: some View {
        let hasCategory = item?.category != nil
        let hasMaterial = item?.material != nil && !(item?.material?.isEmpty ?? true)

        if hasCategory || hasMaterial {
            HStack(spacing: 6) {
                if let category = item?.category {
                    Text(category.displayName)
                }
                if hasCategory && hasMaterial {
                    Text("·")
                }
                if let material = item?.material, !material.isEmpty {
                    Text(material)
                }
            }
            .font(AppTypography.bodyMedium)
            .foregroundColor(AppColors.textSecondary)
        }
    }
}

// MARK: - Item Edit Sheet

struct ItemEditSheet: View {
    let itemId: String
    @Environment(\.dismiss) var dismiss
    @State private var wardrobeService = WardrobeService.shared

    // Edit state
    @State private var editedName: String = ""
    @State private var saveNameTask: Task<Void, Never>?
    // Save feedback states
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    @State private var showCategoryPicker = false
    @State private var showColorPicker = false
    @State private var showStylePicker = false
    @State private var showMaterialPicker = false
    @State private var showFormalityPicker = false
    @State private var showOccasionsPicker = false
    @State private var showSeasonsPicker = false

    private var item: WardrobeItem? {
        wardrobeService.items.first { $0.id == itemId }
    }

    var body: some View {
        NavigationStack {
            List {
                // Name - Bug Fix: Add visual feedback for save status
                Section {
                    HStack {
                        TextField("Name", text: $editedName)
                            .onChange(of: editedName) { _, newValue in
                                saveName(newValue)
                            }

                        // Save status indicator
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if saveSuccess {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }

                // Details
                Section("Details") {
                    // Category
                    if let category = item?.category {
                        Button {
                            showCategoryPicker = true
                        } label: {
                            HStack {
                                Text("Category")
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Text(category.displayName)
                                    .foregroundColor(AppColors.textSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.textMuted)
                            }
                        }
                    }

                    // Color
                    if let color = item?.primaryColor {
                        Button {
                            showColorPicker = true
                        } label: {
                            HStack {
                                Text("Color")
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                if let colorHex = item?.colorHex {
                                    Circle()
                                        .fill(Color(hex: colorHex))
                                        .frame(width: 16, height: 16)
                                }
                                Text(color)
                                    .foregroundColor(AppColors.textSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.textMuted)
                            }
                        }
                    }

                    // Style
                    Button {
                        showStylePicker = true
                    } label: {
                        HStack {
                            Text("Style")
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            if let vibes = item?.styleVibes, !vibes.isEmpty {
                                Text(vibes.joined(separator: ", "))
                                    .foregroundColor(AppColors.textSecondary)
                                    .lineLimit(1)
                            } else {
                                Text("Not set")
                                    .foregroundColor(AppColors.textMuted)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.textMuted)
                        }
                    }

                    // Material
                    Button {
                        showMaterialPicker = true
                    } label: {
                        HStack {
                            Text("Material")
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            if let material = item?.material, !material.isEmpty {
                                Text(material)
                                    .foregroundColor(AppColors.textSecondary)
                            } else {
                                Text("Not set")
                                    .foregroundColor(AppColors.textMuted)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.textMuted)
                        }
                    }

                    // Formality
                    Button {
                        showFormalityPicker = true
                    } label: {
                        HStack {
                            Text("Formality")
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            if let formality = item?.formality {
                                Text(formalityLabel(formality))
                                    .foregroundColor(AppColors.textSecondary)
                            } else {
                                Text("Not set")
                                    .foregroundColor(AppColors.textMuted)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.textMuted)
                        }
                    }
                }

                // Context
                Section("Context") {
                    // Seasons
                    Button {
                        showSeasonsPicker = true
                    } label: {
                        HStack {
                            Text("Seasons")
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            if let seasons = item?.seasons, !seasons.isEmpty {
                                Text(seasons.joined(separator: ", "))
                                    .foregroundColor(AppColors.textSecondary)
                                    .lineLimit(1)
                            } else {
                                Text("Not set")
                                    .foregroundColor(AppColors.textMuted)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.textMuted)
                        }
                    }

                    // Occasions
                    Button {
                        showOccasionsPicker = true
                    } label: {
                        HStack {
                            Text("Occasions")
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            if let occasions = item?.occasions, !occasions.isEmpty {
                                Text(occasions.joined(separator: ", "))
                                    .foregroundColor(AppColors.textSecondary)
                                    .lineLimit(1)
                            } else {
                                Text("Not set")
                                    .foregroundColor(AppColors.textMuted)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.textMuted)
                        }
                    }
                }

                // Info (read-only)
                if item?.brand != nil || item?.size != nil || (item?.timesWorn ?? 0) > 0 {
                    Section("Info") {
                        if let brand = item?.brand, !brand.isEmpty {
                            HStack {
                                Text("Brand")
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Text(brand)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }

                        if let size = item?.size, !size.isEmpty {
                            HStack {
                                Text("Size")
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Text(size)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }

                        if let timesWorn = item?.timesWorn, timesWorn > 0 {
                            HStack {
                                Text("Times Worn")
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Text("\(timesWorn)")
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            editedName = item?.itemName ?? ""
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerSheet(itemId: itemId, currentCategory: item?.category)
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPickerSheet(itemId: itemId, currentColor: item?.primaryColor, currentColorHex: item?.colorHex)
        }
        .sheet(isPresented: $showStylePicker) {
            StylePickerSheet(itemId: itemId, currentStyles: item?.styleVibes ?? [])
        }
        .sheet(isPresented: $showMaterialPicker) {
            MaterialPickerSheet(itemId: itemId, currentMaterial: item?.material)
        }
        .sheet(isPresented: $showFormalityPicker) {
            FormalityPickerSheet(itemId: itemId, currentFormality: item?.formality)
        }
        .sheet(isPresented: $showOccasionsPicker) {
            OccasionsPickerSheet(itemId: itemId, currentOccasions: item?.occasions ?? [])
        }
        .sheet(isPresented: $showSeasonsPicker) {
            SeasonsPickerSheet(itemId: itemId, currentSeasons: item?.seasons ?? [])
        }
        .alert("Save Failed", isPresented: $showSaveError) {
            Button("Retry") {
                saveName(editedName)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(saveErrorMessage)
        }
    }

    private func saveName(_ name: String) {
        // Cancel any pending save task
        saveNameTask?.cancel()
        saveSuccess = false

        // Trim whitespace for validation
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate: if not empty, require at least 2 characters
        if !trimmedName.isEmpty && trimmedName.count < 2 {
            // Don't show error yet, user might still be typing
            return
        }

        // Debounce: wait 500ms before saving to avoid excessive API calls
        saveNameTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }

                await MainActor.run { isSaving = true }

                // Use trimmed name, or nil if empty (will use default display)
                let updates = WardrobeItemUpdate(itemName: trimmedName.isEmpty ? nil : trimmedName)
                try await wardrobeService.updateItem(id: itemId, updates: updates)

                // Force refresh to confirm persistence
                await wardrobeService.fetchItems()

                await MainActor.run {
                    isSaving = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        saveSuccess = true
                    }
                    HapticManager.shared.success()

                    // Verify the change persisted
                    if let updatedItem = wardrobeService.items.first(where: { $0.id == itemId }) {
                        print("[ItemEdit] Verified: name is now '\(updatedItem.itemName ?? "nil")'")
                    }

                    // Reset success indicator after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            saveSuccess = false
                        }
                    }
                }
                print("[ItemEdit] Name saved: '\(trimmedName)'")
            } catch {
                await MainActor.run {
                    isSaving = false
                    if !(error is CancellationError) {
                        saveErrorMessage = "Couldn't save the name. Please try again."
                        showSaveError = true
                        HapticManager.shared.error()
                        print("[ItemEdit] Failed to save name: \(error)")
                    }
                }
            }
        }
    }

    private func formalityLabel(_ score: Int) -> String {
        switch score {
        case 1: return "Very Casual"
        case 2: return "Casual"
        case 3: return "Smart Casual"
        case 4: return "Business Casual"
        case 5: return "Formal"
        case 6...7: return "Business"
        case 8...10: return "Formal"
        default: return "Not set"
        }
    }
}

// MARK: - Picker Sheets

struct CategoryPickerSheet: View {
    let itemId: String
    let currentCategory: ClothingCategory?
    @Environment(\.dismiss) var dismiss
    @State private var wardrobeService = WardrobeService.shared
    @State private var selectedCategory: ClothingCategory?

    var body: some View {
        NavigationStack {
            List {
                ForEach(ClothingCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                        saveCategory()
                    } label: {
                        HStack {
                            Text(category.displayName)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            if selectedCategory == category || (selectedCategory == nil && currentCategory == category) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.slate)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            selectedCategory = currentCategory
        }
    }

    private func saveCategory() {
        guard let category = selectedCategory else { return }
        Task {
            let updates = WardrobeItemUpdate(category: category.rawValue)
            try? await wardrobeService.updateItem(id: itemId, updates: updates)
            HapticManager.shared.light()
        }
    }
}

struct ColorPickerSheet: View {
    let itemId: String
    let currentColor: String?
    let currentColorHex: String?
    @Environment(\.dismiss) var dismiss
    @State private var wardrobeService = WardrobeService.shared

    private let commonColors = [
        ("Black", "#000000"),
        ("White", "#FFFFFF"),
        ("Gray", "#808080"),
        ("Navy", "#000080"),
        ("Brown", "#8B4513"),
        ("Beige", "#F5F5DC"),
        ("Tan", "#D2B48C"),
        ("Cream", "#FFFDD0"),
        ("Red", "#FF0000"),
        ("Blue", "#0000FF"),
        ("Green", "#008000"),
        ("Yellow", "#FFFF00"),
        ("Pink", "#FFC0CB"),
        ("Purple", "#800080"),
        ("Orange", "#FFA500")
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(commonColors, id: \.0) { colorName, colorHex in
                    Button {
                        saveColor(colorName, colorHex)
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 20, height: 20)
                            Text(colorName)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            if currentColor?.lowercased() == colorName.lowercased() {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.slate)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func saveColor(_ color: String, _ colorHex: String) {
        Task {
            let updates = WardrobeItemUpdate(primaryColor: color)
            try? await wardrobeService.updateItem(id: itemId, updates: updates)
            HapticManager.shared.light()
            dismiss()
        }
    }
}

struct StylePickerSheet: View {
    let itemId: String
    let currentStyles: [String]
    @Environment(\.dismiss) var dismiss
    @State private var wardrobeService = WardrobeService.shared
    @State private var selectedStyles: Set<String>

    private let commonStyles = [
        "Casual", "Streetwear", "Minimalist", "Preppy", "Vintage",
        "Bohemian", "Formal", "Sporty", "Edgy", "Romantic",
        "Classic", "Modern", "Retro", "Elegant", "Trendy"
    ]

    init(itemId: String, currentStyles: [String]) {
        self.itemId = itemId
        self.currentStyles = currentStyles
        _selectedStyles = State(initialValue: Set(currentStyles))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(commonStyles, id: \.self) { style in
                    Button {
                        if selectedStyles.contains(style) {
                            selectedStyles.remove(style)
                        } else {
                            selectedStyles.insert(style)
                        }
                        saveStyles()
                    } label: {
                        HStack {
                            Text(style)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            if selectedStyles.contains(style) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.slate)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func saveStyles() {
        Task {
            let updates = WardrobeItemUpdate(styleVibes: Array(selectedStyles))
            try? await wardrobeService.updateItem(id: itemId, updates: updates)
            HapticManager.shared.light()
        }
    }
}

struct MaterialPickerSheet: View {
    let itemId: String
    let currentMaterial: String?
    @Environment(\.dismiss) var dismiss
    @State private var wardrobeService = WardrobeService.shared
    @State private var selectedMaterial: Material?

    var body: some View {
        NavigationStack {
            List {
                ForEach(Material.allCases) { material in
                    Button {
                        selectedMaterial = material
                        saveMaterial()
                    } label: {
                        HStack {
                            Text(material.displayName)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            if selectedMaterial == material || (selectedMaterial == nil && currentMaterial?.lowercased() == material.rawValue.lowercased()) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.slate)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Material")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            if let current = currentMaterial,
               let material = Material.allCases.first(where: { $0.rawValue.lowercased() == current.lowercased() }) {
                selectedMaterial = material
            }
        }
    }

    private func saveMaterial() {
        guard let material = selectedMaterial else { return }
        Task {
            let updates = WardrobeItemUpdate(material: material.rawValue)
            try? await wardrobeService.updateItem(id: itemId, updates: updates)
            HapticManager.shared.light()
        }
    }
}

struct FormalityPickerSheet: View {
    let itemId: String
    let currentFormality: Int?
    @Environment(\.dismiss) var dismiss
    @State private var wardrobeService = WardrobeService.shared
    @State private var selectedFormality: Int?

    private let formalityOptions = [
        (1, "Very Casual"),
        (2, "Casual"),
        (3, "Smart Casual"),
        (4, "Business Casual"),
        (5, "Formal")
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(formalityOptions, id: \.0) { score, label in
                    Button {
                        selectedFormality = score
                        saveFormality()
                    } label: {
                        HStack {
                            Text(label)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            if selectedFormality == score || (selectedFormality == nil && currentFormality == score) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.slate)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Formality")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            selectedFormality = currentFormality
        }
    }

    private func saveFormality() {
        guard let formality = selectedFormality else { return }
        Task {
            let updates = WardrobeItemUpdate(formality: formality)
            try? await wardrobeService.updateItem(id: itemId, updates: updates)
            HapticManager.shared.light()
        }
    }
}

struct OccasionsPickerSheet: View {
    let itemId: String
    let currentOccasions: [String]
    @Environment(\.dismiss) var dismiss
    @State private var wardrobeService = WardrobeService.shared
    @State private var selectedOccasions: Set<String>

    private let commonOccasions = [
        "Casual", "Work", "Formal", "Party", "Wedding",
        "Date", "Travel", "Exercise", "Beach", "Dinner",
        "Brunch", "Outdoor", "Night Out", "Everyday"
    ]

    init(itemId: String, currentOccasions: [String]) {
        self.itemId = itemId
        self.currentOccasions = currentOccasions
        _selectedOccasions = State(initialValue: Set(currentOccasions))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(commonOccasions, id: \.self) { occasion in
                    Button {
                        if selectedOccasions.contains(occasion) {
                            selectedOccasions.remove(occasion)
                        } else {
                            selectedOccasions.insert(occasion)
                        }
                        saveOccasions()
                    } label: {
                        HStack {
                            Text(occasion)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            if selectedOccasions.contains(occasion) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.slate)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Occasions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func saveOccasions() {
        Task {
            let updates = WardrobeItemUpdate(occasions: Array(selectedOccasions))
            try? await wardrobeService.updateItem(id: itemId, updates: updates)
            HapticManager.shared.light()
        }
    }
}

struct SeasonsPickerSheet: View {
    let itemId: String
    let currentSeasons: [String]
    @Environment(\.dismiss) var dismiss
    @State private var wardrobeService = WardrobeService.shared
    @State private var selectedSeasons: Set<String>

    private let seasons = ["Spring", "Summer", "Fall", "Winter"]

    init(itemId: String, currentSeasons: [String]) {
        self.itemId = itemId
        self.currentSeasons = currentSeasons
        _selectedSeasons = State(initialValue: Set(currentSeasons))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(seasons, id: \.self) { season in
                    Button {
                        if selectedSeasons.contains(season) {
                            selectedSeasons.remove(season)
                        } else {
                            selectedSeasons.insert(season)
                        }
                        saveSeasons()
                    } label: {
                        HStack {
                            Text(season)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            if selectedSeasons.contains(season) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.slate)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Seasons")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func saveSeasons() {
        // Note: seasons updates not currently supported by API
        // This is a placeholder for when the API supports it
        HapticManager.shared.light()
    }
}

#Preview {
    ItemDetailScreen(itemId: "test")
        .environment(AppCoordinator())
}
