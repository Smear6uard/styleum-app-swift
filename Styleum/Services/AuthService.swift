import Foundation
import Supabase
import GoogleSignIn

#if os(iOS)
import UIKit
#endif

@Observable
final class AuthService {
    static let shared = AuthService()

    private let supabase = SupabaseManager.shared.client

    var currentUser: User?
    var isAuthenticated: Bool { currentUser != nil }
    var isLoading = false
    var error: Error?

    private init() {
        print("🔐 [AUTH] AuthService initialized")
        print("🔐 [AUTH] Supabase client exists: \(supabase != nil)")
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
            print("🔐 [AUTH] Session expires at: \(session.expiresAt ?? 0)")

            currentUser = session.user
            print("🔐 [AUTH] ✅ currentUser set to: \(currentUser?.email ?? "nil")")
            print("🔐 [AUTH] ✅ isAuthenticated is now: \(isAuthenticated)")
        } catch {
            currentUser = nil
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

    var errorDescription: String? {
        switch self {
        case .noViewController: return "Unable to present sign-in"
        case .noIdToken: return "Failed to get authentication token"
        case .sessionExpired: return "Session expired. Please sign in again."
        }
    }
}
