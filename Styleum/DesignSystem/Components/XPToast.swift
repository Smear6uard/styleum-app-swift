import SwiftUI

struct XPToast: View {
    let amount: Int
    let isBonus: Bool
    @Binding var isShowing: Bool

    @State private var opacity: Double = 0
    @State private var offset: CGFloat = -20

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))

            if isBonus {
                Text("+\(amount) XP")
                    .font(AppTypography.labelMedium)
                +
                Text(" · 2x bonus!")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(.white.opacity(0.8))
            } else {
                Text("+\(amount) XP")
                    .font(AppTypography.labelMedium)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColors.black)
        .clipShape(Capsule())
        .opacity(opacity)
        .offset(y: offset)
        .onAppear {
            HapticManager.shared.success()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                opacity = 1
                offset = 0
            }

            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                    offset = -10
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isShowing = false
                }
            }
        }
    }
}

#Preview("Standard XP") {
    ZStack {
        Color.gray.opacity(0.2)
        XPToast(amount: 25, isBonus: false, isShowing: .constant(true))
    }
}

#Preview("Bonus XP") {
    ZStack {
        Color.gray.opacity(0.2)
        XPToast(amount: 50, isBonus: true, isShowing: .constant(true))
    }
}
