import UIKit
import SwiftUI

// MARK: - Share Service
/// Handles sharing outfits as branded image cards via the native share sheet
@Observable
@MainActor
final class ShareService {
    static let shared = ShareService()

    private(set) var isSharing = false

    private init() {}

    /// Share an outfit as an image card
    /// - Parameters:
    ///   - outfit: The scored outfit to share
    ///   - items: The wardrobe items in the outfit
    ///   - occasion: Optional occasion context
    ///   - from: The view controller to present the share sheet from
    func shareOutfit(
        outfit: ScoredOutfit,
        items: [WardrobeItem],
        occasion: String? = nil,
        from viewController: UIViewController
    ) async {
        isSharing = true
        defer { isSharing = false }

        // Render the card to image
        guard let image = await ShareCardRenderer.renderAsync(
            outfit: outfit,
            items: items,
            occasion: occasion
        ) else {
            print("ShareService: Failed to render share card")
            HapticManager.shared.error()
            return
        }

        // Present share sheet
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        // Exclude irrelevant activities
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks,
            .print
        ]

        // Track when share completes
        activityVC.completionWithItemsHandler = { activity, completed, _, error in
            Task { @MainActor in
                if completed {
                    await self.handleShareCompleted()
                }
            }
        }

        // iPad popover support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        viewController.present(activityVC, animated: true)
    }

    /// Handle successful share completion
    private func handleShareCompleted() async {
        // Share tracking is handled implicitly by the API
        // Success haptic for share completion
        HapticManager.shared.success()
    }
}
