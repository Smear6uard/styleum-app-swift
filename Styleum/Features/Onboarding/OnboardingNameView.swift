import SwiftUI

/// Step 2: Name input
struct OnboardingNameView: View {
    @Binding var name: String
    let onContinue: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title with italic word
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("What should we")
                    .font(AppTypography.displayLarge)
                    .foregroundColor(AppColors.textPrimary)
                Text("call you?")
                    .font(AppTypography.clashDisplayItalic(32))
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(.top, AppSpacing.xl)

            Text("Just your first name is fine")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, AppSpacing.sm)

            // Text field (max 50 characters for first name)
            TextField("First name", text: $name)
                .font(AppTypography.bodyLarge)
                .padding(AppSpacing.md)
                .background(AppColors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
                .padding(.top, AppSpacing.lg)
                .focused($isFocused)
                .textContentType(.givenName)
                .autocorrectionDisabled()
                .onChange(of: name) { _, newValue in
                    if newValue.count > 50 {
                        name = String(newValue.prefix(50))
                    }
                }

            Spacer()

            // Continue button
            Button {
                HapticManager.shared.medium()
                onContinue()
            } label: {
                Text("Continue")
                    .font(AppTypography.labelLarge)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(name.isEmpty ? AppColors.textMuted : AppColors.black)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(name.isEmpty)
            .padding(.bottom, AppSpacing.xl)
        }
        .padding(.horizontal, AppSpacing.pageMargin)
        .background(AppColors.background)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}

#Preview {
    OnboardingNameView(name: .constant(""), onContinue: {})
}
