import SwiftUI

/// Reusable item card for outfit presentation with editorial styling
struct OutfitItemCard: View {
    let item: OutfitItemRole
    let size: CardSize

    enum CardSize {
        case hero      // Large featured item (40% of screen)
        case medium    // Standard grid item
        case small     // Accessory thumbnail (80pt)

        var cornerRadius: CGFloat {
            switch self {
            case .hero: return 20
            case .medium: return 16
            case .small: return 12
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // White background
                RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                    .fill(Color.white)

                // Item image - centered
                AsyncImage(url: URL(string: item.imageUrl ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(size == .small ? 4 : 12)
                    case .failure, .empty:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous))
            .shadow(
                color: .black.opacity(size == .hero ? 0.08 : 0.04),
                radius: size == .hero ? 12 : 8,
                y: size == .hero ? 6 : 2
            )
        }
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color(hex: "F5F5F5"))
            .overlay(
                Image(systemName: placeholderIcon)
                    .font(.system(size: size == .small ? 16 : 28))
                    .foregroundColor(Color(hex: "CCCCCC"))
            )
    }

    private var placeholderIcon: String {
        let role = item.role.lowercased()
        switch role {
        case "top", "shirt", "blouse", "sweater":
            return "tshirt"
        case "bottom", "pants", "shorts", "skirt":
            return "rectangle.portrait"
        case "footwear", "shoes":
            return "shoe"
        case "outerwear", "jacket", "coat", "blazer":
            return "cloud.fill"
        default:
            return "sparkles"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        OutfitItemCard(
            item: OutfitItemRole(
                id: "1",
                role: "top",
                imageUrl: nil,
                category: "tops",
                subcategory: nil,
                itemName: "White T-Shirt",
                colors: nil
            ),
            size: .hero
        )
        .frame(height: 300)

        HStack(spacing: 16) {
            OutfitItemCard(
                item: OutfitItemRole(id: "2", role: "bottom", imageUrl: nil, category: nil, subcategory: nil, itemName: nil, colors: nil),
                size: .medium
            )
            OutfitItemCard(
                item: OutfitItemRole(id: "3", role: "footwear", imageUrl: nil, category: nil, subcategory: nil, itemName: nil, colors: nil),
                size: .medium
            )
        }
        .frame(height: 140)

        HStack(spacing: 12) {
            OutfitItemCard(
                item: OutfitItemRole(id: "4", role: "accessory", imageUrl: nil, category: nil, subcategory: nil, itemName: nil, colors: nil),
                size: .small
            )
            .frame(width: 80, height: 80)
        }
    }
    .padding()
    .background(Color(hex: "FAFAFA"))
}
