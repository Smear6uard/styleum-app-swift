import SwiftUI

struct SubscriptionScreen: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Current plan
                VStack(spacing: AppSpacing.sm) {
                    Text("Current Plan")
                        .font(AppTypography.kicker)
                        .foregroundColor(AppColors.textMuted)
                        .tracking(1)

                    Text("Free")
                        .font(AppTypography.displayMedium)

                    Text("Basic features included")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.vertical, AppSpacing.lg)

                // Pro plan card
                AppCard {
                    VStack(spacing: AppSpacing.md) {
                        HStack {
                            Text("Styleum Pro")
                                .font(AppTypography.headingMedium)
                            Spacer()
                            Text("$4.99/mo")
                                .font(AppTypography.titleMedium)
                                .foregroundColor(AppColors.slate)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            FeatureRow(text: "Unlimited outfit suggestions")
                            FeatureRow(text: "Advanced style analytics")
                            FeatureRow(text: "Priority support")
                            FeatureRow(text: "No ads")
                        }

                        AppButton(label: "Upgrade to Pro") {
                            // Upgrade action
                        }
                    }
                }

                // Restore purchases
                Button("Restore Purchases") {
                    // Restore action
                }
                .font(AppTypography.labelMedium)
                .foregroundColor(AppColors.textSecondary)
            }
            .padding(AppSpacing.pageMargin)
        }
        .background(AppColors.background)
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let text: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(symbol: .checkmark)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.success)

            Text(text)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        SubscriptionScreen()
            .environment(AppCoordinator())
    }
}
