import SwiftUI
import Kingfisher

// MARK: - Share Format

enum ShareFormat {
    case stories  // 9:16 - 1080x1920
    case square   // 1:1 - 1080x1080

    var size: CGSize {
        switch self {
        case .stories: return CGSize(width: 1080, height: 1920)
        case .square: return CGSize(width: 1080, height: 1080)
        }
    }

    var aspectRatio: CGFloat {
        switch self {
        case .stories: return 9 / 16
        case .square: return 1
        }
    }
}

// MARK: - Outfit Share Card View

/// Premium, editorial share card for Gen-Z
/// Design principles: Outfit is the star, subtle branding, fashion magazine aesthetic
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
        format == .stories ? 120 : 60
    }

    private var bottomPadding: CGFloat {
        format == .stories ? 60 : 40
    }

    private var horizontalPadding: CGFloat {
        format == .stories ? 48 : 32
    }

    private var scoreFontSize: CGFloat {
        format == .stories ? 56 : 44
    }

    private var headlineFontSize: CGFloat {
        format == .stories ? 36 : 28
    }

    var body: some View {
        ZStack {
            // Background - subtle warm gradient (light theme)
            LinearGradient(
                colors: [
                    Color(hex: "FAFAF8"),
                    Color(hex: "F5F3F0")
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                // Top spacing
                Spacer()
                    .frame(height: topPadding)

                // Items display
                itemsGrid
                    .padding(.horizontal, horizontalPadding)

                Spacer()

                // Content section
                VStack(spacing: 16) {
                    // Headline
                    Text(headline)
                        .font(.system(size: headlineFontSize, weight: .semibold, design: .serif))
                        .foregroundColor(Color(hex: "1A1A1A"))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    // Style score
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(styleScore)")
                            .font(.system(size: scoreFontSize, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "1A1A1A"))

                        Text("STYLE\nSCORE")
                            .font(.system(size: format == .stories ? 13 : 11, weight: .semibold))
                            .foregroundColor(Color(hex: "666666"))
                            .multilineTextAlignment(.leading)
                            .lineSpacing(2)
                    }

                    // Vibe tag
                    Text(vibe.lowercased())
                        .font(.system(size: format == .stories ? 15 : 13, weight: .medium))
                        .foregroundColor(Color(hex: "888888"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.05))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 32)

                Spacer()
                    .frame(height: format == .stories ? 80 : 40)

                // Footer with branding
                footerView
                    .padding(.horizontal, 32)
                    .padding(.bottom, bottomPadding)
            }
        }
        .frame(width: format.size.width, height: format.size.height)
    }

    // MARK: - Items Grid

    @ViewBuilder
    private var itemsGrid: some View {
        let displayItems = Array(items.prefix(4))

        switch displayItems.count {
        case 0:
            // Empty state placeholder
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.05))
                .frame(
                    width: format == .stories ? 400 : 300,
                    height: format == .stories ? 520 : 300
                )
                .overlay(
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 64))
                        .foregroundColor(Color.black.opacity(0.1))
                )

        case 1:
            // Single large item
            itemCard(displayItems[0])
                .frame(
                    maxWidth: format == .stories ? 400 : 300,
                    maxHeight: format == .stories ? 480 : 280
                )

        case 2:
            // Two items side by side
            HStack(spacing: 24) {
                ForEach(displayItems) { item in
                    itemCard(item)
                }
            }
            .frame(maxHeight: format == .stories ? 320 : 200)

        case 3:
            // Top item centered, bottom two
            VStack(spacing: 20) {
                itemCard(displayItems[0])
                    .frame(
                        maxWidth: format == .stories ? 320 : 240,
                        maxHeight: format == .stories ? 280 : 160
                    )

                HStack(spacing: 24) {
                    ForEach(displayItems.dropFirst()) { item in
                        itemCard(item)
                    }
                }
                .frame(maxHeight: format == .stories ? 200 : 120)
            }

        default: // 4+ items
            // 2x2 grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 20),
                    GridItem(.flexible(), spacing: 20)
                ],
                spacing: 20
            ) {
                ForEach(displayItems) { item in
                    itemCard(item)
                }
            }
            .frame(maxHeight: format == .stories ? 560 : 340)
        }
    }

    private func itemCard(_ item: WardrobeItem) -> some View {
        VStack(spacing: 12) {
            // Item image
            KFImage(URL(string: item.photoUrlClean ?? item.photoUrl ?? ""))
                .placeholder {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                }
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: format == .stories ? 280 : 180)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)

            // Item name
            Text(item.itemName ?? item.category?.rawValue.capitalized ?? "Item")
                .font(.system(size: format == .stories ? 14 : 12, weight: .medium))
                .foregroundColor(Color(hex: "666666"))
                .lineLimit(1)
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            // Hashtag
            Text("#StyledWithStyleum")
                .font(.system(size: format == .stories ? 14 : 12, weight: .medium))
                .foregroundColor(Color(hex: "AAAAAA"))

            Spacer()

            // Logo/wordmark
            Text("styleum")
                .font(.system(size: format == .stories ? 18 : 14, weight: .semibold, design: .serif))
                .foregroundColor(Color(hex: "AAAAAA"))
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
