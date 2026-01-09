import SwiftUI

/// Enhanced streak at risk sheet with freeze count visuals and upgrade prompts
struct StreakAtRiskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tierManager = TierManager.shared
    @State private var isUsing = false

    let streakDays: Int
    let onUpgrade: () -> Void

    private var freezesRemaining: Int {
        tierManager.streakFreezesRemaining
    }

    private var freezesLimit: Int {
        tierManager.tierInfo?.usage.streakFreezesLimit ?? (tierManager.isPro ? 5 : 1)
    }

    private var freezesUsed: Int {
        tierManager.tierInfo?.usage.streakFreezesUsed ?? 0
    }

    private var resetDate: Date? {
        tierManager.tierInfo?.usage.freezesResetAt
    }

    var body: some View {
        VStack(spacing: 24) {
            // Flame animation
            Text("\u{1F525}")
                .font(.system(size: 64))

            // Streak info
            VStack(spacing: 8) {
                Text("Your \(streakDays)-day streak is at risk!")
                    .font(.system(size: 20, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("Don't lose your progress")
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.textSecondary)
            }

            // Freeze status
            if freezesRemaining > 0 {
                freezeAvailableSection
            } else {
                noFreezesSection
            }

            // Monthly reset info
            if let reset = resetDate {
                Text("Freezes reset \(reset, style: .relative)")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textMuted)
            }
        }
        .padding(24)
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private var freezeAvailableSection: some View {
        VStack(spacing: 16) {
            // Freeze count
            HStack(spacing: 8) {
                ForEach(0..<freezesLimit, id: \.self) { index in
                    Image(systemName: index < freezesRemaining ? "snowflake" : "snowflake.slash")
                        .font(.system(size: 20))
                        .foregroundStyle(index < freezesRemaining ? .blue : AppColors.textMuted)
                }
            }

            Text("\(freezesRemaining) of \(freezesLimit) freezes remaining this month")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textSecondary)

            // Use freeze button
            Button {
                Task { await useFreeze() }
            } label: {
                HStack {
                    if isUsing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "snowflake")
                        Text("Use Streak Freeze")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
            }
            .disabled(isUsing)
        }
    }

    @ViewBuilder
    private var noFreezesSection: some View {
        VStack(spacing: 16) {
            // Empty freeze indicators
            HStack(spacing: 8) {
                ForEach(0..<freezesLimit, id: \.self) { _ in
                    Image(systemName: "snowflake.slash")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.textMuted)
                }
            }

            Text("No freezes left this month")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textSecondary)

            // Upgrade for more freezes
            Button {
                dismiss()
                onUpgrade()
            } label: {
                VStack(spacing: 4) {
                    Text("Get 5 Monthly Freezes")
                        .font(.system(size: 16, weight: .semibold))
                    Text("with Styleum Pro")
                        .font(.system(size: 12))
                        .opacity(0.8)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.brownPrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
            }
        }
    }

    private func useFreeze() async {
        isUsing = true
        defer { isUsing = false }

        let success = await tierManager.useStreakFreeze()
        if success {
            HapticManager.shared.success()
            dismiss()
        } else {
            HapticManager.shared.error()
        }
    }
}

#Preview("Has Freezes") {
    Text("Background")
        .sheet(isPresented: .constant(true)) {
            StreakAtRiskSheet(streakDays: 15, onUpgrade: {})
        }
}

#Preview("No Freezes") {
    Text("Background")
        .sheet(isPresented: .constant(true)) {
            StreakAtRiskSheet(streakDays: 15, onUpgrade: {})
        }
}
