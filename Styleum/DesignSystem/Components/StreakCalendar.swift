import SwiftUI

/// Duolingo-style 7-day week view showing activity history.
/// Displays checkmarks for active days, with XP earned below each day.
struct StreakCalendar: View {
    @State private var gamificationService = GamificationService.shared

    // Today pulsing animation
    @State private var todayPulse = false

    private let calendar = Calendar.current
    private let weekDays = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("YOUR WEEK")
                    .font(AppTypography.kicker)
                    .foregroundColor(AppColors.textMuted)

                Spacer()

                // Streak indicator
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.warning)

                    Text("\(gamificationService.currentStreak) day streak")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }
            }

            // Week days row
            HStack(spacing: 0) {
                ForEach(Array(weekDates.enumerated()), id: \.element) { index, date in
                    DayCell(
                        dayLetter: weekDays[index],
                        date: date,
                        activity: activityForDate(date),
                        isToday: calendar.isDateInToday(date),
                        isFuture: date > Date(),
                        isPulsing: calendar.isDateInToday(date) && todayPulse && !hasActivityToday
                    )
                    .frame(maxWidth: .infinity)
                }
            }

            // Stats row
            HStack {
                // Best streak
                HStack(spacing: 4) {
                    Image(systemName: "flame")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.textMuted)

                    Text("Best: \(gamificationService.longestStreak) days")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.textMuted)
                }

                Spacer()

                // Freezes remaining
                HStack(spacing: 4) {
                    Image(systemName: "snowflake")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.info)

                    Text("Freezes: \(gamificationService.streakFreezes)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.textMuted)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusMd)
        .onAppear {
            // Start today pulse if no activity
            if !hasActivityToday {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    todayPulse = true
                }
            }
        }
    }

    // MARK: - Computed Properties

    /// Get dates for the current week (Monday to Sunday)
    private var weekDates: [Date] {
        let today = Date()
        var dates: [Date] = []

        // Find Monday of current week
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        components.weekday = 2 // Monday
        guard let monday = calendar.date(from: components) else { return [] }

        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: monday) {
                dates.append(date)
            }
        }

        return dates
    }

    /// Check if today has activity
    private var hasActivityToday: Bool {
        gamificationService.hasEngagedToday
    }

    /// Get activity for a specific date
    private func activityForDate(_ date: Date) -> DayActivity? {
        gamificationService.activityHistory.first { activity in
            calendar.isDate(activity.date, inSameDayAs: date)
        }
    }
}

// MARK: - Day Cell

private struct DayCell: View {
    let dayLetter: String
    let date: Date
    let activity: DayActivity?
    let isToday: Bool
    let isFuture: Bool
    let isPulsing: Bool

    private let calendar = Calendar.current

    private var hasActivity: Bool {
        activity?.hasActivity == true
    }

    private var xpEarned: Int {
        activity?.xpEarned ?? 0
    }

    var body: some View {
        VStack(spacing: 6) {
            // Day letter
            Text(dayLetter)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.textMuted)

            // Circle indicator
            ZStack {
                if isFuture {
                    // Future day - dashed outline
                    Circle()
                        .strokeBorder(AppColors.border, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        .frame(width: 36, height: 36)
                } else if hasActivity {
                    // Active day - black fill with checkmark
                    Circle()
                        .fill(AppColors.black)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: isToday ? "flame.fill" : "checkmark")
                                .font(.system(size: isToday ? 14 : 13, weight: .bold))
                                .foregroundColor(.white)
                        )
                } else if isToday {
                    // Today incomplete - ring outline with pulse
                    Circle()
                        .strokeBorder(AppColors.black, lineWidth: 2.5)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                        )
                        .scaleEffect(isPulsing ? 1.08 : 1.0)
                } else {
                    // Past day without activity - gray fill
                    Circle()
                        .fill(AppColors.backgroundTertiary)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.textMuted)
                        )
                }
            }

            // XP earned (or "today" label)
            if isToday && !hasActivity {
                Text("today")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(AppColors.textMuted)
            } else if hasActivity && xpEarned > 0 {
                Text("+\(xpEarned)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.success)
            } else {
                Text(" ")
                    .font(.system(size: 10))
            }
        }
    }
}

// MARK: - Compact Streak Calendar (Single Row)

struct CompactStreakCalendar: View {
    @State private var gamificationService = GamificationService.shared

    private let calendar = Calendar.current

    var body: some View {
        HStack(spacing: 8) {
            ForEach(lastSevenDays, id: \.self) { date in
                let activity = activityForDate(date)
                let hasActivity = activity?.hasActivity == true
                let isToday = calendar.isDateInToday(date)

                Circle()
                    .fill(hasActivity ? AppColors.black : AppColors.backgroundTertiary)
                    .frame(width: 24, height: 24)
                    .overlay {
                        if hasActivity {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        } else if isToday {
                            Circle()
                                .strokeBorder(AppColors.black, lineWidth: 2)
                        }
                    }
            }
        }
    }

    private var lastSevenDays: [Date] {
        (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -6 + offset, to: Date())
        }
    }

    private func activityForDate(_ date: Date) -> DayActivity? {
        gamificationService.activityHistory.first { activity in
            calendar.isDate(activity.date, inSameDayAs: date)
        }
    }
}

// MARK: - Previews

#Preview("Streak Calendar") {
    VStack(spacing: 20) {
        StreakCalendar()

        CompactStreakCalendar()
    }
    .padding()
    .background(AppColors.background)
}
