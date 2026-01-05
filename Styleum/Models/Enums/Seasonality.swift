import Foundation

enum Seasonality: String, Codable, CaseIterable, Identifiable {
    case spring
    case summer
    case fall
    case winter
    case allSeason = "all_season"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .fall: return "Fall"
        case .winter: return "Winter"
        case .allSeason: return "All Season"
        }
    }
}
