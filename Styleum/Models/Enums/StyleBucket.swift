import Foundation

enum StyleBucket: String, Codable, CaseIterable, Identifiable {
    case casual
    case smartCasual = "smart_casual"
    case businessCasual = "business_casual"
    case formal
    case streetwear
    case athleisure
    case bohemian
    case minimalist
    case edgy
    case preppy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .casual: return "Casual"
        case .smartCasual: return "Smart Casual"
        case .businessCasual: return "Business Casual"
        case .formal: return "Formal"
        case .streetwear: return "Streetwear"
        case .athleisure: return "Athleisure"
        case .bohemian: return "Bohemian"
        case .minimalist: return "Minimalist"
        case .edgy: return "Edgy"
        case .preppy: return "Preppy"
        }
    }
}
