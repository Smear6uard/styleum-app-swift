import SwiftUI
import Kingfisher

/// Swipe card component for style images
struct StyleCard: View {
    let image: StyleReferenceImage
    @State private var imageLoaded = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Image with Kingfisher for better performance and caching
                if let url = URL(string: image.imageUrl) {
                    KFImage(url)
                        .placeholder {
                            Rectangle()
                                .fill(Color.black.opacity(0.05))
                                .overlay(
                                    ProgressView()
                                        .tint(.black)
                                )
                        }
                        .onSuccess { _ in
                            imageLoaded = true
                        }
                        .onFailure { _ in
                            imageLoaded = true  // Show tags on failure too
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.black.opacity(0.05))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.black.opacity(0.3))
                        )
                        .onAppear { imageLoaded = true }
                }

                // Gradient overlay and tags - only show when image loaded
                if imageLoaded {
                    LinearGradient(
                        colors: [.clear, .clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Vibe and tags
                    VStack(alignment: .leading, spacing: 8) {
                        Text(image.vibe)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        if !image.styleTags.isEmpty {
                            Text(image.styleTags.joined(separator: " · "))
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                }
            }
            .cornerRadius(AppSpacing.radiusXl)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        }
    }
}

#Preview {
    StyleCard(image: StyleReferenceImage(
        id: "1",
        imageUrl: "https://images.unsplash.com/photo-1490481651871-ab68de25d43d",
        styleTags: ["minimalist", "tailored", "neutral"],
        vibe: "Quiet Luxury"
    ))
    .frame(height: 500)
    .padding()
}
