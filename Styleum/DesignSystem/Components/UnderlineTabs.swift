import SwiftUI

struct UnderlineTabs: View {
    let tabs: [String]
    @Binding var selectedTabs: Set<String>
    var allowMultiSelect: Bool = true

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.lg) {
                ForEach(tabs, id: \.self) { tab in
                    UnderlineTab(
                        label: tab,
                        isSelected: selectedTabs.contains(tab)
                    ) {
                        HapticManager.shared.selection()

                        if allowMultiSelect {
                            if tab == "All" {
                                // "All" clears other selections
                                selectedTabs = ["All"]
                            } else {
                                // Remove "All" if selecting specific tab
                                selectedTabs.remove("All")

                                if selectedTabs.contains(tab) {
                                    selectedTabs.remove(tab)
                                    // If nothing selected, default to "All"
                                    if selectedTabs.isEmpty {
                                        selectedTabs = ["All"]
                                    }
                                } else {
                                    selectedTabs.insert(tab)
                                }
                            }
                        } else {
                            selectedTabs = [tab]
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.pageMargin)
        }
    }
}

struct UnderlineTab: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(label)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)

                // Underline
                Rectangle()
                    .fill(isSelected ? AppColors.black : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

// Single select variant
struct UnderlineTabsSingle: View {
    let tabs: [String]
    @Binding var selectedTab: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.lg) {
                ForEach(tabs, id: \.self) { tab in
                    UnderlineTab(
                        label: tab,
                        isSelected: selectedTab == tab
                    ) {
                        HapticManager.shared.selection()
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, AppSpacing.pageMargin)
        }
    }
}

#Preview {
    VStack {
        UnderlineTabs(
            tabs: ["All", "Tops", "Bottoms", "Shoes", "Outerwear"],
            selectedTabs: .constant(["All"])
        )

        UnderlineTabsSingle(
            tabs: ["All", "Wardrobe", "Outfits", "Streaks", "Social"],
            selectedTab: .constant("All")
        )
    }
}
