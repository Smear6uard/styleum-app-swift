import SwiftUI

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: AppSymbol?
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if let icon = icon {
                Image(symbol: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isFocused ? AppColors.textPrimary : AppColors.textMuted)
                    .animation(AppAnimations.fast, value: isFocused)
            }

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .keyboardType(keyboardType)
            .textInputAutocapitalization(autocapitalization)
            .focused($isFocused)
            .onSubmit {
                onSubmit?()
            }
        }
        .font(AppTypography.bodyLarge)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 2)
        .background(AppColors.inputBackground)
        .cornerRadius(AppSpacing.radiusMd)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                .stroke(isFocused ? AppColors.black : .clear, lineWidth: 1.5)
        )
        .animation(AppAnimations.fast, value: isFocused)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        AppTextField(placeholder: "Email", text: .constant(""), icon: .profile)
        AppTextField(placeholder: "Password", text: .constant(""), icon: .settings, isSecure: true)
        AppTextField(placeholder: "Search items...", text: .constant(""), icon: .chevronRight)
    }
    .padding()
}
