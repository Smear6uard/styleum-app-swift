import Foundation

enum Formality: Int, Codable, CaseIterable, Identifiable {
    case veryCasual = 1
    case casual = 2
    case smartCasual = 3
    case business = 4
    case formal = 5

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .veryCasual: return "Very Casual"
        case .casual: return "Casual"
        case .smartCasual: return "Smart Casual"
        case .business: return "Business"
        case .formal: return "Formal"
        }
    }
}
