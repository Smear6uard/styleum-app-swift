import SwiftUI

/// Step 4: Tinder-style swipe view for style preference collection
struct StyleSwipeView: View {
    let department: String
    @Binding var likedIds: [String]
    @Binding var dislikedIds: [String]
    let onComplete: () -> Void

    @State private var styleImages: [StyleReferenceImage] = []
    @State private var currentIndex = 0
    @State private var offset: CGSize = .zero
    @State private var isLoading = true
    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var isDragging = false

    private let swipeThreshold: CGFloat = 100

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                // Title with italic word
                HStack(spacing: 8) {
                    Text("Define Your")
                        .font(AppTypography.clashDisplay(28))
                    Text("Style")
                        .font(AppTypography.clashDisplayItalic(28))
                }
                .foregroundColor(AppColors.textPrimary)

                Text("Swipe right on looks you love, left on ones you don't")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.pageMargin)

            // Progress counter
            if !styleImages.isEmpty && currentIndex < styleImages.count {
                Text("\(min(currentIndex + 1, 12))/12")
                    .font(AppTypography.labelMedium)
                    .foregroundColor(.secondary)
                    .padding(.top, 16)
            }

            Spacer()

            // Card stack
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if currentIndex < styleImages.count {
                cardStack
            } else {
                completedState
            }

            Spacer()

            // Bottom buttons (alternative to swiping)
            if currentIndex < styleImages.count && !isLoading {
                HStack(spacing: 40) {
                    // Dislike button
                    Button(action: { swipeLeft() }) {
                        Image(systemName: "xmark")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.red)
                            .frame(width: 64, height: 64)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }

                    // Like button
                    Button(action: { swipeRight() }) {
                        Image(systemName: "heart.fill")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.green)
                            .frame(width: 64, height: 64)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .task(id: department) {
            // Use task(id:) so images reload when department changes
            // (TabView creates all views upfront, so onAppear fires too early)
            await loadStyleImages()
        }
    }

    // MARK: - Card Stack (Tinder-style 3-card stack)

    private var cardStack: some View {
        ZStack {
            // Card at index + 2 (bottommost, smallest)
            if currentIndex + 2 < styleImages.count {
                StyleCard(image: styleImages[currentIndex + 2])
                    .frame(height: 460)
                    .scaleEffect(0.9)
                    .offset(y: 16)
                    .allowsHitTesting(false)
                    .drawingGroup()
            }

            // Card at index + 1 (middle)
            if currentIndex + 1 < styleImages.count {
                StyleCard(image: styleImages[currentIndex + 1])
                    .frame(height: 480)
                    .scaleEffect(0.95)
                    .offset(y: 8)
                    .allowsHitTesting(false)
                    .drawingGroup()
            }

            // Current card (top) - only one that moves
            if currentIndex < styleImages.count {
                let totalOffset = CGSize(
                    width: offset.width + dragOffset.width,
                    height: offset.height + dragOffset.height
                )
                StyleCard(image: styleImages[currentIndex])
                    .frame(height: 500)
                    .offset(totalOffset)
                    .rotationEffect(.degrees(Double(totalOffset.width / 20)))
                    .highPriorityGesture(dragGesture)
                    .overlay(swipeOverlay)
                    .drawingGroup()
                    .animation(isDragging ? nil : AppAnimations.springSmooth, value: offset)
                    .animation(isDragging ? nil : AppAnimations.springSmooth, value: dragOffset)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Swipe Overlay

    private var swipeOverlay: some View {
        let totalOffsetWidth = offset.width + dragOffset.width
        return ZStack {
            // LOVE indicator
            Text("LOVE")
                .font(.largeTitle.weight(.black))
                .foregroundColor(.green)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green, lineWidth: 4)
                )
                .rotationEffect(.degrees(-15))
                .opacity(totalOffsetWidth > 0 ? min(totalOffsetWidth / swipeThreshold, 1) : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(40)

            // NOPE indicator
            Text("NOPE")
                .font(.largeTitle.weight(.black))
                .foregroundColor(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red, lineWidth: 4)
                )
                .rotationEffect(.degrees(15))
                .opacity(totalOffsetWidth < 0 ? min(-totalOffsetWidth / swipeThreshold, 1) : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(40)
        }
    }

    // MARK: - Completed State

    private var completedState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("All done!")
                .font(AppTypography.headingLarge)
                .foregroundColor(.black)

            Text("You liked \(min(likedIds.count, 12)) looks")
                .font(.body)
                .foregroundColor(.secondary)

            Button(action: {
                HapticManager.shared.success()
                onComplete()
            }) {
                Text("Continue")
                    .font(AppTypography.labelLarge)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(AppSpacing.radiusMd)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                            .stroke(Color.black, lineWidth: 2)
                    )
            }
            .padding(.horizontal, 48)
            .padding(.top, 16)
        }
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onEnded { gesture in
                let totalTranslation = offset.width + gesture.translation.width
                if totalTranslation > swipeThreshold {
                    swipeRight()
                } else if totalTranslation < -swipeThreshold {
                    swipeLeft()
                } else {
                    withAnimation(AppAnimations.springSmooth) {
                        offset = .zero
                    }
                }
            }
    }

    // MARK: - Actions

    private enum SwipeDirection {
        case left, right
    }

    private func swipeRight() {
        guard currentIndex < styleImages.count else { return }
        // Ensure we don't exceed 12 likes
        guard likedIds.count < 12 else { return }
        HapticManager.shared.medium()
        likedIds.append(styleImages[currentIndex].id)
        completeSwipe(direction: .right)
    }

    private func swipeLeft() {
        guard currentIndex < styleImages.count else { return }
        HapticManager.shared.light()
        dislikedIds.append(styleImages[currentIndex].id)
        completeSwipe(direction: .left)
    }

    private func completeSwipe(direction: SwipeDirection) {
        // Use window scene bounds instead of deprecated UIScreen.main
        let screenWidth: CGFloat
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            screenWidth = window.bounds.width
        } else {
            screenWidth = 390 // Fallback for previews
        }

        // Animate card off screen (snappy 0.25s)
        withAnimation(.easeOut(duration: 0.25)) {
            offset = CGSize(
                width: direction == .right ? screenWidth * 1.5 : -screenWidth * 1.5,
                height: 0
            )
        }

        // After animation completes, reset and advance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            // Reset offset WITHOUT animation
            offset = .zero
            // Advance index
            currentIndex += 1
            // Prefetch upcoming images
            prefetchUpcomingImages()
        }
    }

    private func prefetchUpcomingImages() {
        for i in 1...3 {
            let prefetchIndex = currentIndex + i
            guard prefetchIndex < styleImages.count else { continue }
            guard let url = URL(string: styleImages[prefetchIndex].imageUrl) else { continue }
            URLSession.shared.dataTask(with: url) { _, _, _ in }.resume()
        }
    }

    // MARK: - Data Loading

    private func loadStyleImages() async {
        // Reset local view state when reloading (e.g., when department changes)
        // Note: likedIds/dislikedIds are @Binding from parent - don't reset here
        let maxImages = 12 // Limit to 12 images max
        styleImages = []
        currentIndex = 0
        isLoading = true

        do {
            let response = try await StyleumAPI.shared.getOnboardingStyleImages(department: department)
            // Limit to 12 images max
            styleImages = Array(response.images.prefix(maxImages))
            isLoading = false
            // Prefetch first batch of images for smooth swiping
            prefetchUpcomingImages()
        } catch {
            print("🎭 [SWIPE] ❌ Failed to load style images: \(error)")
            // Don't use placeholders - their IDs won't match database UUIDs
            isLoading = false
            styleImages = []  // Empty = shows completedState view
        }
    }

    // MARK: - Placeholder Images

    private static let placeholderImages: [StyleReferenceImage] = [
        StyleReferenceImage(id: "1", imageUrl: "https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800", styleTags: ["minimalist", "tailored"], vibe: "Quiet Luxury"),
        StyleReferenceImage(id: "2", imageUrl: "https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=800", styleTags: ["casual", "relaxed"], vibe: "Effortless Cool"),
        StyleReferenceImage(id: "3", imageUrl: "https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=800", styleTags: ["bohemian", "artistic"], vibe: "Free Spirit"),
        StyleReferenceImage(id: "4", imageUrl: "https://images.unsplash.com/photo-1485968579580-b6d095142e6e?w=800", styleTags: ["classic", "timeless"], vibe: "Old Money"),
        StyleReferenceImage(id: "5", imageUrl: "https://images.unsplash.com/photo-1509631179647-0177331693ae?w=800", styleTags: ["streetwear", "urban"], vibe: "Street Style"),
        StyleReferenceImage(id: "6", imageUrl: "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800", styleTags: ["modern", "sleek"], vibe: "Contemporary"),
        StyleReferenceImage(id: "7", imageUrl: "https://images.unsplash.com/photo-1495385794356-15371f348c31?w=800", styleTags: ["preppy", "polished"], vibe: "Ivy League"),
        StyleReferenceImage(id: "8", imageUrl: "https://images.unsplash.com/photo-1475180098004-ca77a66827be?w=800", styleTags: ["romantic", "feminine"], vibe: "Soft Glam"),
        StyleReferenceImage(id: "9", imageUrl: "https://images.unsplash.com/photo-1441123694162-e54a981ceba5?w=800", styleTags: ["edgy", "bold"], vibe: "Avant-Garde"),
        StyleReferenceImage(id: "10", imageUrl: "https://images.unsplash.com/photo-1445205170230-053b83016050?w=800", styleTags: ["athletic", "sporty"], vibe: "Athleisure"),
        StyleReferenceImage(id: "11", imageUrl: "https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800", styleTags: ["trendy", "fashion-forward"], vibe: "It Girl"),
        StyleReferenceImage(id: "12", imageUrl: "https://images.unsplash.com/photo-1492707892479-7bc8d5a4ee93?w=800", styleTags: ["vintage", "retro"], vibe: "Throwback"),
        StyleReferenceImage(id: "13", imageUrl: "https://images.unsplash.com/photo-1487222477894-8943e31ef7b2?w=800", styleTags: ["eclectic", "mixed"], vibe: "Creative Mix"),
        StyleReferenceImage(id: "14", imageUrl: "https://images.unsplash.com/photo-1475180429175-5a8e7a2a1e72?w=800", styleTags: ["professional", "sharp"], vibe: "Power Dressing"),
        StyleReferenceImage(id: "15", imageUrl: "https://images.unsplash.com/photo-1558171813-4c088753af8f?w=800", styleTags: ["coastal", "breezy"], vibe: "Coastal Chic"),
        StyleReferenceImage(id: "16", imageUrl: "https://images.unsplash.com/photo-1509631179647-0177331693ae?w=800", styleTags: ["monochrome", "minimal"], vibe: "All Black"),
        StyleReferenceImage(id: "17", imageUrl: "https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=800", styleTags: ["colorful", "playful"], vibe: "Color Pop"),
        StyleReferenceImage(id: "18", imageUrl: "https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=800", styleTags: ["layered", "textured"], vibe: "Layered Look"),
        StyleReferenceImage(id: "19", imageUrl: "https://images.unsplash.com/photo-1485968579580-b6d095142e6e?w=800", styleTags: ["elegant", "refined"], vibe: "Refined Elegance"),
        StyleReferenceImage(id: "20", imageUrl: "https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800", styleTags: ["weekend", "casual"], vibe: "Weekend Warrior"),
    ]
}

#Preview {
    struct PreviewWrapper: View {
        @State private var liked: [String] = []
        @State private var disliked: [String] = []

        var body: some View {
            StyleSwipeView(
                department: "womenswear",
                likedIds: $liked,
                dislikedIds: $disliked,
                onComplete: {
                    print("Liked: \(liked.count), Disliked: \(disliked.count)")
                }
            )
        }
    }
    return PreviewWrapper()
}
