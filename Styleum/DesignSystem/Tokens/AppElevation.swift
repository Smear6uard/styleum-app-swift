import SwiftUI

/// Elevation system for consistent shadow depth throughout the app
enum AppElevation {

    // MARK: - Shadow Definitions

    /// No shadow
    static let none: [(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)] = []

    /// Subtle shadow for inline elements
    static let subtle: [(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)] = [
        (color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
    ]

    /// Standard card elevation
    static let card: [(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)] = [
        (color: .black.opacity(0.03), radius: 1, x: 0, y: 1),
        (color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    ]

    /// Elevated card (pressed state, hover)
    static let elevated: [(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)] = [
        (color: .black.opacity(0.03), radius: 1, x: 0, y: 1),
        (color: .black.opacity(0.08), radius: 12, x: 0, y: 6),
        (color: .black.opacity(0.04), radius: 24, x: 0, y: 12)
    ]

    /// Floating elements (modals, popovers)
    static let floating: [(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)] = [
        (color: .black.opacity(0.1), radius: 16, x: 0, y: 8),
        (color: .black.opacity(0.05), radius: 32, x: 0, y: 16)
    ]

    /// Hero/featured elements
    static let hero: [(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)] = [
        (color: .black.opacity(0.04), radius: 2, x: 0, y: 1),
        (color: .black.opacity(0.08), radius: 16, x: 0, y: 8),
        (color: .black.opacity(0.04), radius: 32, x: 0, y: 16)
    ]
}

// MARK: - View Extension for Easy Application

extension View {
    /// Apply an elevation shadow to the view
    func elevation(_ level: [(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)]) -> some View {
        var view = AnyView(self)
        for shadow in level {
            view = AnyView(view.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y))
        }
        return view
    }

    /// Apply card elevation
    func cardElevation() -> some View {
        self
            .shadow(color: .black.opacity(0.03), radius: 1, y: 1)
            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    /// Apply elevated/pressed card elevation
    func elevatedElevation() -> some View {
        self
            .shadow(color: .black.opacity(0.03), radius: 1, y: 1)
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
            .shadow(color: .black.opacity(0.04), radius: 24, y: 12)
    }

    /// Apply hero/featured elevation
    func heroElevation() -> some View {
        self
            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
            .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
            .shadow(color: .black.opacity(0.04), radius: 32, y: 16)
    }

    /// Apply floating element elevation
    func floatingElevation() -> some View {
        self
            .shadow(color: .black.opacity(0.1), radius: 16, y: 8)
            .shadow(color: .black.opacity(0.05), radius: 32, y: 16)
    }
}
