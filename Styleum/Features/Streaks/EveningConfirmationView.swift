import SwiftUI

/// Evening confirmation sheet shown when user taps the evening push notification.
/// Allows users to confirm they wore an outfit or something else to maintain their streak.
struct EveningConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var gamificationService = GamificationService.shared

    @State private var showSkipWarning = false
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var xpAwarded = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Header
                VStack(spacing: 12) {
                    Text("💅")
                        .font(.system(size: 64))

                    Text("Did you slay today?")
                        .font(AppTypography.editorialHeadline)
                        .foregroundStyle(AppColors.textPrimary)

                    if gamificationService.currentStreak > 0 {
                        Text("\(gamificationService.currentStreak)-day streak on the line!")
                            .font(.system(size: 15))
                            .foregroundStyle(AppColors.textMuted)
                    }
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 16) {
                    // Yes I wore it
                    Button {
                        Task { await confirmDay(response: "yes") }
                    } label: {
                        HStack {
                            Text("Yes, I wore it!")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                            Text("+10 XP")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppColors.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(AppColors.black)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                    }
                    .disabled(isSubmitting)

                    // Something else
                    Button {
                        Task { await confirmDay(response: "something_else") }
                    } label: {
                        HStack {
                            Text("I wore something else")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                            Text("+5 XP")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppColors.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(AppColors.backgroundTertiary)
                        .foregroundStyle(AppColors.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                    }
                    .disabled(isSubmitting)

                    // Skip
                    Button {
                        if gamificationService.currentStreak > 0 {
                            showSkipWarning = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text("Skip for now")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .disabled(isSubmitting)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if gamificationService.currentStreak > 0 {
                            showSkipWarning = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
            }
            .alert("You'll lose your streak! 🔥", isPresented: $showSkipWarning) {
                Button("Keep my streak", role: .cancel) { }
                Button("Let it go", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("Your \(gamificationService.currentStreak)-day streak will reset if you don't confirm today.")
            }
            .overlay {
                if showSuccess {
                    successOverlay
                }
            }
        }
        .interactiveDismissDisabled(isSubmitting)
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppColors.success)

                Text("Streak maintained! 🔥")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                if xpAwarded > 0 {
                    Text("+\(xpAwarded) XP")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppColors.textMuted)
                }
            }
        }
        .transition(.opacity)
    }

    // MARK: - Actions

    private func confirmDay(response: String) async {
        isSubmitting = true
        HapticManager.shared.medium()

        do {
            let result = try await StyleumAPI.shared.confirmDay(response: response)

            if result.success {
                xpAwarded = result.xpAwarded

                // Refresh gamification data
                await gamificationService.loadGamificationData()

                // Show success briefly then dismiss
                withAnimation(.easeOut(duration: 0.3)) {
                    showSuccess = true
                }
                HapticManager.shared.success()

                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s
                dismiss()
            } else {
                // API returned success: false
                print("⚠️ [EveningConfirmation] API returned success: false - \(result.message ?? "unknown")")
                isSubmitting = false
            }
        } catch {
            print("❌ [EveningConfirmation] Failed to confirm day: \(error)")
            isSubmitting = false
            HapticManager.shared.error()
        }
    }
}

// MARK: - Preview

#Preview {
    EveningConfirmationView()
}
