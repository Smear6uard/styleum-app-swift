import SwiftUI
import PhotosUI

struct AddItemSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var wardrobeService = WardrobeService.shared

    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var selectedCategory: ClothingCategory = .top
    @State private var isUploading = false
    @State private var uploadError: String?

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

                if let image = selectedImage {
                    // Image selected - show preview and upload
                    ScrollView {
                        VStack(spacing: AppSpacing.lg) {
                            // Image preview with animation
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 280)
                                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusLg))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                .scaleEffect(imageScale)
                                .opacity(imageOpacity)
                                .onAppear {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        imageScale = 1.0
                                        imageOpacity = 1.0
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        clearImage()
                                    } label: {
                                        Label("Remove Photo", systemImage: "trash")
                                    }

                                    Button {
                                        showCamera = true
                                    } label: {
                                        Label("Retake Photo", systemImage: "camera")
                                    }
                                }

                            // Category picker
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("CATEGORY")
                                    .font(AppTypography.kicker)
                                    .foregroundColor(AppColors.textMuted)
                                    .tracking(1)

                                Menu {
                                    ForEach(ClothingCategory.allCases) { category in
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                selectedCategory = category
                                            }
                                            HapticManager.shared.selection()
                                        } label: {
                                            if selectedCategory == category {
                                                Label(category.displayName, systemImage: "checkmark")
                                            } else {
                                                Text(category.displayName)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(symbol: selectedCategory.iconSymbol)
                                            .font(.system(size: 18))
                                        Text(selectedCategory.displayName)
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
                    }

                    Spacer()

                    // Upload section
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

                        Button {
                            Task {
                                await uploadItem()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if isUploading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                Text(isUploading ? "Analyzing..." : "Add to Wardrobe")
                                    .font(AppTypography.labelMedium)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.black)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                        }
                        .disabled(isUploading)
                        .buttonStyle(ScaleButtonStyle())

                        Button {
                            clearImage()
                        } label: {
                            Text("Choose Different Photo")
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

                } else {
                    // No image selected - show empty state
                    VStack(spacing: AppSpacing.xl) {
                        Spacer()

                        // Headline
                        VStack(spacing: AppSpacing.sm) {
                            Text("Add to closet")
                                .font(AppTypography.headingLarge)
                                .foregroundColor(AppColors.textPrimary)

                            Text("Add a few pieces — the AI gets better fast.")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        // Photo options
                        VStack(spacing: AppSpacing.md) {
                            // Camera button - primary
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

                            // Photo library
                            PhotosPicker(
                                selection: $selectedPhotoItem,
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

                        // Tips section
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

                                Text("Full-body photos can add multiple items")
                                    .font(AppTypography.bodySmall)
                                    .foregroundColor(AppColors.textMuted)
                                    .italic()
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.bottom, AppSpacing.xl)
                    }
                    .padding(.horizontal, AppSpacing.pageMargin)
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
                CameraView(image: $selectedImage)
                    .ignoresSafeArea()
            }
            .onChange(of: selectedPhotoItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        // Reset animation states
                        imageScale = 0.8
                        imageOpacity = 0
                        selectedImage = image
                        HapticManager.shared.medium()
                    }
                }
            }
        }
        .interactiveDismissDisabled(isUploading)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private func clearImage() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            imageScale = 0.8
            imageOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            selectedImage = nil
        }
        HapticManager.shared.light()
    }

    private func uploadItem() async {
        guard let image = selectedImage else { return }

        isUploading = true
        uploadError = nil
        HapticManager.shared.light()

        do {
            let _ = try await wardrobeService.addItem(image: image, category: selectedCategory)
            HapticManager.shared.achievementUnlock()
            dismiss()
        } catch {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                uploadError = error.localizedDescription
            }
            HapticManager.shared.error()
        }

        isUploading = false
    }
}

#Preview {
    AddItemSheet()
}
