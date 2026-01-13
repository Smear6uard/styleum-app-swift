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
    ///   - format: The share format (Stories 9:16 or Square 1:1)
    /// - Returns: A UIImage of the rendered card, or nil if rendering fails
    static func render(
        outfit: ScoredOutfit,
        items: [WardrobeItem],
        occasion: String? = nil,
        format: ShareFormat = .stories
    ) -> UIImage? {
        let cardView = OutfitShareCardView(
            outfit: outfit,
            items: items,
            format: format
        )

        let renderer = ImageRenderer(content: cardView)

        // Render at 1x scale since we're already at full resolution
        renderer.scale = 1.0

        // Use format-specific size
        renderer.proposedSize = ProposedViewSize(
            width: format.size.width,
            height: format.size.height
        )

        return renderer.uiImage
    }

    /// Render an outfit share card asynchronously with image loading
    /// - Parameters:
    ///   - outfit: The scored outfit to render
    ///   - items: The wardrobe items in the outfit
    ///   - occasion: Optional occasion context
    ///   - format: The share format (Stories 9:16 or Square 1:1)
    /// - Returns: A UIImage of the rendered card, or nil if rendering fails
    static func renderAsync(
        outfit: ScoredOutfit,
        items: [WardrobeItem],
        occasion: String? = nil,
        format: ShareFormat = .stories
    ) async -> UIImage? {
        // Allow time for images to load via Kingfisher cache
        // In production, images should already be cached from viewing
        try? await Task.sleep(for: .milliseconds(100))

        return render(outfit: outfit, items: items, occasion: occasion, format: format)
    }
}
