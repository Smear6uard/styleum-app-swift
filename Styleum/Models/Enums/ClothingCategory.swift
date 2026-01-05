import SwiftUI

enum ClothingCategory: String, Codable, CaseIterable, Identifiable {
    case top = "top"
    case bottom = "bottom"
    case shoes = "shoes"
    case outerwear = "outerwear"
    case accessory = "accessory"
    case dress = "dress"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .top: return "Tops"
        case .bottom: return "Bottoms"
        case .shoes: return "Shoes"
        case .outerwear: return "Outerwear"
        case .accessory: return "Accessories"
        case .dress: return "Dresses"
        }
    }

    var iconSymbol: AppSymbol {
        switch self {
        case .top: return .wardrobe
        case .bottom: return .wardrobe
        case .shoes: return .wardrobe
        case .outerwear: return .wardrobe
        case .accessory: return .sparkles
        case .dress: return .wardrobe
        }
    }
}
