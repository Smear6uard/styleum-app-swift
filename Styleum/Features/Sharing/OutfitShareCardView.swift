import SwiftUI
import Kingfisher

// MARK: - Outfit Share Card View
/// A 1080x1920 pixel card designed for sharing to Instagram Stories, iMessage, etc.
struct OutfitShareCardView: View {
    let outfit: ScoredOutfit
    let items: [WardrobeItem]
    let occasion: String?

    // Card dimensions (9:16 aspect ratio for Stories)
    private let cardWidth: CGFloat = 1080
    private let cardHeight: CGFloat = 1920

    var body: some View {
        ZStack {
            // Background gradient - dark editorial aesthetic
            LinearGradient(
                colors: [Color(hex: "0A0A0A"), Color(hex: "1A1A1A")],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                // Top branding area
                VStack(spacing: 24) {
                    // Styleum wordmark
                    Text("STYLEUM")
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .tracking(8)
                        .foregroundColor(.white.opacity(0.9))

                    // Occasion/context label
                    if let occasion = occasion, !occasion.isEmpty {
                        Text(occasion.uppercased())
                            .font(.system(size: 14, weight: .medium))
                            .tracking(3)
                            .foregroundColor(.white.opacity(0.5))
                    } else {
                        Text("TODAY'S LOOK")
                            .font(.system(size: 14, weight: .medium))
                            .tracking(3)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.top, 80)

                Spacer()

                // Outfit items grid
                OutfitShareItemsGrid(items: items)
                    .padding(.horizontal, 60)

                Spacer()

                // Bottom info area
                VStack(spacing: 32) {
                    // Score badge (if score exists)
                    if outfit.score > 0 {
                        OutfitScoreBadge(score: outfit.score)
                    }

                    // Vibe/headline
                    if let headline = outfit.headline, !headline.isEmpty {
                        Text(headline)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 60)
                    } else if let vibe = outfit.vibe, !vibe.isEmpty {
                        Text(vibe)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }

                    // Date stamp
                    Text(Date().formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))

                    // Footer branding
                    HStack(spacing: 8) {
                        Text("styled with")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.3))
                        Text("styleum")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.bottom, 80)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}

// MARK: - Outfit Share Items Grid
/// Displays outfit items in an appealing layout based on item count
struct OutfitShareItemsGrid: View {
    let items: [WardrobeItem]

    // Size constants for the share card
    private let largeItemSize: CGFloat = 400
    private let mediumItemSize: CGFloat = 280
    private let smallItemSize: CGFloat = 200
    private let spacing: CGFloat = 16

    var body: some View {
        let displayItems = Array(items.prefix(6))

        if displayItems.isEmpty {
            // Empty state placeholder
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.1))
                .frame(width: 400, height: 520)
                .overlay(
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.white.opacity(0.2))
                )
        } else {
            switch displayItems.count {
            case 1:
                // Single large item
                ShareItemImage(item: displayItems[0])
                    .frame(width: largeItemSize, height: 520)

            case 2:
                // Two items stacked vertically
                VStack(spacing: spacing) {
                    ForEach(displayItems, id: \.id) { item in
                        ShareItemImage(item: item)
                            .frame(height: 300)
                    }
                }
                .frame(width: largeItemSize)

            case 3:
                // One large + two small
                HStack(alignment: .center, spacing: spacing) {
                    ShareItemImage(item: displayItems[0])
                        .frame(width: mediumItemSize, height: 400)

                    VStack(spacing: spacing) {
                        ShareItemImage(item: displayItems[1])
                            .frame(width: smallItemSize, height: 192)
                        ShareItemImage(item: displayItems[2])
                            .frame(width: smallItemSize, height: 192)
                    }
                }

            case 4:
                // 2x2 grid
                VStack(spacing: spacing) {
                    HStack(spacing: spacing) {
                        ShareItemImage(item: displayItems[0])
                            .frame(width: mediumItemSize, height: 300)
                        ShareItemImage(item: displayItems[1])
                            .frame(width: mediumItemSize, height: 300)
                    }
                    HStack(spacing: spacing) {
                        ShareItemImage(item: displayItems[2])
                            .frame(width: mediumItemSize, height: 300)
                        ShareItemImage(item: displayItems[3])
                            .frame(width: mediumItemSize, height: 300)
                    }
                }

            default:
                // 5-6 items: asymmetric grid
                HStack(alignment: .center, spacing: spacing) {
                    // Left column - 2 larger items
                    VStack(spacing: spacing) {
                        ShareItemImage(item: displayItems[0])
                            .frame(width: mediumItemSize, height: 280)
                        ShareItemImage(item: displayItems[1])
                            .frame(width: mediumItemSize, height: 280)
                    }

                    // Right column - smaller items
                    VStack(spacing: spacing) {
                        ForEach(Array(displayItems.dropFirst(2).prefix(3)), id: \.id) { item in
                            ShareItemImage(item: item)
                                .frame(width: smallItemSize, height: 180)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Share Item Image
/// Individual item image with rounded corners for the share card
struct ShareItemImage: View {
    let item: WardrobeItem

    private var imageUrl: String? {
        item.photoUrlClean ?? item.photoUrl
    }

    var body: some View {
        GeometryReader { geo in
            if let urlString = imageUrl, let url = URL(string: urlString) {
                KFImage(url)
                    .placeholder {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.3))
                    )
            }
        }
    }
}

// MARK: - Outfit Score Badge
/// Displays the outfit score as a circular badge
struct OutfitScoreBadge: View {
    let score: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .semibold))
            Text("\(score)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text("/ 100")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.15))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview
#Preview {
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
        occasion: "Weekend brunch"
    )
    .scaleEffect(0.2)
    .frame(width: 216, height: 384)
}
