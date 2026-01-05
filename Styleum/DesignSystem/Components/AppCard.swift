import SwiftUI

struct AppCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = AppSpacing.cardPadding
    var cornerRadius: CGFloat = AppSpacing.radiusLg
    var hasBorder: Bool = true
    var hasShadow: Bool = true
    var onTap: (() -> Void)?

    // For matched geometry transitions
    var geometryID: String?
    var geometryNamespace: Namespace.ID?

    init(
        padding: CGFloat = AppSpacing.cardPadding,
        cornerRadius: CGFloat = AppSpacing.radiusLg,
        hasBorder: Bool = true,
        hasShadow: Bool = true,
        geometryID: String? = nil,
        geometryNamespace: Namespace.ID? = nil,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.hasBorder = hasBorder
        self.hasShadow = hasShadow
        self.geometryID = geometryID
        self.geometryNamespace = geometryNamespace
        self.onTap = onTap
    }

    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: {
                    HapticManager.shared.light()
                    onTap()
                }) {
                    cardContent
                }
                .buttonStyle(CardButtonStyle())
            } else {
                cardContent
            }
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        content
            .padding(padding)
            .background(AppColors.background)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(hasBorder ? AppColors.border : .clear, lineWidth: 1)
            )
            .if(hasShadow) { view in
                view.cardShadow()
            }
            .if(geometryID != nil && geometryNamespace != nil) { view in
                view.matchedGeometryEffect(
                    id: geometryID!,
                    in: geometryNamespace!
                )
            }
    }
}

// MARK: - Card Button Style (Lift Effect)
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? -2 : 0)
            .shadow(
                color: .black.opacity(configuration.isPressed ? 0.08 : 0.04),
                radius: configuration.isPressed ? 12 : 8,
                x: 0,
                y: configuration.isPressed ? 4 : 2
            )
            .animation(AppAnimations.springSnappy, value: configuration.isPressed)
    }
}

// MARK: - Conditional Modifier
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Title")
                    .font(AppTypography.headingMedium)
                Text("This is some card content")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
            }
        }

        AppCard(onTap: { print("Tapped!") }) {
            HStack {
                Text("Tappable Card")
                Spacer()
                Image(symbol: .chevronRight)
            }
        }
    }
    .padding()
}
