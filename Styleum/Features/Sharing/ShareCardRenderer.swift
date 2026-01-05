import SwiftUI
import UIKit

// MARK: - Share Card Renderer
/// Converts the OutfitShareCardView to a UIImage for sharing
@MainActor
struct ShareCardRenderer {

    /// Render an outfit share card to a UIImage
    /// - Parameters:
    ///   - outfit: The scored outfit to render
    ///   - items: The wardrobe items in the outfit
    ///   - occasion: Optional occasion context
    /// - Returns: A UIImage of the rendered card, or nil if rendering fails
    static func render(
        outfit: ScoredOutfit,
        items: [WardrobeItem],
        occasion: String? = nil
    ) -> UIImage? {
        let cardView = OutfitShareCardView(
            outfit: outfit,
            items: items,
            occasion: occasion ?? outfit.occasion
        )

        let renderer = ImageRenderer(content: cardView)

        // Render at 1x scale since we're already at 1080x1920
        renderer.scale = 1.0

        // Ensure proper rendering environment
        renderer.proposedSize = ProposedViewSize(
            width: 1080,
            height: 1920
        )

        return renderer.uiImage
    }

    /// Render an outfit share card asynchronously with image loading
    /// - Parameters:
    ///   - outfit: The scored outfit to render
    ///   - items: The wardrobe items in the outfit
    ///   - occasion: Optional occasion context
    /// - Returns: A UIImage of the rendered card, or nil if rendering fails
    static func renderAsync(
        outfit: ScoredOutfit,
        items: [WardrobeItem],
        occasion: String? = nil
    ) async -> UIImage? {
        // Allow time for images to load via Kingfisher cache
        // In production, images should already be cached from viewing
        try? await Task.sleep(for: .milliseconds(100))

        return render(outfit: outfit, items: items, occasion: occasion)
    }
}
