import SwiftUI

enum AppAnimations {
    // Basic timing - refined
    static let fast: Animation = .easeOut(duration: 0.12)
    static let normal: Animation = .easeOut(duration: 0.2)
    static let slow: Animation = .easeOut(duration: 0.3)
    static let page: Animation = .easeInOut(duration: 0.4)

    // Springs — more playful, confident motion
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.65)
    static let springSnappy = Animation.spring(response: 0.25, dampingFraction: 0.7)
    static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.55)
    static let interactiveSpring = Animation.interactiveSpring(response: 0.25, dampingFraction: 0.7, blendDuration: 0.2)

    // New: specialized springs
    static let springHero = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let springMicro = Animation.spring(response: 0.2, dampingFraction: 0.8)
    static let springCard = Animation.spring(response: 0.35, dampingFraction: 0.72)

    // Staggered list animations - context-aware
    static func staggered(index: Int, baseDelay: Double = 0.05) -> Animation {
        .spring(response: 0.4, dampingFraction: 0.72).delay(Double(index) * baseDelay)
    }

    // Fast stagger for dense grids (wardrobe)
    static func staggeredFast(index: Int) -> Animation {
        .spring(response: 0.35, dampingFraction: 0.75).delay(Double(index) * 0.03)
    }

    // Dramatic stagger for hero moments
    static func staggeredDramatic(index: Int) -> Animation {
        .spring(response: 0.5, dampingFraction: 0.68).delay(Double(index) * 0.08)
    }

    // Symbol animations
    static let symbolBounce = Animation.spring(response: 0.3, dampingFraction: 0.5)
    static let symbolPulse = Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)

    // Press animations
    static let press = Animation.easeOut(duration: 0.1)
    static let release = Animation.spring(response: 0.25, dampingFraction: 0.7)
}
