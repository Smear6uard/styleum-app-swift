import SwiftUI

// MARK: - Billing Issue Banner

struct BillingIssueBanner: View {
    let onFix: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Payment issue")
                    .font(.system(size: 14, weight: .semibold))
                Text("Update your payment method to keep Pro")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Button("Fix") {
                onFix()
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(.orange)
            .clipShape(Capsule())
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
    }
}

// MARK: - Grace Period Banner

struct GracePeriodBanner: View {
    let daysRemaining: Int
    let onFix: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.exclamationmark.fill")
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("Pro expires in \(daysRemaining) day\(daysRemaining == 1 ? "" : "s")")
                    .font(.system(size: 14, weight: .semibold))
                Text("Update payment to continue")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Button("Fix") {
                onFix()
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(.yellow)
            .clipShape(Capsule())
        }
        .padding(12)
        .background(Color.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
    }
}

// MARK: - Cancellation Banner

struct CancellationBanner: View {
    let expiryDate: Date
    let onResubscribe: () -> Void

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: expiryDate)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)

            VStack(alignment: .leading, spacing: 2) {
                Text("Pro cancelled")
                    .font(.system(size: 14, weight: .semibold))
                Text("Access until \(formattedDate)")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Button("Resubscribe") {
                onResubscribe()
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(AppColors.textPrimary)
            .clipShape(Capsule())
        }
        .padding(12)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
    }
}

// MARK: - Over Limit Banner

struct OverLimitBanner: View {
    let itemCount: Int
    let limit: Int
    let onUpgrade: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tshirt.fill")
                .foregroundStyle(AppColors.brownPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Wardrobe over limit")
                    .font(.system(size: 14, weight: .semibold))
                Text("\(itemCount) items (limit: \(limit))")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Button("Upgrade") {
                onUpgrade()
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(AppColors.brownPrimary)
            .clipShape(Capsule())
        }
        .padding(12)
        .background(AppColors.brownPrimary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
    }
}

// MARK: - Previews

#Preview("Billing Issue") {
    BillingIssueBanner(onFix: {})
        .padding()
}

#Preview("Grace Period") {
    GracePeriodBanner(daysRemaining: 3, onFix: {})
        .padding()
}

#Preview("Cancellation") {
    CancellationBanner(
        expiryDate: Date().addingTimeInterval(7 * 24 * 3600),
        onResubscribe: {}
    )
    .padding()
}

#Preview("Over Limit") {
    OverLimitBanner(itemCount: 28, limit: 25, onUpgrade: {})
        .padding()
}
