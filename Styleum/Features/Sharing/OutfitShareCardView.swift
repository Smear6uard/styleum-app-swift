import SwiftUI
import Kingfisher

// MARK: - Share Format

enum ShareFormat {
    case stories  // 9:16 - 1080x1920
    case square   // 1:1 - 1080x1080
    case poster   // 4:5 - 1080x1350 (NEW)

    var size: CGSize {
        switch self {
        case .stories: return CGSize(width: 1080, height: 1920)
        case .square: return CGSize(width: 1080, height: 1080)
        case .poster: return CGSize(width: 1080, height: 1350)
        }
    }

    var aspectRatio: CGFloat {
        switch self {
        case .stories: return 9 / 16
        case .square: return 1
        case .poster: return 4 / 5
        }
    }
}

// MARK: - Outfit Share Card View

/// Premium, editorial share card with dark canvas drop aesthetic
/// Design principles: Outfit is the star, bold typography, fashion magazine aesthetic
struct OutfitShareCardView: View {
    let outfit: ScoredOutfit
    let items: [WardrobeItem]
    let format: ShareFormat

    // Computed style properties
    private var styleScore: Int {
        outfit.score
    }

    private var headline: String {
        outfit.headline ?? "Today's Look"
    }

    private var vibe: String {
        outfit.vibe ?? outfit.occasion ?? "Styled for you"
    }

    // Format-dependent sizing
    private var topPadding: CGFloat {
        switch format {
        case .stories: return 100
        case .poster: return 80
        case .square: return 60
        }
    }

    private var bottomPadding: CGFloat {
        switch format {
        case .stories: return 60
        case .poster: return 50
        case .square: return 40
        }
    }

    private var horizontalPadding: CGFloat {
        switch format {
        case .stories: return 48
        case .poster: return 40
        case .square: return 32
        }
    }

    private var headlineFontSize: CGFloat {
        switch format {
        case .stories: return 28
        case .poster: return 24
        case .square: return 20
        }
    }

    private var itemAreaHeight: CGFloat {
        switch format {
        case .stories: return format.size.height * 0.55
        case .poster: return format.size.height * 0.58
        case .square: return format.size.height * 0.55
        }
    }

    var body: some View {
        ZStack {
            // Dark canvas background
            Color(hex: "0A0A0A")

            // Noise texture overlay
            noiseOverlay
                .opacity(0.04)

            VStack(spacing: 0) {
                // Top spacing
                Spacer().frame(height: topPadding)

                // Pyramid items display
                pyramidItemsLayout
                    .frame(height: itemAreaHeight)
                    .padding(.horizontal, horizontalPadding)

                Spacer()

                // Typography section
                VStack(spacing: 12) {
                    // Headline (all caps, tracked)
                    Text(headline.uppercased())
                        .font(.system(size: headlineFontSize, weight: .semibold))
                        .tracking(4)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    // Match score and vibe
                    HStack(spacing: 8) {
                        Text("\(styleScore)% match")
                        Text("\u{00B7}")
                        Text(vibe.lowercased())
                    }
                    .font(.system(size: format == .square ? 12 : 14))
                    .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 32)

                Spacer()
                    .frame(height: format == .stories ? 60 : 40)

                // Footer with watermark
                footerView
                    .padding(.horizontal, 32)
                    .padding(.bottom, bottomPadding)
            }
        }
        .frame(width: format.size.width, height: format.size.height)
    }

    // MARK: - Noise Overlay

    private var noiseOverlay: some View {
        Canvas { context, size in
            for x in stride(from: 0, to: Int(size.width), by: 4) {
                for y in stride(from: 0, to: Int(size.height), by: 4) {
                    let grayscale = Double.random(in: 0...1)
                    context.fill(
                        Path(CGRect(x: CGFloat(x), y: CGFloat(y), width: 4, height: 4)),
                        with: .color(.white.opacity(grayscale))
                    )
                }
            }
        }
    }

    // MARK: - Pyramid Items Layout

    @ViewBuilder
    private var pyramidItemsLayout: some View {
        let displayItems = Array(items.prefix(7))
        let gap: CGFloat = format == .square ? 12 : 16

        GeometryReader { geometry in
            let containerWidth = geometry.size.width

            VStack(spacing: gap) {
                switch displayItems.count {
                case 0:
                    emptyItemsState

                case 1:
                    // Single centered item
                    shareItemCard(displayItems[0])
                        .frame(width: containerWidth * 0.6, height: containerWidth * 0.65)

                case 2:
                    // Two items side by side
                    HStack(spacing: gap) {
                        ForEach(displayItems, id: \.id) { item in
                            shareItemCard(item)
                        }
                    }
                    .frame(height: containerWidth * 0.5)

                case 3:
                    // Classic pyramid: 1 top, 2 bottom
                    VStack(spacing: gap) {
                        shareItemCard(displayItems[0])
                            .frame(width: containerWidth * 0.45, height: containerWidth * 0.5)

                        HStack(spacing: gap) {
                            ForEach(displayItems.dropFirst().prefix(2), id: \.id) { item in
                                shareItemCard(item)
                                    .frame(width: containerWidth * 0.38, height: containerWidth * 0.4)
                            }
                        }
                    }

                case 4:
                    // 1 top, 2 middle, 1 bottom
                    VStack(spacing: gap) {
                        shareItemCard(displayItems[0])
                            .frame(width: containerWidth * 0.45, height: containerWidth * 0.38)

                        HStack(spacing: gap) {
                            ForEach(displayItems.dropFirst().prefix(2), id: \.id) { item in
                                shareItemCard(item)
                                    .frame(width: containerWidth * 0.38, height: containerWidth * 0.32)
                            }
                        }

                        shareItemCard(displayItems[3])
                            .frame(width: containerWidth * 0.32, height: containerWidth * 0.28)
                    }

                case 5:
                    // 1 top, 2 middle, 2 bottom
                    VStack(spacing: gap) {
                        shareItemCard(displayItems[0])
                            .frame(width: containerWidth * 0.45, height: containerWidth * 0.35)

                        HStack(spacing: gap) {
                            ForEach(displayItems.dropFirst().prefix(2), id: \.id) { item in
                                shareItemCard(item)
                                    .frame(width: containerWidth * 0.38, height: containerWidth * 0.28)
                            }
                        }

                        HStack(spacing: gap) {
                            ForEach(displayItems.dropFirst(3).prefix(2), id: \.id) { item in
                                shareItemCard(item)
                                    .frame(width: containerWidth * 0.30, height: containerWidth * 0.24)
                            }
                        }
                    }

                default: // 6-7 items
                    // 1 top, 2 middle, 3+ bottom
                    VStack(spacing: gap) {
                        shareItemCard(displayItems[0])
                            .frame(width: containerWidth * 0.42, height: containerWidth * 0.32)

                        HStack(spacing: gap) {
                            ForEach(displayItems.dropFirst().prefix(2), id: \.id) { item in
                                shareItemCard(item)
                                    .frame(width: containerWidth * 0.35, height: containerWidth * 0.26)
                            }
                        }

                        HStack(spacing: gap) {
                            ForEach(displayItems.dropFirst(3).prefix(3), id: \.id) { item in
                                shareItemCard(item)
                                    .frame(width: containerWidth * 0.28, height: containerWidth * 0.22)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var emptyItemsState: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.1))
            .frame(width: 300, height: 350)
            .overlay(
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(0.2))
            )
    }

    private func shareItemCard(_ item: WardrobeItem) -> some View {
        ZStack {
            // White card background
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)

            // Item image
            KFImage(URL(string: item.photoUrlClean ?? item.photoUrl ?? ""))
                .placeholder {
                    Image(systemName: "tshirt")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "CCCCCC"))
                }
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Spacer()

            // STYLEUM watermark (bottom right, 30% opacity white)
            Text("STYLEUM")
                .font(.system(size: format == .square ? 14 : 16, weight: .bold))
                .tracking(3)
                .foregroundColor(.white.opacity(0.3))
        }
    }
}

// MARK: - Legacy Initializer (for backward compatibility)

extension OutfitShareCardView {
    /// Legacy initializer that defaults to Stories format
    init(outfit: ScoredOutfit, items: [WardrobeItem], occasion: String?) {
        self.outfit = outfit
        self.items = items
        self.format = .stories
    }
}

// MARK: - Preview

#Preview("Stories Format") {
    OutfitShareCardView(
        outfit: ScoredOutfit(
            id: "preview",
            wardrobeItemIds: ["1", "2", "3"],
            score: 87,
            whyItWorks: "The colors complement each other beautifully",
            stylingTip: "Add a watch for extra polish",
            vibes: ["casual", "modern"],
            occasion: "Weekend brunch",
            headline: "Effortlessly Cool",
            colorHarmony: "complementary",
            vibe: "Modern Minimalist"
        ),
        items: [],
        format: .stories
    )
    .scaleEffect(0.2)
    .frame(width: 216, height: 384)
}

#Preview("Poster Format (4:5)") {
    OutfitShareCardView(
        outfit: ScoredOutfit(
            id: "preview",
            wardrobeItemIds: ["1", "2", "3", "4"],
            score: 91,
            whyItWorks: "Editorial style harmony",
            stylingTip: nil,
            vibes: ["streetwear"],
            occasion: "Daily wear",
            headline: "Today's Drop",
            colorHarmony: "monochromatic",
            vibe: "Streetwear"
        ),
        items: [],
        format: .poster
    )
    .scaleEffect(0.25)
    .frame(width: 270, height: 337.5)
}

#Preview("Square Format") {
    OutfitShareCardView(
        outfit: ScoredOutfit(
            id: "preview",
            wardrobeItemIds: ["1", "2"],
            score: 92,
            whyItWorks: "Perfect color harmony",
            stylingTip: nil,
            vibes: ["elegant"],
            occasion: "Date night",
            headline: "Date Night Ready",
            colorHarmony: "analogous",
            vibe: "Elegant Chic"
        ),
        items: [],
        format: .square
    )
    .scaleEffect(0.3)
    .frame(width: 324, height: 324)
}
