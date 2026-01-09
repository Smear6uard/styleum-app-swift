import SwiftUI

/// Time options for daily outfit notifications
enum NotificationTimeOption: String, CaseIterable, Identifiable {
    case earlyBird = "earlyBird"
    case morning = "morning"
    case midday = "midday"
    case evening = "evening"
    case custom = "custom"

    var id: String { rawValue }

    var hour: Int {
        switch self {
        case .earlyBird: return 7
        case .morning: return 9
        case .midday: return 12
        case .evening: return 18
        case .custom: return 9  // Default for custom
        }
    }

    var emoji: String {
        switch self {
        case .earlyBird: return "sun.horizon.fill"
        case .morning: return "sunrise.fill"
        case .midday: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .custom: return "gearshape.fill"
        }
    }

    var label: String {
        switch self {
        case .earlyBird: return "Early Bird"
        case .morning: return "Morning"
        case .midday: return "Midday"
        case .evening: return "Evening"
        case .custom: return "Custom"
        }
    }

    var timeString: String {
        switch self {
        case .earlyBird: return "7 AM"
        case .morning: return "9 AM"
        case .midday: return "12 PM"
        case .evening: return "6 PM"
        case .custom: return ""
        }
    }
}

/// Onboarding screen for selecting notification delivery time
struct OnboardingNotificationTimeView: View {
    let onContinue: (Int) -> Void
    let onSkip: () -> Void

    @State private var selectedOption: NotificationTimeOption = .morning
    @State private var customHour: Int = 9

    private var timezoneHint: String {
        let tz = TimeZone.current
        let city = String(tz.identifier.split(separator: "/").last ?? "your timezone")
            .replacingOccurrences(of: "_", with: " ")
        return "Times shown in \(city) time"
    }

    private var selectedHour: Int {
        selectedOption == .custom ? customHour : selectedOption.hour
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: AppSpacing.md) {
                Text("When should we deliver your daily outfit?")
                    .font(AppTypography.clashDisplay(28))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("We'll have your personalized look ready and waiting")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppSpacing.pageMargin)

            Spacer()
                .frame(height: AppSpacing.xl)

            // Time options
            VStack(spacing: AppSpacing.sm) {
                ForEach(NotificationTimeOption.allCases) { option in
                    TimeOptionCard(
                        option: option,
                        isSelected: selectedOption == option,
                        customHour: customHour,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedOption = option
                            }
                            HapticManager.shared.selection()
                        },
                        onCustomHourChange: { newHour in
                            customHour = newHour
                        }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.pageMargin)

            // Timezone hint
            Text(timezoneHint)
                .font(.system(size: 13))
                .foregroundColor(AppColors.textMuted)
                .padding(.top, AppSpacing.md)

            Spacer()

            // Buttons
            VStack(spacing: AppSpacing.md) {
                Button {
                    HapticManager.shared.success()
                    onContinue(selectedHour)
                } label: {
                    Text("Continue")
                        .font(AppTypography.labelMedium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppColors.black)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                }
                .buttonStyle(ScaleButtonStyle())

                Button {
                    HapticManager.shared.light()
                    onSkip()
                } label: {
                    Text("Skip")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textMuted)
                }
            }
            .padding(.horizontal, AppSpacing.pageMargin)
            .padding(.bottom, AppSpacing.xl)
        }
    }
}

// MARK: - Time Option Card

private struct TimeOptionCard: View {
    let option: NotificationTimeOption
    let isSelected: Bool
    let customHour: Int
    let onTap: () -> Void
    let onCustomHourChange: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: option.emoji)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? AppColors.slate : AppColors.textSecondary)
                        .frame(width: 28)

                    Text(option.label)
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.slate)
                    }

                    if option != .custom {
                        Text(option.timeString)
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(AppSpacing.md)
                .background(isSelected ? AppColors.slate.opacity(0.08) : AppColors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                        .stroke(isSelected ? AppColors.slate : AppColors.border, lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())

            // Custom time picker
            if option == .custom && isSelected {
                CustomTimePicker(selectedHour: customHour, onHourChange: onCustomHourChange)
                    .padding(.top, AppSpacing.sm)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Custom Time Picker

private struct CustomTimePicker: View {
    let selectedHour: Int
    let onHourChange: (Int) -> Void

    // Available hours (4 AM to 11 PM)
    private let hours = Array(4...23)

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(hours, id: \.self) { hour in
                    Button {
                        HapticManager.shared.selection()
                        onHourChange(hour)
                    } label: {
                        Text(formatHour(hour))
                            .font(.system(size: 14, weight: selectedHour == hour ? .semibold : .regular))
                            .foregroundColor(selectedHour == hour ? .white : AppColors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedHour == hour ? AppColors.slate : AppColors.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .frame(height: 44)
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"

        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }
}

#Preview {
    OnboardingNotificationTimeView(
        onContinue: { hour in print("Selected hour: \(hour)") },
        onSkip: { print("Skipped") }
    )
}
