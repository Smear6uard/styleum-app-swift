import SwiftUI

/// Trigger context for showing the upgrade screen
enum UpgradeTrigger {
    case lockedOutfits
    case capsuleComplete
    case creditsExhausted
    case streakAtRisk
    case historyLocked
    case analyticsLocked
    case manual

    var headline: String {
        switch self {
        case .lockedOutfits:
            return "See all your outfit options"
        case .capsuleComplete:
            return "Unlock your full wardrobe"
        case .creditsExhausted:
            return "Style without limits"
        case .streakAtRisk:
            return "Protect your progress"
        case .historyLocked:
            return "Relive your best looks"
        case .analyticsLocked:
            return "Know your wardrobe better"
        case .manual:
            return "Unlock your full wardrobe"
        }
    }
}

/// Main upgrade/paywall screen with feature list and pricing
struct ProUpgradeView: View {
    @Environment(\.dismiss) var dismiss
    let trigger: UpgradeTrigger
    @State private var tierManager = TierManager.shared
    @State private var isPurchasing = false
    @State private var showCelebration = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // What you're missing (contextual)
                    if tierManager.tierInfo != nil {
                        missingSection
                    }

                    // Features list
                    featuresSection

                    // Pricing and CTA
                    pricingSection

                    // Legal footer
                    legalFooter
                }
                .padding(.horizontal, AppSpacing.pageMargin)
                .padding(.vertical, 24)
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Styleum Pro")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.brownPrimary)
                .tracking(1)

            Text(trigger.headline)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }

    // MARK: - What You're Missing

    @ViewBuilder
    private var missingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Right now, you're missing:")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)

            VStack(alignment: .leading, spacing: 10) {
                if let usage = tierManager.tierInfo?.usage {
                    if usage.wardrobeRemaining <= 0 {
                        MissingItemRow(
                            icon: "tshirt",
                            text: "Items waiting to be added"
                        )
                    }

                    if usage.dailyOutfitsUsed >= usage.dailyOutfitsLimit {
                        MissingItemRow(
                            icon: "sparkles",
                            text: "\(max(0, 4 - usage.dailyOutfitsLimit)) more outfit options today"
                        )
                    }

                    if !tierManager.hasAnalytics {
                        MissingItemRow(
                            icon: "chart.bar",
                            text: "Your cost-per-wear insights"
                        )
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
    }

    // MARK: - Features

    @ViewBuilder
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProFeatureRow(icon: "infinity", text: "Unlimited wardrobe items")
            ProFeatureRow(icon: "square.grid.2x2", text: "4 daily outfit options")
            ProFeatureRow(icon: "sparkles", text: "Unlimited Style Me")
            ProFeatureRow(icon: "clock.arrow.circlepath", text: "Full outfit history")
            ProFeatureRow(icon: "chart.pie", text: "Wardrobe analytics")
            ProFeatureRow(icon: "snowflake", text: "5 streak freezes monthly")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
    }

    // MARK: - Pricing

    @ViewBuilder
    private var pricingSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("$9.99/month")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Cancel anytime")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textMuted)
            }

            Button {
                HapticManager.shared.medium()
                Task {
                    await purchasePro()
                }
            } label: {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(AppColors.background)
                    } else {
                        Text("Start styling smarter")
                    }
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppColors.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
            }
            .disabled(isPurchasing)

            Button {
                // Restore purchases
                HapticManager.shared.light()
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(.top, 8)
        .fullScreenCover(isPresented: $showCelebration) {
            ProUpgradeCelebrationView(trigger: trigger) {
                showCelebration = false
                dismiss()
            }
        }
    }

    // MARK: - Legal Footer

    @ViewBuilder
    private var legalFooter: some View {
        VStack(spacing: 8) {
            Text("Subscription auto-renews monthly until cancelled.")
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textMuted)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button("Terms of Use") {
                    if let url = URL(string: "https://styleum.app/terms") {
                        UIApplication.shared.open(url)
                    }
                }

                Text("•")
                    .foregroundStyle(AppColors.textMuted)

                Button("Privacy Policy") {
                    if let url = URL(string: "https://styleum.app/privacy") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .font(.system(size: 12))
            .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Purchase

    private func purchasePro() async {
        isPurchasing = true
        defer { isPurchasing = false }

        // TODO: Implement RevenueCat purchase flow
        // For now, simulate purchase and show celebration
        try? await Task.sleep(for: .seconds(1))

        // Refresh tier state from backend
        await tierManager.refresh()

        // Show celebration!
        await MainActor.run {
            showCelebration = true
        }
    }
}

// MARK: - Supporting Views

private struct MissingItemRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.brownPrimary)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textPrimary)
        }
    }
}

private struct ProFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.green)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textPrimary)
        }
    }
}

// MARK: - Previews

#Preview("From Locked Outfits") {
    ProUpgradeView(trigger: .lockedOutfits)
}

#Preview("From Capsule Complete") {
    ProUpgradeView(trigger: .capsuleComplete)
}

#Preview("Manual") {
    ProUpgradeView(trigger: .manual)
}
