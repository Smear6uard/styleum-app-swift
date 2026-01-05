import SwiftUI
import CoreHaptics

@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private var engine: CHHapticEngine?

    private init() {
        prepareHaptics()
    }

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine error: \(error)")
        }
    }

    // MARK: - Simple Haptics

    func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    func rigid() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    // MARK: - Custom Patterns

    func achievementUnlock() {
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.medium()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.light()
        }
    }

    func streakMilestone() {
        heavy()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.medium()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.medium()
        }
    }

    func swipeThreshold() {
        rigid()
    }

    func likeOutfit() {
        medium()
    }

    func skipOutfit() {
        soft()
    }

    func buttonTap() {
        light()
    }

    func refresh() {
        light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.medium()
        }
    }
}
