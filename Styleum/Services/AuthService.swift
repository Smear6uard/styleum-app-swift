import Foundation
import Supabase
import GoogleSignIn
import AuthenticationServices
import Sentry

#if os(iOS)
import UIKit
#endif

@Observable
final class AuthService {
    static let shared = AuthService()

    private let supabase = SupabaseManager.shared.client

    var currentUser: Supabase.User? {
        didSet {
            isAuthenticated = currentUser != nil
            print("🔐 [AUTH] ⚡️ currentUser changed - isAuthenticated: \(isAuthenticated)")
        }
    }
    private(set) var isAuthenticated: Bool = false
    var isLoading = false
    var error: Error?

    private init() {
        print("🔐 [AUTH] AuthService initialized")
        print("🔐 [AUTH] Supabase client initialized")
        Task {
            await checkSession()
        }
    }

    // MARK: - Check Existing Session
    func checkSession() async {
        print("🔐 [AUTH] ========== CHECK SESSION START ==========")
        print("🔐 [AUTH] Timestamp: \(Date())")
        print("🔐 [AUTH] Current isAuthenticated: \(isAuthenticated)")
        print("🔐 [AUTH] Current user before check: \(currentUser?.email ?? "nil")")

        do {
            print("🔐 [AUTH] Attempting to get Supabase session...")
            let session = try await supabase.auth.session
            print("🔐 [AUTH] ✅ Session retrieved successfully")
            print("🔐 [AUTH] Session user ID: \(session.user.id)")
            print("🔐 [AUTH] Session user email: \(session.user.email ?? "no email")")
            print("🔐 [AUTH] Session access token exists: \(!session.accessToken.isEmpty)")
            print("🔐 [AUTH] Session expires at: \(session.expiresAt)")

            currentUser = session.user
            print("🔐 [AUTH] ✅ currentUser set to: \(currentUser?.email ?? "nil")")
            print("🔐 [AUTH] ✅ isAuthenticated is now: \(isAuthenticated)")

            // Set Sentry user context for crash reporting
            SentrySDK.setUser(Sentry.User(userId: session.user.id.uuidString))

            // Identify user in PostHog
            AnalyticsService.identify(userId: session.user.id.uuidString)

            // Link user to RevenueCat (critical for restoring purchases after reinstall)
            await SubscriptionManager.shared.login(userId: session.user.id.uuidString)
        } catch {
            currentUser = nil
            SentrySDK.setUser(nil)
            AnalyticsService.reset()
            print("🔐 [AUTH] ⚠️ No existing session or error occurred")
            print("🔐 [AUTH] Error type: \(type(of: error))")
            print("🔐 [AUTH] Error description: \(error.localizedDescription)")
            print("🔐 [AUTH] Full error: \(error)")
            print("🔐 [AUTH] isAuthenticated is now: \(isAuthenticated)")
        }
        print("🔐 [AUTH] ========== CHECK SESSION END ==========")
    }

    // MARK: - Google Sign In
    @MainActor
    func signInWithGoogle() async throws {
        print("🔐 [AUTH] ========== GOOGLE SIGN-IN START ==========")
        print("🔐 [AUTH] Timestamp: \(Date())")

        isLoading = true
        error = nil
        print("🔐 [AUTH] Set isLoading=true, cleared error")

        defer {
            isLoading = false
            print("🔐 [AUTH] Set isLoading=false (defer)")
        }

        #if os(iOS)
        print("🔐 [AUTH] Platform: iOS")
        print("🔐 [AUTH] Looking for window scene and root view controller...")

        let connectedScenes = UIApplication.shared.connectedScenes
        print("🔐 [AUTH] Connected scenes count: \(connectedScenes.count)")

        for (index, scene) in connectedScenes.enumerated() {
            print("🔐 [AUTH] Scene \(index): \(type(of: scene)), state: \(scene.activationState.rawValue)")
        }

        guard let windowScene = connectedScenes.first as? UIWindowScene else {
            print("🔐 [AUTH] ❌ No UIWindowScene found in connected scenes")
            throw AuthError.noViewController
        }

        print("🔐 [AUTH] ✅ Got window scene: \(windowScene)")
        print("🔐 [AUTH] Window scene windows count: \(windowScene.windows.count)")

        guard let window = windowScene.windows.first else {
            print("🔐 [AUTH] ❌ No windows in window scene")
            throw AuthError.noViewController
        }

        print("🔐 [AUTH] ✅ Got first window: \(window)")

        guard let rootViewController = window.rootViewController else {
            print("🔐 [AUTH] ❌ No root view controller on window")
            throw AuthError.noViewController
        }

        print("🔐 [AUTH] ✅ Got root view controller: \(type(of: rootViewController))")

        do {
            print("🔐 [AUTH] Presenting Google Sign-In dialog...")
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            print("🔐 [AUTH] ✅ Google Sign-In dialog completed")
            print("🔐 [AUTH] Google user email: \(result.user.profile?.email ?? "no email")")
            print("🔐 [AUTH] Google user name: \(result.user.profile?.name ?? "no name")")

            guard let idToken = result.user.idToken?.tokenString else {
                print("🔐 [AUTH] ❌ No ID token received from Google")
                print("🔐 [AUTH] Access token exists: \(result.user.accessToken.tokenString.isEmpty == false)")
                throw AuthError.noIdToken
            }

            print("🔐 [AUTH] ✅ Got ID token (length: \(idToken.count) chars)")
            print("🔐 [AUTH] Exchanging ID token with Supabase...")

            let response = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .google,
                    idToken: idToken
                )
            )

            print("🔐 [AUTH] ✅ Supabase auth.signInWithIdToken successful")
            print("🔐 [AUTH] Response user ID: \(response.user.id)")
            print("🔐 [AUTH] Response user email: \(response.user.email ?? "no email")")
            print("🔐 [AUTH] Session access token exists: \(!response.accessToken.isEmpty)")

            currentUser = response.user
            print("🔐 [AUTH] ✅ currentUser set to: \(currentUser?.email ?? "nil")")
            print("🔐 [AUTH] ✅ isAuthenticated is now: \(isAuthenticated)")

            // Set Sentry user context for crash reporting
            SentrySDK.setUser(Sentry.User(userId: response.user.id.uuidString))

            // Identify user and track login in PostHog
            AnalyticsService.identify(userId: response.user.id.uuidString)
            AnalyticsService.track(AnalyticsEvent.userLoggedIn)

            // Link user to RevenueCat
            Task {
                await SubscriptionManager.shared.login(userId: response.user.id.uuidString)
            }

            HapticManager.shared.success()
            print("🔐 [AUTH] ========== GOOGLE SIGN-IN SUCCESS ==========")

        } catch let error as NSError {
            print("🔐 [AUTH] ========== GOOGLE SIGN-IN ERROR ==========")
            print("🔐 [AUTH] ❌ Error occurred during Google Sign-In")
            print("🔐 [AUTH] Error type: \(type(of: error))")
            print("🔐 [AUTH] Error domain: \(error.domain)")
            print("🔐 [AUTH] Error code: \(error.code)")
            print("🔐 [AUTH] Error localizedDescription: \(error.localizedDescription)")
            print("🔐 [AUTH] Error userInfo keys: \(error.userInfo.keys)")
            for (key, value) in error.userInfo {
                print("🔐 [AUTH] Error userInfo[\(key)]: \(value)")
            }
            if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? Error {
                print("🔐 [AUTH] Underlying error: \(underlyingError)")
            }
            self.error = error
            throw error
        }
        #else
        print("🔐 [AUTH] ❌ Platform not iOS - Google Sign-In not supported")
        #endif
    }

    // MARK: - Apple Sign In
    @MainActor
    func signInWithApple() async throws {
        print("🔐 [AUTH] ========== APPLE SIGN-IN START ==========")
        print("🔐 [AUTH] Timestamp: \(Date())")

        isLoading = true
        error = nil
        print("🔐 [AUTH] Set isLoading=true, cleared error")

        defer {
            isLoading = false
            print("🔐 [AUTH] Set isLoading=false (defer)")
        }

        #if os(iOS)
        do {
            print("🔐 [AUTH] Creating AppleSignInCoordinator...")
            let coordinator = AppleSignInCoordinator()

            print("🔐 [AUTH] Presenting Apple Sign-In dialog...")
            let credential = try await coordinator.signIn()
            print("🔐 [AUTH] ✅ Apple Sign-In dialog completed")
            print("🔐 [AUTH] Apple user ID: \(credential.user)")
            print("🔐 [AUTH] Apple user email: \(credential.email ?? "not provided")")
            print("🔐 [AUTH] Apple user name: \(credential.fullName?.givenName ?? "not provided")")

            guard let identityToken = credential.identityToken,
                  let identityTokenString = String(data: identityToken, encoding: .utf8) else {
                print("🔐 [AUTH] ❌ No identity token received from Apple")
                throw AuthError.noIdToken
            }

            print("🔐 [AUTH] ✅ Got identity token (length: \(identityTokenString.count) chars)")
            print("🔐 [AUTH] Exchanging identity token with Supabase...")

            let response = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: identityTokenString
                )
            )

            print("🔐 [AUTH] ✅ Supabase auth.signInWithIdToken successful")
            print("🔐 [AUTH] Response user ID: \(response.user.id)")
            print("🔐 [AUTH] Response user email: \(response.user.email ?? "no email")")
            print("🔐 [AUTH] Session access token exists: \(!response.accessToken.isEmpty)")

            currentUser = response.user
            print("🔐 [AUTH] ✅ currentUser set to: \(currentUser?.email ?? "nil")")
            print("🔐 [AUTH] ✅ isAuthenticated is now: \(isAuthenticated)")

            // Set Sentry user context for crash reporting
            SentrySDK.setUser(Sentry.User(userId: response.user.id.uuidString))

            // Identify user and track login in PostHog
            AnalyticsService.identify(userId: response.user.id.uuidString)
            AnalyticsService.track(AnalyticsEvent.userLoggedIn)

            // Link user to RevenueCat
            Task {
                await SubscriptionManager.shared.login(userId: response.user.id.uuidString)
            }

            HapticManager.shared.success()
            print("🔐 [AUTH] ========== APPLE SIGN-IN SUCCESS ==========")

        } catch let error as NSError {
            print("🔐 [AUTH] ========== APPLE SIGN-IN ERROR ==========")
            print("🔐 [AUTH] ❌ Error occurred during Apple Sign-In")
            print("🔐 [AUTH] Error type: \(type(of: error))")
            print("🔐 [AUTH] Error domain: \(error.domain)")
            print("🔐 [AUTH] Error code: \(error.code)")
            print("🔐 [AUTH] Error localizedDescription: \(error.localizedDescription)")

            // Don't show error for user cancellation
            if error.domain == ASAuthorizationError.errorDomain && error.code == ASAuthorizationError.canceled.rawValue {
                print("🔐 [AUTH] User cancelled Apple Sign-In - not showing error")
                return
            }

            self.error = error
            throw error
        }
        #else
        print("🔐 [AUTH] ❌ Platform not iOS - Apple Sign-In not supported")
        #endif
    }

    // MARK: - Email OTP Sign In

    /// Sends a one-time password to the specified email address
    func sendOTP(email: String) async throws {
        print("🔐 [AUTH] ========== SEND OTP START ==========")
        print("🔐 [AUTH] Email: \(email)")

        isLoading = true
        error = nil

        defer {
            isLoading = false
            print("🔐 [AUTH] Set isLoading=false (defer)")
        }

        do {
            try await supabase.auth.signInWithOTP(email: email)
            print("🔐 [AUTH] ✅ OTP sent successfully to \(email)")
            HapticManager.shared.light()
        } catch {
            print("🔐 [AUTH] ❌ Failed to send OTP: \(error)")
            self.error = error
            throw error
        }
        print("🔐 [AUTH] ========== SEND OTP END ==========")
    }

    /// Verifies the OTP code and signs in the user
    func verifyOTP(email: String, token: String) async throws {
        print("🔐 [AUTH] ========== VERIFY OTP START ==========")
        print("🔐 [AUTH] Email: \(email), Token length: \(token.count)")

        isLoading = true
        error = nil

        defer {
            isLoading = false
            print("🔐 [AUTH] Set isLoading=false (defer)")
        }

        do {
            let session = try await supabase.auth.verifyOTP(
                email: email,
                token: token,
                type: .email
            )
            print("🔐 [AUTH] ✅ OTP verified successfully")
            print("🔐 [AUTH] User ID: \(session.user.id)")
            print("🔐 [AUTH] User email: \(session.user.email ?? "no email")")

            currentUser = session.user
            print("🔐 [AUTH] ✅ currentUser set, isAuthenticated: \(isAuthenticated)")

            // Set Sentry user context for crash reporting
            SentrySDK.setUser(Sentry.User(userId: session.user.id.uuidString))

            // Identify user and track login in PostHog
            AnalyticsService.identify(userId: session.user.id.uuidString)
            AnalyticsService.track(AnalyticsEvent.userLoggedIn)

            // Link user to RevenueCat
            Task {
                await SubscriptionManager.shared.login(userId: session.user.id.uuidString)
            }

            HapticManager.shared.success()
        } catch {
            print("🔐 [AUTH] ❌ Failed to verify OTP: \(error)")
            self.error = error
            throw error
        }
        print("🔐 [AUTH] ========== VERIFY OTP END ==========")
    }

    // MARK: - Sign Out
    func signOut() async throws {
        print("🔐 [AUTH] ========== SIGN OUT START ==========")
        isLoading = true
        error = nil

        defer {
            isLoading = false
            print("🔐 [AUTH] ========== SIGN OUT END ==========")
        }

        print("🔐 [AUTH] Signing out from Supabase...")
        try await supabase.auth.signOut()
        print("🔐 [AUTH] ✅ Supabase sign out complete")

        print("🔐 [AUTH] Signing out from Google...")
        GIDSignIn.sharedInstance.signOut()
        print("🔐 [AUTH] ✅ Google sign out complete")

        // Logout from RevenueCat
        print("🔐 [AUTH] Signing out from RevenueCat...")
        await SubscriptionManager.shared.logout()
        print("🔐 [AUTH] ✅ RevenueCat sign out complete")

        // Clear Sentry user context
        SentrySDK.setUser(nil)

        // Reset PostHog user
        AnalyticsService.reset()

        currentUser = nil
        print("🔐 [AUTH] ✅ currentUser set to nil")
        print("🔐 [AUTH] ✅ isAuthenticated is now: \(isAuthenticated)")
        HapticManager.shared.light()
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case noViewController
    case noIdToken
    case sessionExpired
    case appleSignInFailed

    var errorDescription: String? {
        switch self {
        case .noViewController:
            return "Something went wrong. Please try signing in again."
        case .noIdToken:
            return "We couldn't complete sign-in. Please try again."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .appleSignInFailed:
            return "Apple Sign-In failed. Please try again."
        }
    }
}

// MARK: - Apple Sign In Coordinator
#if os(iOS)
final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    func signIn() async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.email, .fullName]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            // This shouldn't happen in a properly configured app
            fatalError("No window scene available for Apple Sign In")
        }
        return windowScene.windows.first ?? UIWindow(windowScene: windowScene)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            continuation?.resume(returning: credential)
        } else {
            continuation?.resume(throwing: AuthError.appleSignInFailed)
        }
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
#endif
