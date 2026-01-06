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
