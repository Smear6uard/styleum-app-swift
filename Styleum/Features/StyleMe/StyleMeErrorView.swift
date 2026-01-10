import SwiftUI

struct StyleMeErrorView: View {
    let error: Error?
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Error icon
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 52, weight: .light))
                .foregroundColor(AppColors.warning)

            // Error messaging
            VStack(spacing: 10) {
                Text("Couldn't create looks")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                Text(errorMessage)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Retry button
            Button {
                HapticManager.shared.light()
                onRetry()
            } label: {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(AppColors.brownSecondary)
                    .cornerRadius(10)
            }
            .padding(.top, 8)

            Spacer()
            Spacer()
        }
    }

    private var errorMessage: String {
        if let outfitError = error as? OutfitError {
            return outfitError.localizedDescription
        }
        return error?.localizedDescription ?? "Something went wrong. Please try again."
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

        StyleMeErrorView(error: OutfitError.notEnoughItems) {
            print("Retry tapped")
        }
    }
}
