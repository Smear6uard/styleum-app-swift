import SwiftUI

enum ClothingCategory: String, Codable, CaseIterable, Identifiable {
    case tops = "tops"
    case bottoms = "bottoms"
    case shoes = "shoes"
    case outerwear = "outerwear"
    case accessories = "accessories"
    case bags = "bags"
    case jewelry = "jewelry"
    case dress = "dress"

    var id: String { rawValue }

    // Case-insensitive decoding to handle API variations
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        // Try exact match first
        if let category = ClothingCategory(rawValue: rawValue) {
            self = category
            return
        }

        // Try case-insensitive match
        let lowercased = rawValue.lowercased()
        if let category = ClothingCategory(rawValue: lowercased) {
            self = category
            return
        }

        // Handle common variations
        switch lowercased {
        case "top", "shirt", "shirts", "blouse", "tee", "t-shirt":
            self = .tops
        case "bottom", "pants", "pant", "jeans", "shorts", "skirt":
            self = .bottoms
        case "shoe", "footwear", "sneakers", "boots", "sandals":
            self = .shoes
        case "jacket", "coat", "hoodie", "sweater", "blazer":
            self = .outerwear
        case "accessory", "hat", "scarf", "belt", "sunglasses", "watch":
            self = .accessories
        case "bag", "purse", "backpack", "tote", "handbag":
            self = .bags
        case "ring", "necklace", "bracelet", "earrings", "earring":
            self = .jewelry
        case "dresses", "gown", "romper", "jumpsuit":
            self = .dress
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unknown category: \(rawValue)"
                )
            )
        }
    }

    var displayName: String {
        switch self {
        case .tops: return "Tops"
        case .bottoms: return "Bottoms"
        case .shoes: return "Shoes"
        case .outerwear: return "Outerwear"
        case .accessories: return "Accessories"
        case .bags: return "Bags"
        case .jewelry: return "Jewelry"
        case .dress: return "Dresses"
        }
    }

    var iconSymbol: AppSymbol {
        switch self {
        case .tops: return .wardrobe
        case .bottoms: return .wardrobe
        case .shoes: return .wardrobe
        case .outerwear: return .wardrobe
        case .accessories: return .sparkles
        case .bags: return .wardrobe
        case .jewelry: return .sparkles
        case .dress: return .wardrobe
        }
    }
}
