import SwiftUI

struct StatCard: View {
    let value: String
    let label: String
    var icon: AppSymbol?
    var iconColor: Color = AppColors.slate
    var trend: Trend?

    enum Trend {
        case up, down, neutral

        var color: Color {
            switch self {
            case .up: return AppColors.success
            case .down: return AppColors.danger
            case .neutral: return AppColors.textMuted
            }
        }

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "arrow.right"
            }
        }
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    if let icon = icon {
                        Image(symbol: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(iconColor)
                    }

                    Spacer()

                    if let trend = trend {
                        Image(systemName: trend.icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(trend.color)
                    }
                }

                Text(value)
                    .font(AppTypography.numberLarge)
                    .foregroundColor(AppColors.textPrimary)

                Text(label.uppercased())
                    .font(AppTypography.kicker)
                    .foregroundColor(AppColors.textMuted)
                    .tracking(0.5)
            }
        }
    }
}

// MARK: - Stat Row (Multiple stats in a row)
struct StatRow: View {
    let stats: [(value: String, label: String, icon: AppSymbol?)]

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                StatCard(
                    value: stat.value,
                    label: stat.label,
                    icon: stat.icon
                )
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        StatCard(
            value: "5",
            label: "Day Streak",
            icon: .flame,
            iconColor: .orange,
            trend: .up
        )

        StatRow(stats: [
            ("9", "Items", .wardrobe),
            ("5", "Day Streak", .flame),
            ("0", "Outfits", .styleMe)
        ])
    }
    .padding()
}
