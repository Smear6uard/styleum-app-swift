import SwiftUI

enum AppAnimations {
    // Basic timing
    static let fast: Animation = .easeOut(duration: 0.15)
    static let normal: Animation = .easeOut(duration: 0.2)
    static let slow: Animation = .easeOut(duration: 0.3)
    static let page: Animation = .easeInOut(duration: 0.4)

    // Springs — iOS native feel
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 0.8)
    static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let interactiveSpring = Animation.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.25)

    // Staggered list animations
    static func staggered(index: Int, baseDelay: Double = 0.05) -> Animation {
        .spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * baseDelay)
    }

    // Symbol animations
    static let symbolBounce = Animation.spring(response: 0.3, dampingFraction: 0.5)
    static let symbolPulse = Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)
}
