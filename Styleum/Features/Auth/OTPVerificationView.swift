import SwiftUI

struct OTPVerificationView: View {
    let email: String
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var authService = AuthService.shared
    @State private var code = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var resendCooldown = 0
    @State private var timer: Timer?

    private let codeLength = 6

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "envelope.badge")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(AppColors.textMuted.opacity(0.5))

                Text("Check your email")
                    .font(AppTypography.clashDisplay(28))
                    .foregroundColor(AppColors.textPrimary)

                Text("We sent a code to \(email)")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Code input
            VStack(spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    TextField("Enter 6-digit code", text: $code)
                        .textFieldStyle(.plain)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                                .stroke(
                                    errorMessage != nil ? AppColors.danger : AppColors.border,
                                    lineWidth: 1
                                )
                        )
                        .onChange(of: code) { _, newValue in
                            // Only allow digits and limit to 6
                            let filtered = String(newValue.filter { $0.isNumber }.prefix(codeLength))
                            if filtered != newValue {
                                code = filtered
                            }

                            // Auto-submit when 6 digits entered
                            if filtered.count == codeLength {
                                verifyCode()
                            }
                        }

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.danger)
                            .padding(.horizontal, AppSpacing.xs)
                    }
                }

                // Verify button
                Button {
                    verifyCode()
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Verify")
                                .font(AppTypography.labelMedium)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(code.count == codeLength && !isLoading ? AppColors.black : AppColors.textMuted)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(code.count != codeLength || isLoading)

                // Resend button
                Button {
                    resendCode()
                } label: {
                    if resendCooldown > 0 {
                        Text("Resend code in \(resendCooldown)s")
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.textMuted)
                    } else {
                        Text("Resend code")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .disabled(resendCooldown > 0 || isLoading)
            }
            .padding(.horizontal, AppSpacing.pageMargin)

            Spacer()
            Spacer()
        }
        .background(AppColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isLoading)
        .onAppear {
            startResendCooldown()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Actions

    private func verifyCode() {
        guard code.count == codeLength else { return }

        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await authService.verifyOTP(email: email, token: code)
                await MainActor.run {
                    isLoading = false
                    // Successfully verified - dismiss the entire auth flow
                    onDismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = parseError(error)
                    code = "" // Clear for retry
                }
            }
        }
    }

    private func resendCode() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await authService.sendOTP(email: email)
                await MainActor.run {
                    isLoading = false
                    startResendCooldown()
                    HapticManager.shared.light()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = parseError(error)
                }
            }
        }
    }

    private func startResendCooldown() {
        resendCooldown = 60
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if resendCooldown > 0 {
                resendCooldown -= 1
            } else {
                timer?.invalidate()
            }
        }
    }

    private func parseError(_ error: Error) -> String {
        let description = error.localizedDescription.lowercased()

        if description.contains("invalid") || description.contains("incorrect") {
            return "Invalid code. Please try again."
        } else if description.contains("expired") {
            return "Code expired. Please request a new one."
        } else if description.contains("rate") || description.contains("limit") {
            return "Too many attempts. Please try again later."
        } else if description.contains("network") || description.contains("connection") {
            return "Connection error. Please check your internet."
        }

        return "Something went wrong. Please try again."
    }
}

#Preview {
    NavigationStack {
        OTPVerificationView(email: "test@example.com", onDismiss: {})
    }
}
