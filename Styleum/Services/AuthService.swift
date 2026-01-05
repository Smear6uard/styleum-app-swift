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
        Task {
            await checkSession()
        }
    }

    // MARK: - Check Existing Session
    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            currentUser = session.user
            print("✅ Existing session found: \(session.user.email ?? "no email")")
        } catch {
            currentUser = nil
            print("ℹ️ No existing session")
        }
    }

    // MARK: - Google Sign In
    @MainActor
    func signInWithGoogle() async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        print("🔄 Starting Google Sign-In...")

        #if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ Google Sign-In: No view controller found")
            throw AuthError.noViewController
        }

        print("✅ Got root view controller")

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            print("✅ Google Sign-In dialog completed")

            guard let idToken = result.user.idToken?.tokenString else {
                print("❌ Google Sign-In: No ID token received")
                throw AuthError.noIdToken
            }

            print("✅ Got ID token, exchanging with Supabase...")

            let response = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .google,
                    idToken: idToken
                )
            )

            currentUser = response.user
            print("✅ Supabase auth successful: \(response.user.email ?? "no email")")
            HapticManager.shared.success()

            // Create profile if first time
            await createProfileIfNeeded()

        } catch let error as NSError {
            print("❌ Google Sign-In Error: \(error.localizedDescription)")
            print("❌ Error domain: \(error.domain)")
            print("❌ Error code: \(error.code)")
            print("❌ Error userInfo: \(error.userInfo)")
            self.error = error
            throw error
        }
        #endif
    }

    // MARK: - Sign Out
    func signOut() async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        try await supabase.auth.signOut()
        GIDSignIn.sharedInstance.signOut()

        currentUser = nil
        print("✅ Signed out")
        HapticManager.shared.light()
    }

    // MARK: - Create Profile
    private func createProfileIfNeeded() async {
        guard let userId = currentUser?.id else { return }

        do {
            // Check if profile exists
            let existingProfile: Profile? = try? await supabase
                .from(DBTable.profiles.rawValue)
                .select()
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value

            if existingProfile == nil {
                print("📝 Creating new profile...")
                // Create new profile
                let newProfile = NewProfileInsert(
                    userId: userId.uuidString,
                    onboardingCompleted: false
                )

                try await supabase
                    .from(DBTable.profiles.rawValue)
                    .insert(newProfile)
                    .execute()
                print("✅ Profile created")
            } else {
                print("✅ Profile already exists")
            }
        } catch {
            print("❌ Profile creation error: \(error)")
        }
    }
}

// MARK: - New Profile Insert
struct NewProfileInsert: Encodable {
    let userId: String
    let onboardingCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case onboardingCompleted = "onboarding_completed"
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
