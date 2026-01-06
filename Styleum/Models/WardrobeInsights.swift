import Foundation

struct WardrobeInsights: Codable {
    let itemCount: Int
    let categoryCount: Int
    let categories: [String]
    let mostWornItem: MostWornItem?
}

struct MostWornItem: Codable {
    let id: String
    let name: String
    let imageUrl: String?
    let wearCount: Int
}
