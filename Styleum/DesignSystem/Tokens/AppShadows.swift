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

    /// Medium shadow for toasts, pills, and floating elements
    func mediumShadow() -> some View {
        self.shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    /// Toast shadow for notification-style elements
    func toastShadow() -> some View {
        self.shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
    }

    /// Tab bar shadow (upward)
    func tabBarShadow() -> some View {
        self.shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: -4)
    }
}
