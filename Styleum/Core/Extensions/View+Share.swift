import SwiftUI
import UIKit

// MARK: - View Extension for Sharing
extension View {

    /// Get the topmost view controller for presenting sheets
    @MainActor
    func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return nil
        }

        // Find the topmost presented controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        return topVC
    }
}

// MARK: - UIApplication Extension
extension UIApplication {

    /// Get the key window's root view controller
    @MainActor
    var rootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }

    /// Get the topmost presented view controller
    @MainActor
    var topViewController: UIViewController? {
        guard var topVC = rootViewController else { return nil }

        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        return topVC
    }
}
