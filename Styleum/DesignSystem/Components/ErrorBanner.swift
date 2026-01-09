import SwiftUI

/// A reusable error banner for displaying user-friendly error messages.
/// Supports automatic dismissal, retry actions, and consistent styling.
struct ErrorBanner: View {
    let error: Error
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?

    @State private var opacity: Double = 0
    @State private var offset: CGFloat = -20

    init(
        error: Error,
        onRetry: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.error = error
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: error.errorIcon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)

            Text(error.userFriendlyMessage)
                .font(AppTypography.bodySmall)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 4)

            if let onRetry = onRetry {
                Button {
                    HapticManager.shared.light()
                    onRetry()
                } label: {
                    Text("Retry")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            if let onDismiss = onDismiss {
                Button {
                    dismissBanner()
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                .fill(Color(hex: "3D3D3D"))  // Neutral dark gray
        )
        .opacity(opacity)
        .offset(y: offset)
        .onAppear {
            HapticManager.shared.error()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                opacity = 1
                offset = 0
            }
        }
    }

    private func dismissBanner() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
            offset = -10
        }
    }
}

/// A self-dismissing error toast that appears briefly then disappears
struct ErrorToast: View {
    let error: Error
    @Binding var isShowing: Bool
    var autoDismissDelay: Double = 4.0

    @State private var opacity: Double = 0
    @State private var offset: CGFloat = -20

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: error.errorIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)

            Text(error.userFriendlyMessage)
                .font(AppTypography.bodySmall)
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color(hex: "3D3D3D"))
        )
        .opacity(opacity)
        .offset(y: offset)
        .onAppear {
            HapticManager.shared.error()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                opacity = 1
                offset = 0
            }

            // Auto-dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                    offset = -10
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isShowing = false
                }
            }
        }
        .onTapGesture {
            // Dismiss on tap
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 0
                offset = -10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isShowing = false
            }
        }
    }
}

/// A simple inline error message for form validation
struct InlineError: View {
    let message: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12, weight: .medium))

            Text(message)
                .font(AppTypography.bodySmall)
        }
        .foregroundColor(Color(hex: "D64545"))  // Error red
    }
}

/// Convenience initializer for InlineError from Error type
extension InlineError {
    init(error: Error) {
        self.message = error.userFriendlyMessage
    }
}

// MARK: - View Modifier for Error Toast

struct ErrorToastModifier: ViewModifier {
    @Binding var error: Error?

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let error = error {
                ErrorToast(
                    error: error,
                    isShowing: Binding(
                        get: { self.error != nil },
                        set: { if !$0 { self.error = nil } }
                    )
                )
                .padding(.horizontal, AppSpacing.pageMargin)
                .padding(.top, 8)
            }
        }
    }
}

extension View {
    /// Shows a temporary error toast when the error binding has a value
    func errorToast(_ error: Binding<Error?>) -> some View {
        modifier(ErrorToastModifier(error: error))
    }
}

// MARK: - Previews

#Preview("Error Banner with Retry") {
    VStack {
        Spacer()
        ErrorBanner(
            error: NSError(domain: "", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Network connection lost"
            ]),
            onRetry: { print("Retry tapped") },
            onDismiss: { print("Dismissed") }
        )
        .padding()
        Spacer()
    }
    .background(Color.gray.opacity(0.2))
}

#Preview("Error Toast") {
    ZStack {
        Color.gray.opacity(0.2)
        ErrorToast(
            error: NSError(domain: "", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Something went wrong"
            ]),
            isShowing: .constant(true)
        )
    }
}

#Preview("Inline Error") {
    VStack(alignment: .leading, spacing: 8) {
        TextField("Email", text: .constant(""))
            .textFieldStyle(.roundedBorder)
        InlineError(message: "Please enter a valid email address.")
    }
    .padding()
}
