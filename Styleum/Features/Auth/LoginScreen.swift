import SwiftUI

struct LoginScreen: View {
    @State private var authService = AuthService.shared
    @State private var showError = false
    @State private var showEmailAuth = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Brand
            VStack(spacing: AppSpacing.lg) {
                // Minimal hanger icon
                Image(systemName: "hanger")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(AppColors.textMuted.opacity(0.5))
                    .accessibilityHidden(true) // Decorative image

                // Wordmark
                Text("Styleum")
                    .font(AppTypography.clashDisplay(48))
                    .foregroundColor(AppColors.textPrimary)

                // Tagline - editorial, not tech
                Text("Dress like you're already there")
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
            Spacer()

            // Sign in buttons
            VStack(spacing: AppSpacing.sm) {
                // Google Sign In
                Button {
                    print("🔑 [LOGIN] ========== GOOGLE SIGN-IN BUTTON TAPPED ==========")
                    print("🔑 [LOGIN] Timestamp: \(Date())")
                    print("🔑 [LOGIN] authService.isLoading: \(authService.isLoading)")
                    print("🔑 [LOGIN] authService.isAuthenticated: \(authService.isAuthenticated)")

                    Task {
                        do {
                            print("🔑 [LOGIN] Calling authService.signInWithGoogle()...")
                            try await authService.signInWithGoogle()
                            print("🔑 [LOGIN] ✅ signInWithGoogle completed successfully")
                            print("🔑 [LOGIN] isAuthenticated: \(authService.isAuthenticated)")
                        } catch {
                            print("🔑 [LOGIN] ❌ signInWithGoogle threw error!")
                            print("🔑 [LOGIN] Error type: \(type(of: error))")
                            print("🔑 [LOGIN] Error description: \(error.localizedDescription)")
                            print("🔑 [LOGIN] Full error: \(error)")
                            print("🔑 [LOGIN] Setting showError=true")
                            showError = true
                        }
                    }
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 18))
                        Text("Continue with Google")
                            .font(AppTypography.labelMedium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppColors.black)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(authService.isLoading)

                // Apple Sign In
                Button {
                    // Apple Sign In - implement later
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18))
                        Text("Continue with Apple")
                            .font(AppTypography.labelMedium)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                // Divider
                HStack(spacing: AppSpacing.md) {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(AppColors.border)
                    Text("or")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textMuted)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(AppColors.border)
                }
                .padding(.vertical, AppSpacing.sm)

                // Continue with Email
                Button {
                    showEmailAuth = true
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "envelope")
                            .font(.system(size: 18))
                        Text("Continue with Email")
                            .font(AppTypography.labelMedium)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(AppColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, AppSpacing.pageMargin)

            // Terms - subtle with tappable links
            VStack(spacing: 4) {
                Text("By continuing, you agree to our")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textMuted)

                HStack(spacing: 4) {
                    Button("Terms of Service") {
                        openURL("https://styleum.xyz/terms")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)

                    Text("and")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textMuted)

                    Button("Privacy Policy") {
                        openURL("https://styleum.xyz/privacy")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background)
        .overlay {
            if authService.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    )
            }
        }
        .alert("Sign In Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authService.error?.localizedDescription ?? "Please try again")
        }
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthView()
        }
        .onAppear {
            print("🔑 [LOGIN] ========== LOGIN SCREEN APPEARED ==========")
            print("🔑 [LOGIN] authService.isAuthenticated: \(authService.isAuthenticated)")
            print("🔑 [LOGIN] authService.isLoading: \(authService.isLoading)")
            print("🔑 [LOGIN] authService.currentUser exists: \(authService.currentUser != nil)")
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    LoginScreen()
}
