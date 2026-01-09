import SwiftUI

/// Displays wardrobe item count relative to tier limit
struct WardrobeCounter: View {
    let current: Int
    let limit: Int
    let isPro: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text("\(current)")
                .fontWeight(.semibold)
            Text("of")
                .foregroundStyle(AppColors.textSecondary)
            Text(isPro ? "\u{221E}" : "\(limit)")
                .fontWeight(.semibold)
            Text("items")
                .foregroundStyle(AppColors.textSecondary)
        }
        .font(.system(size: 12))
        .foregroundStyle(AppColors.textPrimary)
    }
}

#Preview("Free Tier") {
    WardrobeCounter(current: 25, limit: 30, isPro: false)
        .padding()
}

#Preview("Pro Tier") {
    WardrobeCounter(current: 87, limit: 30, isPro: true)
        .padding()
}

#Preview("At Limit") {
    WardrobeCounter(current: 30, limit: 30, isPro: false)
        .padding()
}
