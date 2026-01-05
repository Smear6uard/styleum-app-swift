import SwiftUI

// Namespace keys for matched geometry transitions
enum NamespaceKey: String {
    case wardrobeItem = "wardrobeItem"
    case outfitCard = "outfitCard"
    case tabIcon = "tabIcon"
}

// Extension to create consistent IDs
extension String {
    static func geometryID(_ key: NamespaceKey, id: String) -> String {
        "\(key.rawValue)_\(id)"
    }
}
