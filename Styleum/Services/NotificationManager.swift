import SwiftUI

enum InAppNotification: Identifiable {
    case outfitReady(action: () -> Void)
    case error(message: String)
    case success(message: String)

    var id: String {
        switch self {
        case .outfitReady: return "outfitReady"
        case .error: return "error"
        case .success: return "success"
        }
    }
}

@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    var currentNotification: InAppNotification?
    var isShowing = false

    private init() {}

    func show(_ notification: InAppNotification) {
        DispatchQueue.main.async {
            self.currentNotification = notification
            self.isShowing = true

            // Auto-dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                self?.dismiss()
            }
        }
    }

    func dismiss() {
        withAnimation {
            isShowing = false
            currentNotification = nil
        }
    }
}
