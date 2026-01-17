import Foundation
import RevenueCat
import Sentry

/// Manages RevenueCat subscriptions and entitlements
@MainActor
@Observable
final class SubscriptionManager {
    static let shared = SubscriptionManager()

    // MARK: - State

    var isPro: Bool = false
    var isLoading: Bool = false
    var currentOffering: Offering?
    var monthlyPrice: String = "$9.99/month"
    var error: String?

    private var customerInfoTask: Task<Void, Never>?

    // MARK: - Init

    private init() {}

    // MARK: - Configuration

    /// Configure RevenueCat on app launch
    func configure() {
        Purchases.logLevel = .debug  // TODO: Remove for production
        Purchases.configure(withAPIKey: "appl_yMbnLVKVdIKIIfyBvWQYqqvdlkB")
        print("📦 [RC] RevenueCat configured")

        // Start listening for CustomerInfo updates
        startListeningForUpdates()
    }

    /// Start listening for CustomerInfo updates via async stream
    private func startListeningForUpdates() {
        customerInfoTask?.cancel()
        customerInfoTask = Task {
            for await customerInfo in Purchases.shared.customerInfoStream {
                updateProStatus(from: customerInfo)
            }
        }
    }

    // MARK: - User Management

    /// Link authenticated user to RevenueCat
    func login(userId: String) async {
        print("📦 [RC] Logging in user: \(userId)")
        do {
            let (customerInfo, created) = try await Purchases.shared.logIn(userId)
            print("📦 [RC] Login success - created: \(created)")
            updateProStatus(from: customerInfo)
        } catch {
            print("❌ [RC] Failed to login: \(error)")
        }
    }

    /// Logout from RevenueCat (creates anonymous user)
    func logout() async {
        print("📦 [RC] Logging out user")
        do {
            let customerInfo = try await Purchases.shared.logOut()
            updateProStatus(from: customerInfo)
            print("📦 [RC] Logout success")
        } catch {
            print("❌ [RC] Failed to logout: \(error)")
        }
    }

    // MARK: - Offerings

    /// Fetch available offerings and pricing
    func fetchOfferings() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current

            if let monthly = currentOffering?.monthly {
                monthlyPrice = monthly.storeProduct.localizedPriceString + "/month"
                print("📦 [RC] Fetched offerings - monthly: \(monthlyPrice)")
            } else {
                print("📦 [RC] No monthly package in current offering")
            }
        } catch {
            self.error = "Failed to load pricing"
            print("❌ [RC] Failed to fetch offerings: \(error)")
        }
    }

    // MARK: - Purchase

    /// Purchase the Pro subscription
    func purchase() async -> Bool {
        guard let package = currentOffering?.monthly else {
            error = "No subscription package available"
            print("❌ [RC] No monthly package to purchase")
            return false
        }

        // Sentry breadcrumb: subscription purchase started
        let startCrumb = Breadcrumb(level: .info, category: "subscription.purchase")
        startCrumb.message = "Started subscription purchase"
        startCrumb.data = ["package": package.identifier]
        SentrySDK.addBreadcrumb(startCrumb)

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            print("📦 [RC] Starting purchase...")
            let result = try await Purchases.shared.purchase(package: package)

            if result.userCancelled {
                print("📦 [RC] User cancelled purchase")
                return false
            }

            updateProStatus(from: result.customerInfo)

            // Sentry breadcrumb: subscription purchase completed
            let completeCrumb = Breadcrumb(level: .info, category: "subscription.purchase")
            completeCrumb.message = "Subscription purchase completed"
            completeCrumb.data = ["isPro": isPro]
            SentrySDK.addBreadcrumb(completeCrumb)

            print("📦 [RC] Purchase successful! isPro: \(isPro)")

            // Track subscription started event
            if isPro {
                AnalyticsService.track(AnalyticsEvent.subscriptionStarted, properties: [
                    "plan": "monthly"
                ])
            }

            return isPro
        } catch {
            // Check if user cancelled
            if let rcError = error as? RevenueCat.ErrorCode {
                if rcError == .purchaseCancelledError {
                    print("📦 [RC] User cancelled purchase")
                    return false
                }
            }

            self.error = "Purchase failed. Please try again."
            print("❌ [RC] Purchase failed: \(error)")
            return false
        }
    }

    // MARK: - Restore

    /// Restore previous purchases
    func restorePurchases() async -> Bool {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            print("📦 [RC] Restoring purchases...")
            let customerInfo = try await Purchases.shared.restorePurchases()
            updateProStatus(from: customerInfo)
            print("📦 [RC] Restore complete - isPro: \(isPro)")
            return isPro
        } catch {
            self.error = "Restore failed. Please try again."
            print("❌ [RC] Restore failed: \(error)")
            return false
        }
    }

    // MARK: - Status

    /// Update pro status from CustomerInfo
    private func updateProStatus(from customerInfo: CustomerInfo) {
        let wassPro = isPro
        isPro = customerInfo.entitlements["Styleum Pro"]?.isActive == true

        if wassPro != isPro {
            print("📦 [RC] Pro status changed: \(wassPro) → \(isPro)")
        }
    }

    /// Refresh current customer info
    func refreshStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateProStatus(from: customerInfo)
        } catch {
            print("❌ [RC] Failed to refresh status: \(error)")
        }
    }

    // MARK: - Reset

    func reset() {
        isPro = false
        currentOffering = nil
        monthlyPrice = "$9.99/month"
        error = nil
        customerInfoTask?.cancel()
        customerInfoTask = nil
    }
}
