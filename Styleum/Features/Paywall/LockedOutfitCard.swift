import SwiftUI

/// Blurred outfit card with lock overlay for free tier users
struct LockedOutfitCard: View {
    let imageURL: URL?
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            // Blurred outfit image
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 20)
                case .failure:
                    Rectangle()
                        .fill(AppColors.backgroundSecondary)
                case .empty:
                    Rectangle()
                        .fill(AppColors.backgroundSecondary)
                        .shimmer()
                @unknown default:
                    Rectangle()
                        .fill(AppColors.backgroundSecondary)
                }
            }

            // Frosted glass overlay
            Rectangle()
                .fill(.ultraThinMaterial)

            // Lock content
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)

                Text("Your best match might be here")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                Button {
                    HapticManager.shared.light()
                    onUnlock()
                } label: {
                    Text("Reveal")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
    }
}

#Preview {
    LockedOutfitCard(
        imageURL: URL(string: "https://example.com/outfit.jpg"),
        onUnlock: { print("Unlock tapped") }
    )
    .frame(width: 160, height: 200)
    .padding()
}
