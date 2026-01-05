import Foundation

enum Material: String, Codable, CaseIterable, Identifiable {
    case cotton
    case linen
    case silk
    case wool
    case denim
    case leather
    case synthetic
    case knit
    case fleece
    case cashmere
    case velvet
    case corduroy
    case unknown

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}
