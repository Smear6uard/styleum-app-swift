import SwiftUI

struct StyleMeRateLimitedView: View {
    let error: APIError?
    let onRetry: () -> Void
    let onUpgrade: () -> Void

    private let tierManager = TierManager.shared

    // Extract daily info from error
    private var dailyInfo: DailyLimitInfo? {
        if case .rateLimited(_, _, _, let info) = error {
            return info
        }
        return nil
    }

    // Check if this is a daily limit error
    private var isDailyLimit: Bool {
        dailyInfo != nil
    }

    // Format time until reset
    private var timeUntilReset: String? {
        guard let resetsAt = dailyInfo?.resetsAt else { return nil }
        let interval = resetsAt.timeIntervalSinceNow
        guard interval > 0 else { return nil }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }

    private var title: String {
        isDailyLimit ? "Daily Limit Reached" : "Out of Style Credits"
    }

    private var message: String {
        if isDailyLimit {
            if tierManager.isFree {
                return "Upgrade to Pro for more outfits"
            } else {
                if let resetTime = timeUntilReset {
                    return "Resets in \(resetTime)"
                }
                return "Resets at midnight"
            }
        }
        // Fallback to error message for non-daily limits
        if case .rateLimited(let msg, _, _, _) = error {
            return msg
        }
        return "Monthly generation limit reached"
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Rate limit icon
            Image(systemName: "hourglass")
                .font(.system(size: 52, weight: .light))
                .foregroundColor(AppColors.textSecondary)

            // Error messaging
            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Buttons - different for Pro vs Free
            if tierManager.isPro && isDailyLimit {
                // Pro user hitting daily limit - just show retry
                Button {
                    HapticManager.shared.light()
                    onRetry()
                } label: {
                    Text("Try Again Later")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.top, 8)
            } else {
                // Free user or monthly limit - show upgrade option
                Button {
                    HapticManager.shared.medium()
                    onUpgrade()
                } label: {
                    Text("Upgrade to Pro")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(AppColors.brownSecondary)
                        .cornerRadius(AppSpacing.radiusSm)
                }
                .padding(.top, 8)

                // Secondary retry option
                Button {
                    HapticManager.shared.light()
                    onRetry()
                } label: {
                    Text("Try Again")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview("Free User - Daily Limit") {
    ZStack {
        LinearGradient(
            colors: [
                Color(hex: "E8E4DF"),
                Color(hex: "F5F3F0"),
                Color(hex: "FAFAF8")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        StyleMeRateLimitedView(
            error: APIError.rateLimited(
                message: "Daily limit reached",
                remaining: 0,
                limit: 4,
                dailyInfo: DailyLimitInfo(
                    used: 4,
                    limit: 4,
                    resetsAt: Date().addingTimeInterval(5 * 3600)
                )
            )
        ) {
            print("Retry tapped")
        } onUpgrade: {
            print("Upgrade tapped")
        }
    }
}

#Preview("Monthly Limit") {
    ZStack {
        LinearGradient(
            colors: [
                Color(hex: "E8E4DF"),
                Color(hex: "F5F3F0"),
                Color(hex: "FAFAF8")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        StyleMeRateLimitedView(
            error: APIError.rateLimited(
                message: "Monthly generation limit reached",
                remaining: 0,
                limit: 15,
                dailyInfo: nil
            )
        ) {
            print("Retry tapped")
        } onUpgrade: {
            print("Upgrade tapped")
        }
    }
}
