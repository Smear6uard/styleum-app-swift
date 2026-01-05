import SwiftUI

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
