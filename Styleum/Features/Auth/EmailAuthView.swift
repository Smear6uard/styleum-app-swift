import SwiftUI

struct EmailAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var authService = AuthService.shared
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showOTPView = false

    private var isValidEmail: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                // Header
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "envelope")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(AppColors.textMuted.opacity(0.5))

                    Text("Enter your email")
                        .font(AppTypography.clashDisplay(28))
                        .foregroundColor(AppColors.textPrimary)

                    Text("We'll send you a code to sign in")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                // Email input
                VStack(spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        TextField("Email address", text: $email)
                            .textFieldStyle(.plain)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .font(.system(size: 17))
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

                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.danger)
                                .padding(.horizontal, AppSpacing.xs)
                        }
                    }

                    // Send Code button
                    Button {
                        sendCode()
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Send Code")
                                    .font(AppTypography.labelMedium)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(isValidEmail && !isLoading ? AppColors.black : AppColors.textMuted)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(!isValidEmail || isLoading)
                }
                .padding(.horizontal, AppSpacing.pageMargin)

                Spacer()
                Spacer()
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
            .navigationDestination(isPresented: $showOTPView) {
                OTPVerificationView(email: email, onDismiss: {
                    dismiss()
                })
            }
        }
    }

    private func sendCode() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await authService.sendOTP(email: email)
                await MainActor.run {
                    isLoading = false
                    showOTPView = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = parseError(error)
                }
            }
        }
    }

    private func parseError(_ error: Error) -> String {
        let description = error.localizedDescription.lowercased()

        if description.contains("rate") || description.contains("limit") {
            return "Too many attempts. Please try again later."
        } else if description.contains("invalid") && description.contains("email") {
            return "Please enter a valid email address."
        } else if description.contains("network") || description.contains("connection") {
            return "Connection error. Please check your internet."
        }

        return "Something went wrong. Please try again."
    }
}

#Preview {
    EmailAuthView()
}
