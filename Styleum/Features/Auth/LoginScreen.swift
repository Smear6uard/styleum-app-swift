import SwiftUI

struct LoginScreen: View {
    @State private var authService = AuthService.shared
    @State private var showError = false

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Logo/Brand
            VStack(spacing: AppSpacing.md) {
                Image(symbol: .styleMe)
                    .font(.system(size: 64, weight: .medium))
                    .foregroundColor(AppColors.black)

                Text("Styleum")
                    .font(AppTypography.displayLarge)

                Text("Your AI-powered wardrobe assistant")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            // Sign in buttons
            VStack(spacing: AppSpacing.md) {
                // Google Sign In
                Button(action: {
                    Task {
                        do {
                            try await authService.signInWithGoogle()
                        } catch {
                            showError = true
                        }
                    }
                }) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 20))
                        Text("Continue with Google")
                            .font(AppTypography.labelLarge)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.black)
                    .cornerRadius(AppSpacing.radiusMd)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(authService.isLoading)

                // Apple Sign In (placeholder)
                Button(action: {
                    // Apple Sign In - implement later
                }) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20))
                        Text("Continue with Apple")
                            .font(AppTypography.labelLarge)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.background)
                    .cornerRadius(AppSpacing.radiusMd)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                            .stroke(AppColors.border, lineWidth: 1.5)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, AppSpacing.lg)

            // Terms
            Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.lg)
        }
        .overlay {
            if authService.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    )
            }
        }
        .alert("Sign In Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authService.error?.localizedDescription ?? "Please try again")
        }
    }
}

#Preview {
    LoginScreen()
}
