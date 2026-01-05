import SwiftUI

enum AchievementCategory: String, Codable, CaseIterable, Identifiable {
    case wardrobe
    case outfits
    case worn
    case streaks
    case social
    case style

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var iconSymbol: String {
        switch self {
        case .wardrobe: return "tshirt.fill"
        case .outfits: return "person.fill.viewfinder"
        case .worn: return "checkmark.circle.fill"
        case .streaks: return "flame.fill"
        case .social: return "person.2.fill"
        case .style: return "sparkles"
        }
    }
}

enum AchievementActionType: String, Codable {
    case addItem = "add_item"
    case generateOutfit = "generate_outfit"
    case wearOutfit = "wear_outfit"
    case saveOutfit = "save_outfit"
    case shareOutfit = "share_outfit"
    case updateStreak = "update_streak"
}

enum AchievementRarity: String, Codable, CaseIterable, Identifiable {
    case common
    case uncommon
    case rare
    case epic
    case legendary

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .common: return Color(hex: "9CA3AF")
        case .uncommon: return Color(hex: "10B981")
        case .rare: return Color(hex: "3B82F6")
        case .epic: return Color(hex: "8B5CF6")
        case .legendary: return Color(hex: "F59E0B")
        }
    }
}
