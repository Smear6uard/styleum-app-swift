//
//  ComponentTestView.swift
//  Styleum
//
//  Created by Sameer Akhtar on 1/3/26.
//
//  Component testing view - use this to test design system components

import SwiftUI

struct ComponentTestView: View {
    @State private var showOverlay = false
    @State private var selectedCategory: String? = "All"

    let categories = ["All", "Tops", "Bottoms", "Shoes", "Outerwear"]

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    Text("Component Test")
                        .font(AppTypography.headingLarge)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Buttons
                    VStack(spacing: AppSpacing.sm) {
                        AppButton(label: "Primary Button", icon: .styleMe) {
                            showOverlay = true
                        }

                        AppButton(label: "Secondary", variant: .secondary) {}

                        HStack(spacing: AppSpacing.sm) {
                            AppButton(label: "Small", size: .small, fullWidth: false) {}
                            AppButton(label: "Loading", size: .small, isLoading: true, fullWidth: false) {}
                        }
                    }

                    // Chips
                    AppChipGroup(items: categories, selectedItem: $selectedCategory)
                        .padding(.horizontal, -AppSpacing.pageMargin)

                    // Stats
                    StatRow(stats: [
                        ("5", "Streak", .flame),
                        ("12", "Items", .wardrobe),
                        ("3", "Outfits", .styleMe)
                    ])

                    // Card
                    AppCard(onTap: {}) {
                        HStack {
                            AvatarView(initials: "SA", size: .medium)
                            VStack(alignment: .leading) {
                                Text("Sameer")
                                    .font(AppTypography.titleMedium)
                                Text("Chicago, IL")
                                    .font(AppTypography.bodySmall)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                            Image(symbol: .chevronRight)
                                .foregroundColor(AppColors.textMuted)
                        }
                    }

                    // Progress
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Progress: 40%")
                            .font(AppTypography.labelMedium)
                        ProgressBar(progress: 0.4)
                    }

                    // Empty State
                    EmptyState(
                        icon: .wardrobe,
                        headline: "No items yet",
                        description: "Add your first wardrobe item to get started.",
                        ctaLabel: "Add Item",
                        ctaAction: {}
                    )

                    // Skeleton
                    SkeletonCard()
                }
                .padding(AppSpacing.pageMargin)
            }

            // AI Overlay
            AIProcessingOverlay(isVisible: $showOverlay)
                .onTapGesture {
                    showOverlay = false
                }
        }
    }
}

#Preview {
    ComponentTestView()
}
