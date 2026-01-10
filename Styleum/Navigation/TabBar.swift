import SwiftUI

struct TabBar: View {
    @Binding var selectedTab: AppCoordinator.Tab
    @Namespace private var tabNamespace

    var body: some View {
        VStack(spacing: 0) {
            // Tab buttons with matched geometry indicator
            HStack(spacing: 0) {
                ForEach(AppCoordinator.Tab.allCases, id: \.self) { tab in
                    TabBarButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        namespace: tabNamespace
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                        HapticManager.shared.selection()
                    }
                }
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .background(
            // Glass morphism background
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                Rectangle()
                    .fill(AppColors.background.opacity(0.85))
            }
            .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: -4)
            .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct TabBarButton: View {
    let tab: AppCoordinator.Tab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    private var isStyleMe: Bool { tab == .styleMe }

    // Accent color for selected state
    private var accentColor: Color {
        isSelected ? AppColors.brownPrimary : AppColors.textMuted
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if isStyleMe {
                    // Elevated center button
                    ZStack {
                        Circle()
                            .fill(isSelected ? AppColors.brownPrimary : AppColors.backgroundSecondary)
                            .frame(width: 52, height: 52)
                            .shadow(
                                color: isSelected ? AppColors.brownPrimary.opacity(0.3) : .clear,
                                radius: 8,
                                y: 2
                            )

                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isSelected ? .white : AppColors.textMuted)
                            .symbolEffect(.bounce, value: isSelected)
                    }
                    .offset(y: -12)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                } else {
                    // Regular tab button
                    ZStack {
                        // Sliding pill indicator background
                        if isSelected {
                            Capsule()
                                .fill(AppColors.brownPrimary.opacity(0.1))
                                .frame(width: 56, height: 32)
                                .matchedGeometryEffect(id: "tabIndicator", in: namespace)
                        }

                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
                            .foregroundColor(accentColor)
                            .symbolEffect(.bounce, value: isSelected)
                    }
                    .frame(height: 32)
                }

                if !isStyleMe {
                    Text(tab.label)
                        .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(accentColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, isStyleMe ? 0 : 8)
        }
        .buttonStyle(TabBarButtonStyle(isStyleMe: isStyleMe))
    }
}

// MARK: - Tab Bar Button Style with polish
private struct TabBarButtonStyle: ButtonStyle {
    let isStyleMe: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? (isStyleMe ? 0.92 : 0.95) : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension AppCoordinator.Tab {
    var icon: String {
        switch self {
        case .home: return "house"
        case .wardrobe: return "square.grid.2x2"
        case .styleMe: return "rectangle.stack"
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
    VStack {
        Spacer()
        TabBar(selectedTab: .constant(.home))
    }
}
