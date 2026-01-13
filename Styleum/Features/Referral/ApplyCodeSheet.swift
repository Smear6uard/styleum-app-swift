//
//  ApplyCodeSheet.swift
//  Styleum
//
//  Bottom sheet for entering and applying a referral code.
//

import SwiftUI

struct ApplyCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var shakeOffset: CGFloat = 0

    private var isValidFormat: Bool {
        code.trimmingCharacters(in: .whitespacesAndNewlines).count >= 4
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                // Drag indicator
                Capsule()
                    .fill(AppColors.border)
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)

                Spacer()
                    .frame(height: AppSpacing.md)

                // Icon
                ZStack {
                    Circle()
                        .fill(AppColors.brownPrimary.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: showSuccess ? "checkmark" : "ticket")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(showSuccess ? AppColors.success : AppColors.brownPrimary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .scaleEffect(showSuccess ? 1.1 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showSuccess)

                // Title
                VStack(spacing: AppSpacing.xs) {
                    Text(showSuccess ? "Code Applied!" : "Enter Referral Code")
                        .font(AppTypography.headingMedium)
                        .foregroundColor(AppColors.textPrimary)

                    Text(showSuccess ? "You've earned 7 days of Pro!" : "Enter the code your friend shared with you")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                if !showSuccess {
                    // Text Field
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        TextField("XXXXXXXX", text: $code)
                            .font(AppTypography.editorial(20, weight: .semibold))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.center)
                            .padding(.vertical, AppSpacing.md)
                            .padding(.horizontal, AppSpacing.lg)
                            .background(AppColors.inputBackground)
                            .cornerRadius(AppSpacing.radiusMd)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                                    .strokeBorder(
                                        errorMessage != nil ? AppColors.danger : AppColors.border,
                                        lineWidth: 1
                                    )
                            )
                            .offset(x: shakeOffset)
                            .submitLabel(.done)
                            .onSubmit {
                                if isValidFormat && !isLoading {
                                    Task { await applyCode() }
                                }
                            }

                        if let error = errorMessage {
                            Text(error)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.danger)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeOut(duration: 0.2), value: errorMessage)

                    Spacer()

                    // Apply Button
                    AppButton(
                        label: "Apply Code",
                        isLoading: isLoading,
                        isDisabled: !isValidFormat || isLoading
                    ) {
                        Task { await applyCode() }
                    }
                } else {
                    Spacer()

                    // Done Button
                    AppButton(label: "Done") {
                        HapticManager.shared.light()
                        dismiss()
                    }
                }
            }
            .padding(AppSpacing.pageMargin)
            .background(AppColors.background)
            .contentShape(Rectangle())
            .onTapGesture {
                // Dismiss keyboard when tapping outside text field
                #if canImport(UIKit)
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                #endif
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .interactiveDismissDisabled(isLoading)
    }

    // MARK: - Apply Code

    private func applyCode() async {
        errorMessage = nil
        isLoading = true

        do {
            let result = try await ReferralService.shared.applyCode(code)

            await MainActor.run {
                isLoading = false

                switch result {
                case .success:
                    HapticManager.shared.success()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showSuccess = true
                    }

                case .alreadyApplied:
                    errorMessage = "You've already used a referral code"
                    triggerShake()

                case .invalidCode:
                    errorMessage = "This code doesn't exist"
                    triggerShake()

                case .ownCode:
                    errorMessage = "You can't use your own code"
                    triggerShake()
                }
            }
        } catch let error as ReferralError {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                triggerShake()
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Something went wrong. Try again."
                triggerShake()
            }
        }
    }

    private func triggerShake() {
        HapticManager.shared.error()

        withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
            shakeOffset = 10
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
                shakeOffset = -8
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
                shakeOffset = 6
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.5)) {
                shakeOffset = 0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ApplyCodeSheet()
}
