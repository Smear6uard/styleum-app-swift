import SwiftUI

struct StyleMeRateLimitedView: View {
    let error: APIError?
    let onRetry: () -> Void
    let onUpgrade: () -> Void

    private var message: String {
        if case .rateLimited(let msg, _, _) = error {
            return msg
        }
        return "Monthly generation limit reached"
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Rate limit icon
            Image(systemName: "hourglass")
                .font(.system(size: 52, weight: .light))
                .foregroundColor(AppColors.textSecondary)

            // Error messaging
            VStack(spacing: 10) {
                Text("Out of Style Credits")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Upgrade button (primary)
            Button {
                HapticManager.shared.medium()
                onUpgrade()
            } label: {
                Text("Upgrade to Pro")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(AppColors.brownSecondary)
                    .cornerRadius(10)
            }
            .padding(.top, 8)

            // Secondary retry option
            Button {
                HapticManager.shared.light()
                onRetry()
            } label: {
                Text("Try Again")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(hex: "E8E4DF"),
                Color(hex: "F5F3F0"),
                Color(hex: "FAFAF8")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        StyleMeRateLimitedView(
            error: APIError.rateLimited(message: "Monthly generation limit reached", remaining: 0, limit: 15)
        ) {
            print("Retry tapped")
        } onUpgrade: {
            print("Upgrade tapped")
        }
    }
}
