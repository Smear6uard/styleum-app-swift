import SwiftUI

// MARK: - Reusable Skeleton Shapes
// Note: ShimmerModifier and .shimmer() extension are defined in View+Animations.swift
struct SkeletonBox: View {
    var height: CGFloat = 20
    var width: CGFloat? = nil
    var cornerRadius: CGFloat = AppSpacing.radiusSm

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AppColors.backgroundSecondary)
            .frame(width: width, height: height)
            .shimmer()
    }
}

struct SkeletonCircle: View {
    var size: CGFloat = 40

    var body: some View {
        Circle()
            .fill(AppColors.backgroundSecondary)
            .frame(width: size, height: size)
            .shimmer()
    }
}

// MARK: - Card Image Skeleton (for AsyncImage placeholders)
struct CardImageSkeleton: View {
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        ZStack {
            Rectangle()
                .fill(AppColors.backgroundSecondary)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: shimmerOffset)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                shimmerOffset = 200
            }
        }
    }
}

// MARK: - Base Skeleton Loader
struct SkeletonLoader: View {
    var width: CGFloat? = nil
    var height: CGFloat = 20
    var cornerRadius: CGFloat = AppSpacing.radiusSm

    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AppColors.filterTagBg)
            .frame(width: width, height: height)
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.4),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: isAnimating ? geo.size.width : -geo.size.width * 0.6)
                }
            )
            .mask(RoundedRectangle(cornerRadius: cornerRadius))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.2)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Skeleton Card
struct SkeletonCard: View {
    var body: some View {
        AppCard(hasShadow: false) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SkeletonLoader(height: 160, cornerRadius: AppSpacing.radiusMd)
                SkeletonLoader(width: 120, height: 18)
                SkeletonLoader(width: 80, height: 14)
            }
        }
        .clipped()
    }
}

// MARK: - Skeleton List Item
struct SkeletonListItem: View {
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            SkeletonLoader(width: 56, height: 56, cornerRadius: AppSpacing.radiusMd)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                SkeletonLoader(width: 140, height: 16)
                SkeletonLoader(width: 100, height: 14)
            }

            Spacer()
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Insight Card Skeleton (for Wardrobe Insights)
struct InsightCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SkeletonLoader(width: 48, height: 32)   // Large number
            SkeletonLoader(width: 60, height: 16)   // "Items" label
            SkeletonLoader(width: 80, height: 12)   // "X categories" text
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusMd)
    }
}

// MARK: - Empty Wardrobe Skeleton (full-width)
struct EmptyWardrobeSkeleton: View {
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            SkeletonLoader(width: 32, height: 32, cornerRadius: 8)  // Icon
            SkeletonLoader(width: 140, height: 18)                   // "Add your first items"
            SkeletonLoader(width: 80, height: 14)                    // "to get started"
            SkeletonLoader(width: 100, height: 36, cornerRadius: AppSpacing.radiusSm)  // Button
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusMd)
    }
}

// MARK: - Daily Challenges Card Skeleton
struct DailyChallengesCardSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                SkeletonBox(height: 12, width: 90)
                Spacer()
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonCircle(size: 8)
                    }
                    SkeletonBox(height: 12, width: 24)
                }
                SkeletonCircle(size: 28)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, 12)

            // Challenge rows
            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { index in
                    HStack(spacing: 12) {
                        SkeletonCircle(size: 36)
                        VStack(alignment: .leading, spacing: 4) {
                            SkeletonBox(height: 14, width: 120)
                            SkeletonBox(height: 12, width: 160)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            SkeletonBox(height: 12, width: 30)
                            SkeletonBox(height: 5, width: 60, cornerRadius: 2.5)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, 12)

                    if index < 2 {
                        Divider()
                            .padding(.horizontal, AppSpacing.md)
                    }
                }
            }

            // Reset timer
            HStack {
                SkeletonCircle(size: 11)
                SkeletonBox(height: 11, width: 100)
            }
            .padding(.top, 12)
            .padding(.bottom, AppSpacing.md)
        }
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusMd)
    }
}

// MARK: - Streak Calendar Skeleton
struct StreakCalendarSkeleton: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                SkeletonBox(height: 12, width: 80)
                Spacer()
                HStack(spacing: 4) {
                    SkeletonCircle(size: 12)
                    SkeletonBox(height: 12, width: 80)
                }
            }

            // Week days row
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { _ in
                    VStack(spacing: 6) {
                        SkeletonBox(height: 11, width: 12)
                        SkeletonCircle(size: 36)
                        SkeletonBox(height: 10, width: 20)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Stats row
            HStack {
                HStack(spacing: 4) {
                    SkeletonCircle(size: 11)
                    SkeletonBox(height: 11, width: 70)
                }
                Spacer()
                HStack(spacing: 4) {
                    SkeletonCircle(size: 11)
                    SkeletonBox(height: 11, width: 60)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusMd)
    }
}

// MARK: - Profile Stats Section Skeleton
struct ProfileStatsSkeleton: View {
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Section Header
            HStack {
                SkeletonBox(height: 12, width: 70)
                Spacer()
            }

            // Stats Row
            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { index in
                    VStack(spacing: 4) {
                        SkeletonBox(height: 24, width: 40)
                        SkeletonBox(height: 11, width: 60)
                    }
                    .frame(maxWidth: .infinity)

                    if index < 2 {
                        Divider()
                            .frame(height: 44)
                    }
                }
            }
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.radiusMd)

            // Level Progress Card
            VStack(spacing: AppSpacing.sm) {
                HStack {
                    HStack(spacing: 4) {
                        SkeletonBox(height: 12, width: 12)
                        SkeletonBox(height: 28, width: 24)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        SkeletonBox(height: 16, width: 100)
                        SkeletonBox(height: 12, width: 120)
                    }
                    Spacer()
                }
                SkeletonBox(height: 6, cornerRadius: 3)
                HStack {
                    Spacer()
                    SkeletonBox(height: 11, width: 140)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.backgroundSecondary)
            .cornerRadius(AppSpacing.radiusMd)

            // Quick Stats Row
            HStack(spacing: AppSpacing.sm) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 6) {
                        SkeletonCircle(size: 12)
                        SkeletonBox(height: 14, width: 20)
                        SkeletonBox(height: 12, width: 40)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColors.backgroundSecondary)
                    .cornerRadius(AppSpacing.radiusSm)
                }
            }
        }
    }
}

// MARK: - Skeleton Grid
struct SkeletonGrid: View {
    let columns: Int
    let rows: Int

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md), count: columns),
            spacing: AppSpacing.md
        ) {
            ForEach(0..<(columns * rows), id: \.self) { _ in
                SkeletonCard()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        SkeletonLoader(width: 200, height: 20)
        SkeletonCard()
        SkeletonListItem()
    }
    .padding()
}
