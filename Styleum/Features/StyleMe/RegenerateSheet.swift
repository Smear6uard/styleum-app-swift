import SwiftUI

struct RegenerateSheet: View {
    let currentOutfit: ScoredOutfit
    let isPro: Bool
    let onRegenerate: (FeedbackType) -> Void
    let onUpgrade: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Handle indicator
            Capsule()
                .fill(AppColors.textMuted.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, AppSpacing.sm)

            // Header
            VStack(spacing: AppSpacing.xs) {
                Text("Try a different look")
                    .font(AppTypography.headingMedium)
                    .foregroundColor(AppColors.textPrimary)

                Text("Tell us what to change")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, AppSpacing.sm)

            if isPro {
                // Pro user - show feedback options
                feedbackGrid
            } else {
                // Free user - show upgrade prompt
                proGateOverlay
            }

            Spacer()
        }
        .background(AppColors.background)
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.hidden)
    }

    private var feedbackGrid: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
            ForEach(FeedbackType.allCases, id: \.self) { feedback in
                FeedbackButton(
                    feedback: feedback,
                    isLoading: isLoading
                ) {
                    HapticManager.shared.medium()
                    isLoading = true
                    onRegenerate(feedback)
                    dismiss()
                }
            }
        }
        .padding(.horizontal, AppSpacing.pageMargin)
        .padding(.top, AppSpacing.sm)
    }

    private var proGateOverlay: some View {
        VStack(spacing: AppSpacing.md) {
            // Blurred preview of options
            LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
                ForEach(FeedbackType.allCases.prefix(4), id: \.self) { feedback in
                    FeedbackButton(feedback: feedback, isLoading: false) {}
                        .disabled(true)
                        .opacity(0.4)
                        .blur(radius: 2)
                }
            }
            .padding(.horizontal, AppSpacing.pageMargin)

            // Upgrade overlay
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.textMuted)

                Text("Unlock regeneration with Pro")
                    .font(AppTypography.titleMedium)
                    .foregroundColor(AppColors.textPrimary)

                Button {
                    HapticManager.shared.medium()
                    onUpgrade()
                    dismiss()
                } label: {
                    Text("Upgrade to Pro")
                        .font(AppTypography.labelLarge)
                        .foregroundColor(.white)
                        .frame(width: 180)
                        .frame(height: 48)
                        .background(AppColors.black)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.top, -60)  // Overlap with blurred options
        }
    }
}

struct FeedbackButton: View {
    let feedback: FeedbackType
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(AppColors.textSecondary)
                } else {
                    Image(systemName: feedback.iconName)
                        .font(.system(size: 14, weight: .medium))
                }
                Text(feedback.displayName)
                    .font(AppTypography.labelSmall)
            }
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColors.filterTagBg)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isLoading)
    }
}

#Preview("Pro User") {
    RegenerateSheet(
        currentOutfit: ScoredOutfit(
            id: "test",
            wardrobeItemIds: [],
            score: 85,
            whyItWorks: "Test outfit"
        ),
        isPro: true,
        onRegenerate: { _ in },
        onUpgrade: {}
    )
}

#Preview("Free User") {
    RegenerateSheet(
        currentOutfit: ScoredOutfit(
            id: "test",
            wardrobeItemIds: [],
            score: 85,
            whyItWorks: "Test outfit"
        ),
        isPro: false,
        onRegenerate: { _ in },
        onUpgrade: {}
    )
}
