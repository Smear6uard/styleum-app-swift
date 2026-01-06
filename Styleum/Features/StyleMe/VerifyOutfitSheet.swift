import SwiftUI
import AVFoundation

struct VerifyOutfitSheet: View {
    let outfit: ScoredOutfit
    let onVerify: (UIImage) -> Void
    let onSkip: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var selectedImage: UIImage?
    @State private var showCameraPermissionAlert = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Handle indicator
            Capsule()
                .fill(AppColors.textMuted.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, AppSpacing.sm)

            // Header
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: "camera.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AppColors.black)

                Text("Verify your look")
                    .font(AppTypography.headingMedium)
                    .foregroundColor(AppColors.textPrimary)

                Text("Take a photo wearing this outfit for 2x XP")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, AppSpacing.md)

            Spacer()

            // Action buttons
            VStack(spacing: AppSpacing.sm) {
                // Camera button
                Button {
                    checkCameraPermission()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16, weight: .medium))
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

                // Photo library button
                Button {
                    showPhotoLibrary = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 16, weight: .medium))
                        Text("Choose from Library")
                            .font(AppTypography.labelLarge)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.filterTagBg)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, AppSpacing.pageMargin)

            // Skip link
            Button {
                HapticManager.shared.light()
                onSkip()
                dismiss()
            } label: {
                Text("Skip · Get 1x XP")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .underline()
            }
            .padding(.top, AppSpacing.xs)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(source: .camera, selectedImage: $selectedImage)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showPhotoLibrary) {
            ImagePicker(source: .photoLibrary, selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                HapticManager.shared.success()
                onVerify(image)
                dismiss()
            }
        }
        .alert("Camera Access Required", isPresented: $showCameraPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable camera access in Settings to take a verification photo.")
        }
    }

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCamera = true
                    }
                }
            }
        case .denied, .restricted:
            showCameraPermissionAlert = true
        @unknown default:
            break
        }
    }
}

#Preview {
    VerifyOutfitSheet(
        outfit: ScoredOutfit(
            id: "test",
            wardrobeItemIds: [],
            score: 85,
            whyItWorks: "Test outfit"
        ),
        onVerify: { _ in },
        onSkip: {}
    )
}
