import SwiftUI
import UIKit
import Photos

// MARK: - Share Options Sheet

/// Premium share destination picker with format selection and Instagram integration
struct ShareOptionsSheet: View {
    let outfit: ScoredOutfit
    let items: [WardrobeItem]
    let onDismiss: () -> Void

    @State private var selectedFormat: ShareFormat = .stories
    @State private var renderedImage: UIImage?
    @State private var isRendering = false
    @State private var isSharing = false
    @State private var showSaveSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showLinkCopied = false

    private let api = StyleumAPI.shared
    private let gamificationService = GamificationService.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Preview Section
                previewSection
                    .padding(.top, AppSpacing.md)

                Spacer(minLength: AppSpacing.lg)

                // Format Picker
                formatPicker
                    .padding(.horizontal, AppSpacing.pageMargin)
                    .padding(.bottom, AppSpacing.lg)

                // Share Actions
                shareActions
                    .padding(.horizontal, AppSpacing.pageMargin)
                    .padding(.bottom, AppSpacing.xl)
            }
            .background(AppColors.background)
            .navigationTitle("Share Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
            }
        }
        .task {
            await renderPreview()
        }
        .onChange(of: selectedFormat) { _, _ in
            Task {
                await renderPreview()
            }
        }
        .alert("Saved!", isPresented: $showSaveSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Image saved to your photo library.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Preview Section

    @ViewBuilder
    private var previewSection: some View {
        ZStack {
            if isRendering {
                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                    .fill(AppColors.backgroundSecondary)
                    .aspectRatio(selectedFormat.aspectRatio, contentMode: .fit)
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.2)
                    )
            } else if let image = renderedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                    .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
            } else {
                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                    .fill(AppColors.backgroundSecondary)
                    .aspectRatio(selectedFormat.aspectRatio, contentMode: .fit)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                            Text("Preview unavailable")
                                .font(AppTypography.bodySmall)
                        }
                        .foregroundColor(AppColors.textMuted)
                    )
            }
        }
        .frame(maxHeight: 400)
        .padding(.horizontal, AppSpacing.pageMargin)
    }

    // MARK: - Format Picker

    private var formatPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("FORMAT")
                .font(AppTypography.kicker)
                .foregroundColor(AppColors.brownLight)
                .tracking(1)

            HStack(spacing: AppSpacing.sm) {
                FormatButton(
                    title: "Stories",
                    subtitle: "9:16",
                    icon: "rectangle.portrait",
                    isSelected: selectedFormat == .stories
                ) {
                    HapticManager.shared.selection()
                    selectedFormat = .stories
                }

                FormatButton(
                    title: "Square",
                    subtitle: "1:1",
                    icon: "square",
                    isSelected: selectedFormat == .square
                ) {
                    HapticManager.shared.selection()
                    selectedFormat = .square
                }
            }
        }
    }

    // MARK: - Share Actions

    private var shareActions: some View {
        VStack(spacing: AppSpacing.sm) {
            // Share to Instagram Stories
            if canOpenInstagramStories {
                Button {
                    Task {
                        await shareToInstagramStories()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Share to Stories")
                            .font(AppTypography.labelLarge)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(hex: "833AB4"),
                                Color(hex: "E1306C"),
                                Color(hex: "F77737")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(AppSpacing.radiusMd)
                }
                .disabled(isSharing || renderedImage == nil)
            }

            // More Options (Native Share Sheet)
            Button {
                Task {
                    await shareViaActivitySheet()
                }
            } label: {
                HStack(spacing: 10) {
                    if isSharing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(AppColors.textPrimary)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                    }
                    Text("More Options")
                        .font(AppTypography.labelLarge)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.backgroundSecondary)
                .foregroundColor(AppColors.textPrimary)
                .cornerRadius(AppSpacing.radiusMd)
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                        .stroke(AppColors.border, lineWidth: 1)
                )
            }
            .disabled(isSharing || renderedImage == nil)

            // Save to Photos
            Button {
                Task {
                    await saveToPhotos()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 16, weight: .medium))
                    Text("Save to Photos")
                        .font(AppTypography.labelLarge)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.backgroundSecondary)
                .foregroundColor(AppColors.textPrimary)
                .cornerRadius(AppSpacing.radiusMd)
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                        .stroke(AppColors.border, lineWidth: 1)
                )
            }
            .disabled(isSharing || renderedImage == nil)

            // Copy Link
            Button {
                Task {
                    await copyLinkToClipboard()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 16, weight: .medium))
                    Text(showLinkCopied ? "Link Copied!" : "Copy Link")
                        .font(AppTypography.labelLarge)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(showLinkCopied ? AppColors.brownLight.opacity(0.15) : AppColors.backgroundSecondary)
                .foregroundColor(showLinkCopied ? AppColors.brownPrimary : AppColors.textPrimary)
                .cornerRadius(AppSpacing.radiusMd)
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                        .stroke(showLinkCopied ? AppColors.brownPrimary : AppColors.border, lineWidth: 1)
                )
            }
            .disabled(isSharing)
        }
    }

    // MARK: - Actions

    private func renderPreview() async {
        isRendering = true
        defer { isRendering = false }

        renderedImage = await ShareCardRenderer.renderAsync(
            outfit: outfit,
            items: items,
            format: selectedFormat
        )
    }

    private var canOpenInstagramStories: Bool {
        guard let url = URL(string: "instagram-stories://share") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    private func shareToInstagramStories() async {
        guard let image = renderedImage,
              let imageData = image.pngData() else {
            errorMessage = "Could not prepare image for sharing."
            showError = true
            return
        }

        isSharing = true
        defer { isSharing = false }

        // Track share via API
        await trackShare(platform: "instagram_stories")

        // Copy image to pasteboard for Instagram
        let pasteboardItems: [[String: Any]] = [[
            "com.instagram.sharedSticker.backgroundImage": imageData
        ]]
        let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(60 * 5) // 5 minutes
        ]
        UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)

        // Open Instagram Stories
        if let url = URL(string: "instagram-stories://share?source_application=com.sameerstudios.Styleum") {
            await MainActor.run {
                UIApplication.shared.open(url)
            }
        }

        HapticManager.shared.success()
        onDismiss()
    }

    private func shareViaActivitySheet() async {
        guard let image = renderedImage else { return }

        isSharing = true

        // Track share via API
        await trackShare(platform: "other")

        await MainActor.run {
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
                let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
                let rootVC = keyWindow.rootViewController else {
                isSharing = false
                return
            }

            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }

            let shareItems: [Any] = [image]
            let activityVC = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)

            // iPad support
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topVC.view
                popover.sourceRect = CGRect(
                    x: topVC.view.bounds.midX,
                    y: topVC.view.bounds.maxY - 100,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = .down
            }

            activityVC.completionWithItemsHandler = { _, completed, _, _ in
                isSharing = false
                if completed {
                    HapticManager.shared.success()
                    onDismiss()
                }
            }

            topVC.present(activityVC, animated: true)
        }
    }

    private func saveToPhotos() async {
        guard let image = renderedImage else { return }

        isSharing = true
        defer { isSharing = false }

        // Request photo library permission
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            errorMessage = "Please allow photo library access in Settings."
            showError = true
            return
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.creationRequestForAsset(from: image)
            }

            // Track save as a share
            await trackShare(platform: "saved")

            HapticManager.shared.success()
            showSaveSuccess = true
        } catch {
            errorMessage = "Could not save image: \(error.localizedDescription)"
            showError = true
            HapticManager.shared.error()
        }
    }

    private func trackShare(platform: String) async {
        do {
            let response = try await api.trackOutfitShare(outfitId: outfit.id, platform: platform)
            print("📤 [Share] Tracked: platform=\(platform), xp=\(response.xpAwarded), total=\(response.totalShares)")

            // Track outfit shared event
            AnalyticsService.track(AnalyticsEvent.outfitShared, properties: [
                "platform": platform
            ])

            // Update gamification if XP was awarded
            if response.xpAwarded > 0 {
                await gamificationService.loadGamificationData()
                NotificationCenter.default.post(
                    name: .xpAwarded,
                    object: nil,
                    userInfo: ["xp": response.xpAwarded, "action": "share"]
                )
            }

            // Handle achievement unlock
            if let achievement = response.achievementUnlocked {
                NotificationCenter.default.post(
                    name: .achievementUnlocked,
                    object: nil,
                    userInfo: ["id": achievement.id, "name": achievement.name]
                )
            }
        } catch {
            print("⚠️ [Share] Failed to track: \(error)")
            // Don't block the share flow on tracking failure
        }
    }

    private func copyLinkToClipboard() async {
        do {
            let response = try await api.trackOutfitShare(outfitId: outfit.id, platform: "clipboard")

            if let url = response.shareUrl {
                UIPasteboard.general.string = url
                HapticManager.shared.success()

                withAnimation(.easeInOut(duration: 0.2)) {
                    showLinkCopied = true
                }

                // Reset after 2 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation(.easeInOut(duration: 0.2)) {
                    showLinkCopied = false
                }

                // Handle XP if awarded
                if response.xpAwarded > 0 {
                    await gamificationService.loadGamificationData()
                    NotificationCenter.default.post(
                        name: .xpAwarded,
                        object: nil,
                        userInfo: ["xp": response.xpAwarded, "action": "share"]
                    )
                }
            } else {
                errorMessage = "Share link not available yet."
                showError = true
            }
        } catch {
            errorMessage = "Could not generate share link."
            showError = true
        }
    }
}

// MARK: - Format Button

private struct FormatButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .light))

                VStack(spacing: 2) {
                    Text(title)
                        .font(AppTypography.labelMedium)
                    Text(subtitle)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? AppColors.brownLight.opacity(0.15) : AppColors.backgroundSecondary)
            .foregroundColor(isSelected ? AppColors.brownPrimary : AppColors.textSecondary)
            .cornerRadius(AppSpacing.radiusMd)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                    .stroke(isSelected ? AppColors.brownPrimary : AppColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notification Names Extension

extension Notification.Name {
    static let xpAwarded = Notification.Name("xpAwarded")
}

// MARK: - Preview

#Preview {
    ShareOptionsSheet(
        outfit: ScoredOutfit(
            id: "preview",
            wardrobeItemIds: ["1", "2"],
            score: 87,
            whyItWorks: "Great combination",
            stylingTip: nil,
            vibes: ["casual"],
            occasion: "Weekend brunch",
            headline: "Weekend Vibes",
            colorHarmony: "complementary",
            vibe: "Casual Cool"
        ),
        items: [],
        onDismiss: {}
    )
}
