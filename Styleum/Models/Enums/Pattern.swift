import Foundation

enum Pattern: String, Codable, CaseIterable, Identifiable {
    case solid
    case striped
    case plaid
    case floral
    case graphic
    case geometric
    case animal
    case abstract
    case unknown

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}
