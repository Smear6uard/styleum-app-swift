import SwiftUI

enum AppSymbol: String {
    // Tab bar
    case home = "house.fill"
    case wardrobe = "tshirt.fill"
    case styleMe = "wand.and.stars"
    case achievements = "trophy.fill"
    case profile = "person.fill"

    // Actions
    case add = "plus.circle.fill"
    case addSimple = "plus"
    case like = "heart"
    case likeFilled = "heart.fill"
    case skip = "arrow.right.circle"
    case refresh = "arrow.clockwise"
    case settings = "gearshape.fill"
    case camera = "camera.fill"
    case photo = "photo.fill"
    case checkmark = "checkmark.circle.fill"
    case close = "xmark"
    case chevronRight = "chevron.right"
    case chevronDown = "chevron.down"
    case trash = "trash.fill"
    case edit = "pencil"
    case share = "square.and.arrow.up"

    // Weather
    case sunMax = "sun.max.fill"
    case cloud = "cloud.fill"
    case cloudRain = "cloud.rain.fill"
    case cloudSun = "cloud.sun.fill"
    case snowflake = "snowflake"
    case wind = "wind"

    // Stats & Gamification
    case flame = "flame.fill"
    case streak = "bolt.fill"
    case star = "star.fill"
    case sparkles = "sparkles"
    case crown = "crown.fill"

    // Misc
    case location = "location.fill"
    case clock = "clock.fill"
    case calendar = "calendar"
    case info = "info.circle"
    case warning = "exclamationmark.triangle.fill"

    var image: Image {
        Image(systemName: rawValue)
    }
}

extension Image {
    init(symbol: AppSymbol) {
        self.init(systemName: symbol.rawValue)
    }
}

// SF Symbol animation modifiers
extension View {
    @ViewBuilder
    func symbolAnimation(_ animation: Animation = .spring(response: 0.3, dampingFraction: 0.5)) -> some View {
        if #available(iOS 17.0, *) {
            self.symbolEffect(.bounce, options: .speed(1.5))
        } else {
            self
        }
    }

    @ViewBuilder
    func symbolPulse() -> some View {
        if #available(iOS 17.0, *) {
            self.symbolEffect(.pulse)
        } else {
            self
        }
    }

    @ViewBuilder
    func symbolVariableColor() -> some View {
        if #available(iOS 17.0, *) {
            self.symbolEffect(.variableColor.iterative)
        } else {
            self
        }
    }
}
