import SwiftUI

struct ListRow<Leading: View, Trailing: View>: View {
    let title: String
    var subtitle: String?
    var leading: Leading?
    var trailing: Trailing?
    var showChevron: Bool = true
    var destructive: Bool = false
    var action: (() -> Void)?

    init(
        title: String,
        subtitle: String? = nil,
        showChevron: Bool = true,
        destructive: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.destructive = destructive
        self.action = action
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            action?()
        }) {
            HStack(spacing: AppSpacing.md) {
                if let leading = leading, !(leading is EmptyView) {
                    leading
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(destructive ? AppColors.danger : AppColors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTypography.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer()

                if let trailing = trailing, !(trailing is EmptyView) {
                    trailing
                }

                if showChevron && action != nil {
                    Image(symbol: .chevronRight)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textMuted)
                }
            }
            .padding(.vertical, AppSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 0) {
        ListRow(title: "Notifications", action: {}) {
            Image(symbol: .settings)
                .foregroundColor(AppColors.textSecondary)
        } trailing: {
            EmptyView()
        }

        Divider()

        ListRow(title: "Temperature Unit", subtitle: "Fahrenheit", action: {}) {
            EmptyView()
        } trailing: {
            Text("°F")
                .foregroundColor(AppColors.textSecondary)
        }

        Divider()

        ListRow(title: "Sign Out", showChevron: false, destructive: true, action: {}) {
            EmptyView()
        } trailing: {
            EmptyView()
        }
    }
    .padding()
}
