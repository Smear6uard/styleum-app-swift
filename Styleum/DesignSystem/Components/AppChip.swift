import SwiftUI

struct AppChip: View {
    let label: String
    var icon: AppSymbol?
    var isSelected: Bool = false
    var variant: ChipVariant = .filter
    let action: () -> Void

    enum ChipVariant {
        case filter     // For category filters
        case action     // For outfit actions (Skip, More casual, etc.)
        case tag        // For style tags
    }

    private var backgroundColor: Color {
        switch variant {
        case .filter:
            return isSelected ? AppColors.black : AppColors.filterTagBg
        case .action:
            return .clear
        case .tag:
            return isSelected ? AppColors.slate.opacity(0.15) : AppColors.filterTagBg
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .filter:
            return isSelected ? .white : AppColors.textPrimary
        case .action:
            return AppColors.textPrimary
        case .tag:
            return isSelected ? AppColors.slateDark : AppColors.textSecondary
        }
    }

    private var borderColor: Color {
        switch variant {
        case .action:
            return AppColors.border
        default:
            return .clear
        }
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(symbol: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                Text(label)
                    .font(AppTypography.labelMedium)
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, AppSpacing.sm + 2)
            .padding(.vertical, AppSpacing.xs)
            .background(backgroundColor)
            .cornerRadius(AppSpacing.radiusSm)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.radiusSm)
                    .stroke(borderColor, lineWidth: variant == .action ? 1 : 0)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Chip Group (Horizontal scrolling chips)
struct AppChipGroup: View {
    let items: [String]
    @Binding var selectedItem: String?
    var allowsDeselection: Bool = true

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(items, id: \.self) { item in
                    AppChip(
                        label: item,
                        isSelected: selectedItem == item
                    ) {
                        if selectedItem == item && allowsDeselection {
                            selectedItem = nil
                        } else {
                            selectedItem = item
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.pageMargin)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Filter chips
        HStack {
            AppChip(label: "All", isSelected: true) {}
            AppChip(label: "Tops", isSelected: false) {}
            AppChip(label: "Bottoms", isSelected: false) {}
        }

        // Action chips
        HStack {
            AppChip(label: "Skip", icon: .skip, variant: .action) {}
            AppChip(label: "Not for me", variant: .action) {}
            AppChip(label: "More casual", variant: .action) {}
        }

        // Tag chips
        HStack {
            AppChip(label: "Casual", isSelected: true, variant: .tag) {}
            AppChip(label: "Minimalist", variant: .tag) {}
        }
    }
    .padding()
}
