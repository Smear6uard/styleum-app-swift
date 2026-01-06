import SwiftUI
import PhotosUI

// MARK: - Upload Item Model
struct UploadItem: Identifiable {
    let id = UUID()
    let image: UIImage
    var name: String = ""
    var category: ClothingCategory = .tops
}

struct AddItemSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var wardrobeService = WardrobeService.shared

    // Photo selection
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showCamera = false

    // Carousel state
    @State private var uploadItems: [UploadItem] = []
    @State private var currentIndex: Int = 0

    // Upload tracking
    @State private var uploadingIds: Set<UUID> = []
    @State private var completedIds: Set<UUID> = []
    @State private var failedIds: Set<UUID> = []

    // UI state
    @State private var uploadError: String?
    @State private var showCompletion = false
    @State private var completionMessage = ""

    // Animation states
    @State private var imageScale: CGFloat = 0.8
    @State private var imageOpacity: Double = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Drag indicator
                Capsule()
                    .fill(AppColors.border)
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, AppSpacing.md)

                if !uploadItems.isEmpty {
                    // Carousel view
                    carouselView
                } else {
                    // Empty state - photo selection
                    emptyStateView
                }
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.light()
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(image: Binding(
                    get: { nil },
                    set: { newImage in
                        if let image = newImage {
                            imageScale = 0.8
                            imageOpacity = 0
                            uploadItems = [UploadItem(image: image)]
                            currentIndex = 0
                        }
                    }
                ))
                    .ignoresSafeArea()
            }
            .onChange(of: selectedPhotoItems) { _, items in
                Task {
                    imageScale = 0.8
                    imageOpacity = 0

                    var newItems: [UploadItem] = []
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            newItems.append(UploadItem(image: image))
                        }
                    }
                    uploadItems = newItems
                    currentIndex = 0
                    if !newItems.isEmpty {
                        HapticManager.shared.medium()
                    }
                }
            }
            .overlay {
                if showCompletion {
                    completionOverlay
                }
            }
        }
        .interactiveDismissDisabled(!uploadingIds.isEmpty)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Carousel View

    private var carouselView: some View {
        VStack(spacing: 0) {
            // Progress dots
            if uploadItems.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<uploadItems.count, id: \.self) { index in
                        Circle()
                            .fill(dotColor(for: index))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.vertical, AppSpacing.md)
            }

            // Carousel
            TabView(selection: $currentIndex) {
                ForEach(Array(uploadItems.enumerated()), id: \.element.id) { index, item in
                    carouselItemView(index: index, item: item)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .scaleEffect(imageScale)
            .opacity(imageOpacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    imageScale = 1.0
                    imageOpacity = 1.0
                }
            }

            Spacer()

            // Bottom action area
            bottomActionArea
        }
    }

    private func carouselItemView(index: Int, item: UploadItem) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Image preview
                Image(uiImage: item.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 260)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusLg))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                // Name field
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("NAME")
                        .font(AppTypography.kicker)
                        .foregroundColor(AppColors.textMuted)
                        .tracking(1)

                    TextField("Name (optional)", text: $uploadItems[index].name)
                        .font(AppTypography.bodyLarge)
                        .padding()
                        .background(AppColors.inputBackground)
                        .cornerRadius(AppSpacing.radiusMd)
                }

                // Category picker
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("CATEGORY")
                        .font(AppTypography.kicker)
                        .foregroundColor(AppColors.textMuted)
                        .tracking(1)

                    Menu {
                        ForEach(ClothingCategory.allCases) { category in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    uploadItems[index].category = category
                                }
                                HapticManager.shared.selection()
                            } label: {
                                if uploadItems[index].category == category {
                                    Label(category.displayName, systemImage: "checkmark")
                                } else {
                                    Text(category.displayName)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(symbol: uploadItems[index].category.iconSymbol)
                                .font(.system(size: 18))
                            Text(uploadItems[index].category.displayName)
                                .font(AppTypography.bodyLarge)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textMuted)
                        }
                        .foregroundColor(AppColors.textPrimary)
                        .padding()
                        .background(AppColors.inputBackground)
                        .cornerRadius(AppSpacing.radiusMd)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.pageMargin)
            .padding(.top, AppSpacing.sm)
        }
    }

    private var bottomActionArea: some View {
        VStack(spacing: AppSpacing.sm) {
            if let error = uploadError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppColors.danger)
                    Text(error)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.danger)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Save & Next / Save & Done button
            Button {
                saveAndAdvance()
            } label: {
                HStack(spacing: 8) {
                    if isCurrentItemUploading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(saveButtonText)
                        .font(AppTypography.labelMedium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.black)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
            }
            .disabled(isCurrentItemUploading || hasCurrentItemBeenSaved)
            .buttonStyle(ScaleButtonStyle())

            // Start over button
            Button {
                clearAll()
            } label: {
                Text("Start Over")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(AppSpacing.pageMargin)
        .background(
            Rectangle()
                .fill(AppColors.background)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -4)
        )
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            VStack(spacing: AppSpacing.sm) {
                Text("Add to closet")
                    .font(AppTypography.headingLarge)
                    .foregroundColor(AppColors.textPrimary)

                Text("Add a few pieces — the AI gets better fast.")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: AppSpacing.md) {
                Button {
                    showCamera = true
                    HapticManager.shared.medium()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Take Photo")
                            .font(AppTypography.labelLarge)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.black)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                }
                .buttonStyle(ScaleButtonStyle())

                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 10,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Add with Photos")
                            .font(AppTypography.labelLarge)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                            .stroke(AppColors.border, lineWidth: 1.5)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, AppSpacing.xl)

            Spacer()

            VStack(spacing: AppSpacing.xs) {
                Text("TIPS FOR BEST RESULTS")
                    .font(AppTypography.kicker)
                    .foregroundColor(AppColors.textMuted)
                    .tracking(1)

                VStack(spacing: 4) {
                    Text("Lay flat on a plain background")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)

                    Text("Good lighting • One item per photo")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.bottom, AppSpacing.xl)
        }
        .padding(.horizontal, AppSpacing.pageMargin)
    }

    // MARK: - Completion Overlay

    private var completionOverlay: some View {
        VStack {
            Spacer()
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)

                Text(completionMessage)
                    .font(AppTypography.headingMedium)
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(AppSpacing.xl)
            .background(AppColors.background)
            .cornerRadius(AppSpacing.radiusLg)
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
        .transition(.opacity)
    }

    // MARK: - Helper Properties

    private var isCurrentItemUploading: Bool {
        guard currentIndex < uploadItems.count else { return false }
        return uploadingIds.contains(uploadItems[currentIndex].id)
    }

    private var hasCurrentItemBeenSaved: Bool {
        guard currentIndex < uploadItems.count else { return false }
        let itemId = uploadItems[currentIndex].id
        return completedIds.contains(itemId) || uploadingIds.contains(itemId)
    }

    private var saveButtonText: String {
        if hasCurrentItemBeenSaved {
            return "Saved"
        } else if currentIndex == uploadItems.count - 1 {
            return "Save & Done"
        } else {
            return "Save & Next"
        }
    }

    private func dotColor(for index: Int) -> Color {
        let itemId = uploadItems[index].id
        if completedIds.contains(itemId) {
            return .green
        } else if failedIds.contains(itemId) {
            return AppColors.danger
        } else if index == currentIndex {
            return AppColors.textPrimary
        } else {
            return AppColors.border
        }
    }

    // MARK: - Actions

    private func saveAndAdvance() {
        guard currentIndex < uploadItems.count else { return }

        let item = uploadItems[currentIndex]
        uploadingIds.insert(item.id)
        uploadError = nil
        HapticManager.shared.light()

        // Start background upload
        Task {
            do {
                _ = try await wardrobeService.addItem(
                    image: item.image,
                    category: item.category,
                    name: item.name.isEmpty ? nil : item.name
                )
                completedIds.insert(item.id)
                HapticManager.shared.success()
            } catch {
                failedIds.insert(item.id)
                await MainActor.run {
                    uploadError = "Failed to save item"
                }
                HapticManager.shared.error()
            }
            uploadingIds.remove(item.id)

            // Check if all done
            await checkCompletion()
        }

        // Advance immediately (don't wait for upload)
        if currentIndex < uploadItems.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex += 1
            }
        } else {
            // Last item - will show completion when upload finishes
        }
    }

    private func checkCompletion() async {
        // If all items have been processed (completed or failed)
        let allProcessed = uploadItems.allSatisfy { item in
            completedIds.contains(item.id) || failedIds.contains(item.id)
        }

        if allProcessed {
            let successCount = completedIds.count
            let failedCount = failedIds.count

            await MainActor.run {
                if successCount > 0 {
                    completionMessage = "\(successCount) item\(successCount == 1 ? "" : "s") added!"
                    withAnimation {
                        showCompletion = true
                    }
                    HapticManager.shared.achievementUnlock()

                    // Dismiss after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                } else if failedCount > 0 {
                    uploadError = "All uploads failed"
                }
            }
        }
    }

    private func clearAll() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            imageScale = 0.8
            imageOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            uploadItems = []
            selectedPhotoItems = []
            currentIndex = 0
            uploadingIds = []
            completedIds = []
            failedIds = []
            uploadError = nil
        }
        HapticManager.shared.light()
    }
}

#Preview {
    AddItemSheet()
}
