import SwiftUI

extension View {
    func hapticOnTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.simultaneousGesture(TapGesture().onEnded { _ in
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        })
    }

    func hapticLight() -> some View {
        hapticOnTap(.light)
    }

    func hapticMedium() -> some View {
        hapticOnTap(.medium)
    }
}
