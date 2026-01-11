import SwiftUI

/// Global XP toast manager that queues and displays toasts sequentially.
/// Any part of the app can call `XPToastManager.shared.showToast(...)` to display XP notifications.
@Observable
final class XPToastManager {
    static let shared = XPToastManager()

    // MARK: - State

    var currentToast: XPToastData?
    var isShowingToast: Bool = false

    private var toastQueue: [XPToastData] = []
    private var isProcessingQueue = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Public API

    /// Show an XP toast with the given parameters
    func showToast(
        amount: Int,
        reason: XPReason,
        isBonus: Bool = false,
        customMessage: String? = nil
    ) {
        let toast = XPToastData(
            id: UUID().uuidString,
            amount: amount,
            reason: reason,
            isBonus: isBonus,
            customMessage: customMessage
        )

        toastQueue.append(toast)
        processQueue()
    }

    /// Dismiss the current toast immediately
    func dismissCurrentToast() {
        withAnimation(.easeOut(duration: 0.2)) {
            isShowingToast = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.currentToast = nil
            self?.processQueue()
        }
    }

    // MARK: - Queue Processing

    private func processQueue() {
        guard !isProcessingQueue, !toastQueue.isEmpty else { return }
        guard currentToast == nil else { return }

        isProcessingQueue = true

        let nextToast = toastQueue.removeFirst()
        currentToast = nextToast

        // Show the toast
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isShowingToast = true
        }

        // Haptic feedback
        if nextToast.amount > 0 {
            HapticManager.shared.light()
        }

        // Auto-dismiss after display duration
        let displayDuration: TimeInterval = nextToast.isBonus ? 2.5 : 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) { [weak self] in
            self?.dismissAndProcessNext()
        }

        isProcessingQueue = false
    }

    private func dismissAndProcessNext() {
        withAnimation(.easeOut(duration: 0.25)) {
            isShowingToast = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.currentToast = nil
            // Small delay before next toast
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.processQueue()
            }
        }
    }
}

// MARK: - Toast Data Model

struct XPToastData: Identifiable, Equatable {
    let id: String
    let amount: Int
    let reason: XPReason
    let isBonus: Bool
    let customMessage: String?

    var message: String {
        if let custom = customMessage {
            return custom
        }
        return reason.rawValue
    }

    var icon: String {
        reason.icon
    }
}

// MARK: - XP Toast View

struct XPToastView: View {
    let toast: XPToastData
    @Binding var isShowing: Bool

    @State private var offset: CGFloat = -60
    @State private var opacity: Double = 0

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: toast.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            // Amount + Message
            if toast.amount > 0 {
                HStack(spacing: 4) {
                    Text("+\(toast.amount)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("XP")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))

                    Text("  \(toast.message)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))

                    if toast.isBonus {
                        Text("2x")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.warning)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.warning.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            } else {
                // Custom message only (e.g., streak freeze)
                Text(toast.message)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(AppColors.black)
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
        )
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                offset = 0
                opacity = 1
            }
        }
        .onChange(of: isShowing) { _, newValue in
            if !newValue {
                withAnimation(.easeOut(duration: 0.25)) {
                    offset = -30
                    opacity = 0
                }
            }
        }
    }
}

// MARK: - Toast Overlay Modifier

struct XPToastOverlay: ViewModifier {
    @State private var toastManager = XPToastManager.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = toastManager.currentToast, toastManager.isShowingToast {
                    XPToastView(
                        toast: toast,
                        isShowing: Binding(
                            get: { toastManager.isShowingToast },
                            set: { toastManager.isShowingToast = $0 }
                        )
                    )
                    .padding(.top, 60) // Below safe area + header
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .zIndex(1000)
                }
            }
    }
}

extension View {
    /// Adds the global XP toast overlay to this view
    func xpToastOverlay() -> some View {
        self.modifier(XPToastOverlay())
    }
}

// MARK: - Previews

#Preview("XP Toast Queue") {
    struct PreviewContent: View {
        var body: some View {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("XP Toast Manager")
                        .font(.title)

                    Button("Show +10 XP (Outfit Worn)") {
                        XPToastManager.shared.showToast(
                            amount: 10,
                            reason: .outfitWorn
                        )
                    }

                    Button("Show +15 XP (Item Added)") {
                        XPToastManager.shared.showToast(
                            amount: 15,
                            reason: .itemAdded
                        )
                    }

                    Button("Show +50 XP Bonus") {
                        XPToastManager.shared.showToast(
                            amount: 50,
                            reason: .challengeComplete,
                            isBonus: true
                        )
                    }

                    Button("Show Streak Freeze") {
                        XPToastManager.shared.showToast(
                            amount: 0,
                            reason: .streakFreeze,
                            customMessage: "Streak frozen!"
                        )
                    }

                    Button("Queue Multiple") {
                        XPToastManager.shared.showToast(amount: 5, reason: .outfitGenerated)
                        XPToastManager.shared.showToast(amount: 10, reason: .outfitWorn)
                        XPToastManager.shared.showToast(amount: 20, reason: .challengeComplete)
                    }
                }
            }
            .xpToastOverlay()
        }
    }

    return PreviewContent()
}
