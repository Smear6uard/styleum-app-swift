import SwiftUI

extension View {
    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    func cardElevatedShadow() -> some View {
        self.shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)
    }

    func buttonShadow() -> some View {
        self.shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    func subtleShadow() -> some View {
        self.shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
}
