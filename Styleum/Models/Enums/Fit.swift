import Foundation

enum Fit: String, Codable, CaseIterable, Identifiable {
    case slim
    case regular
    case relaxed
    case oversized
    case tailored
    case unknown

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}
