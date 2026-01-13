import SwiftUI

/// Info for first-time milestones (first wardrobe item, first outfit, etc.)
struct FirstMilestoneInfo {
    let type: FirstMilestoneType
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
}

enum FirstMilestoneType {
    case firstWardrobeItem
    case firstOutfit
    case firstAutoOutfit  // Auto-generated first outfit
}

/// Celebratory view shown when user hits first-time milestones.
/// Triggered via NotificationCenter for first wardrobe item or first outfit generated.
struct FirstMilestoneCelebrationView: View {
    let milestone: FirstMilestoneInfo
    @Binding var isPresented: Bool
    var onDismiss: (() -> Void)? = nil  // Optional callback for post-dismiss navigation

    // Animation states
    @State private var iconScale: CGFloat = 0
    @State private var badgeScale: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Content
            VStack(spacing: 24) {
                Spacer()

                // Icon with glow
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    milestone.iconColor.opacity(0.4),
                                    milestone.iconColor.opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .opacity(glowOpacity)

                    // Circle background
                    Circle()
                        .fill(milestone.iconColor)
                        .frame(width: 100, height: 100)
                        .scaleEffect(badgeScale)
                        .shadow(color: milestone.iconColor.opacity(0.5), radius: 20)

                    // Icon
                    Image(systemName: milestone.icon)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(.white)
                        .scaleEffect(iconScale)
                }
                .frame(height: 200)

                // Text content
                VStack(spacing: 12) {
                    Text("FIRST MILESTONE!")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)
                        .foregroundColor(milestone.iconColor)

                    Text(milestone.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text(milestone.subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .opacity(textOpacity)

                Spacer()

                // Continue button
                Button {
                    dismiss()
                } label: {
                    Text(milestone.type == .firstAutoOutfit ? "See My Outfit" : "Let's Go!")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(milestone.iconColor)
                        .cornerRadius(AppSpacing.radiusMd)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .opacity(buttonOpacity)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        HapticManager.shared.achievementUnlock()

        // Badge scales in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
            badgeScale = 1
        }

        // Icon scales in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                iconScale = 1
            }
            withAnimation(.easeOut(duration: 0.5)) {
                glowOpacity = 1
            }
        }

        // Text fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.3)) {
                textOpacity = 1
            }
        }

        // Button appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeOut(duration: 0.3)) {
                buttonOpacity = 1
            }
        }
    }

    private func dismiss() {
        HapticManager.shared.light()
        withAnimation(.easeOut(duration: 0.2)) {
            isPresented = false
        }
        // Call completion after dismiss animation
        if let onDismiss = onDismiss {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                onDismiss()
            }
        }
    }
}

// MARK: - View Modifier

struct FirstMilestoneCelebrationModifier: ViewModifier {
    @State private var milestoneInfo: FirstMilestoneInfo?
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .firstWardrobeItem)) { _ in
                milestoneInfo = FirstMilestoneInfo(
                    type: .firstWardrobeItem,
                    title: "Your Closet Begins",
                    subtitle: "You've added your first piece!\nKeep building your digital wardrobe.",
                    icon: "tshirt.fill",
                    iconColor: AppColors.brownPrimary
                )
                isPresented = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .firstOutfitGenerated)) { _ in
                milestoneInfo = FirstMilestoneInfo(
                    type: .firstOutfit,
                    title: "Your First AI Look",
                    subtitle: "You've styled your first outfit!\nThe algorithm is learning your taste.",
                    icon: "sparkles",
                    iconColor: Color(hex: "8B5CF6")
                )
                isPresented = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .firstAutoOutfitReady)) { _ in
                milestoneInfo = FirstMilestoneInfo(
                    type: .firstAutoOutfit,
                    title: "Your First Outfit is Ready!",
                    subtitle: "We created a look just for you.\nTap to see what to wear today!",
                    icon: "sparkles",
                    iconColor: Color(hex: "8B5CF6")
                )
                isPresented = true
            }
            .fullScreenCover(isPresented: $isPresented) {
                if let info = milestoneInfo {
                    FirstMilestoneCelebrationView(
                        milestone: info,
                        isPresented: $isPresented,
                        onDismiss: info.type == .firstAutoOutfit ? {
                            // Navigate to Style Me tab to view the outfit
                            NotificationCenter.default.post(name: .navigateToStyleMe, object: nil)
                        } : nil
                    )
                    .background(Color.clear)
                }
            }
    }
}

extension View {
    /// Adds first milestone celebrations (first item, first outfit)
    func firstMilestoneCelebration() -> some View {
        self.modifier(FirstMilestoneCelebrationModifier())
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let firstWardrobeItem = Notification.Name("firstWardrobeItem")
    static let firstOutfitGenerated = Notification.Name("firstOutfitGenerated")
}

// MARK: - Previews

#Preview("First Item") {
    FirstMilestoneCelebrationView(
        milestone: FirstMilestoneInfo(
            type: .firstWardrobeItem,
            title: "Your Closet Begins",
            subtitle: "You've added your first piece!\nKeep building your digital wardrobe.",
            icon: "tshirt.fill",
            iconColor: Color(hex: "D97706")
        ),
        isPresented: .constant(true)
    )
}

#Preview("First Outfit") {
    FirstMilestoneCelebrationView(
        milestone: FirstMilestoneInfo(
            type: .firstOutfit,
            title: "Your First AI Look",
            subtitle: "You've styled your first outfit!\nThe algorithm is learning your taste.",
            icon: "sparkles",
            iconColor: Color(hex: "8B5CF6")
        ),
        isPresented: .constant(true)
    )
}
