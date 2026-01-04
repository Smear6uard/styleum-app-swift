import SwiftUI

struct TabBar: View {
    @Binding var selectedTab: AppCoordinator.Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppCoordinator.Tab.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    selectedTab = tab
                    HapticManager.shared.selection()
                }
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Rectangle()
                .fill(AppColors.background)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -4)
        )
    }
}

struct TabBarButton: View {
    let tab: AppCoordinator.Tab
    let isSelected: Bool
    let action: () -> Void

    private var isStyleMe: Bool { tab == .styleMe }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if isStyleMe {
                    // Emphasized Style Me button
                    ZStack {
                        Circle()
                            .fill(isSelected ? AppColors.black : AppColors.backgroundSecondary)
                            .frame(width: 48, height: 48)

                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isSelected ? .white : AppColors.textMuted)
                    }
                    .offset(y: -8)
                } else {
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? AppColors.black : AppColors.textMuted)
                }

                if !isStyleMe {
                    Text(tab.label)
                        .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? AppColors.black : AppColors.textMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, isStyleMe ? 0 : 8)
        }
        .buttonStyle(.plain)
    }
}

extension AppCoordinator.Tab {
    var icon: String {
        switch self {
        case .home: return "house"
        case .wardrobe: return "square.grid.2x2"
        case .styleMe: return "square.stack"
        case .achievements: return "trophy"
        case .profile: return "person"
        }
    }

    var label: String {
        switch self {
        case .home: return "Home"
        case .wardrobe: return "Wardrobe"
        case .styleMe: return "Style Me"
        case .achievements: return "Achieve"
        case .profile: return "Profile"
        }
    }
}

#Preview {
    TabBar(selectedTab: .constant(.home))
}
