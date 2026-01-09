import SwiftUI
import CoreLocation

struct RootView: View {
    @State private var authService = AuthService.shared
    @State private var streakService = StreakService.shared
    @State private var profileService = ProfileService.shared
    @State private var gamificationService = GamificationService.shared
    @State private var isCheckingSession = true

    /// Check if onboarding should be shown (onboardingVersion is nil or < 2)
    private var shouldShowOnboarding: Bool {
        print("🏠 [ROOT] ========== CHECKING shouldShowOnboarding ==========")
        print("🏠 [ROOT] profileService.currentProfile: \(profileService.currentProfile != nil ? "exists" : "nil")")

        guard let profile = profileService.currentProfile else {
            print("🏠 [ROOT] ⚠️ No profile loaded yet - returning false (wait for profile)")
            return false  // Wait for profile to load
        }

        print("🏠 [ROOT] Profile ID: \(profile.id)")
        print("🏠 [ROOT] Profile onboardingVersion: \(profile.onboardingVersion.map { String($0) } ?? "nil")")
        print("🏠 [ROOT] Profile styleQuizCompleted: \(profile.styleQuizCompleted.map { String($0) } ?? "nil")")

        guard let version = profile.onboardingVersion else {
            print("🏠 [ROOT] ✅ onboardingVersion is nil - SHOW ONBOARDING")
            return true  // nil = needs onboarding
        }

        let needsOnboarding = version < 2
        print("🏠 [ROOT] onboardingVersion=\(version), needsOnboarding (version < 2): \(needsOnboarding)")
        return needsOnboarding
    }

    var body: some View {
        Group {
            if isCheckingSession {
                // Splash screen while checking session
                SplashView()
                    .onAppear {
                        print("🏠 [ROOT] 📱 SHOWING: SplashView (isCheckingSession=true)")
                    }
            } else if !authService.isAuthenticated {
                // Not logged in - show login
                LoginScreen()
                    .onAppear {
                        print("🏠 [ROOT] 📱 SHOWING: LoginScreen")
                        print("🏠 [ROOT] Reason: isAuthenticated=false")
                    }
            } else if !profileService.hasFetchedOnce {
                // Authenticated but haven't attempted profile fetch yet - show splash
                SplashView()
                    .onAppear {
                        print("🏠 [ROOT] 📱 SHOWING: SplashView (waiting for profile fetch)")
                        print("🏠 [ROOT] Reason: isAuthenticated=true, hasFetchedOnce=false")
                    }
            } else if shouldShowOnboarding {
                // Profile loaded, needs onboarding
                OnboardingContainerView()
                    .environment(AppCoordinator())
                    .onAppear {
                        print("🏠 [ROOT] 📱 SHOWING: OnboardingContainerView")
                        print("🏠 [ROOT] Reason: isAuthenticated=true, shouldShowOnboarding=true")
                    }
            } else {
                // Profile loaded, onboarding complete - show main app
                MainTabView()
                    .achievementCelebration()
                    .levelUpCelebration()
                    .streakProtection()
                    .xpToastOverlay()
                    .onAppear {
                        print("🏠 [ROOT] 📱 SHOWING: MainTabView")
                        print("🏠 [ROOT] Reason: isAuthenticated=true, shouldShowOnboarding=false")
                    }
            }
        }
        .task {
            print("🏠 [ROOT] ========== ROOT TASK START ==========")
            print("🏠 [ROOT] Timestamp: \(Date())")
            print("🏠 [ROOT] isCheckingSession: \(isCheckingSession)")
            print("🏠 [ROOT] authService.isAuthenticated: \(authService.isAuthenticated)")

            print("🏠 [ROOT] Step 1: Calling authService.checkSession()...")
            await authService.checkSession()
            print("🏠 [ROOT] Step 1 Complete. isAuthenticated: \(authService.isAuthenticated)")

            // Fetch profile BEFORE ending splash (for authenticated users)
            if authService.isAuthenticated {
                print("🏠 [ROOT] Step 2: User IS authenticated - fetching profile...")
                await profileService.fetchProfile()
                print("🏠 [ROOT] Step 2 Complete. Profile: \(profileService.currentProfile?.id ?? "nil")")
                print("🏠 [ROOT] Profile onboardingVersion: \(profileService.currentProfile?.onboardingVersion.map { String($0) } ?? "nil")")
                print("🏠 [ROOT] Profile styleQuizCompleted: \(profileService.currentProfile?.styleQuizCompleted.map { String($0) } ?? "nil")")

                print("🏠 [ROOT] Step 3: Fetching streak and gamification stats...")
                await streakService.fetchStats()
                await gamificationService.loadGamificationData()
                print("🏠 [ROOT] Step 3 Complete.")

                // Step 4: Pre-load outfits and save location (parallel, non-blocking)
                print("🏠 [ROOT] Step 4: Pre-loading outfits and saving location...")
                async let preloadOutfits: () = OutfitRepository.shared.loadPreGeneratedIfAvailable()
                async let saveLocation: () = saveUserLocationForPreGeneration()
                _ = await (preloadOutfits, saveLocation)
                print("🏠 [ROOT] Step 4 Complete.")
            } else {
                print("🏠 [ROOT] ⚠️ User NOT authenticated - skipping profile/streak fetch")
            }

            // Brief delay for splash
            print("🏠 [ROOT] Step 5: Waiting 1.5s splash delay...")
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            print("🏠 [ROOT] Step 5 Complete.")

            print("🏠 [ROOT] Step 6: Setting isCheckingSession=false with animation")
            print("🏠 [ROOT] Final state check:")
            print("🏠 [ROOT]   - isAuthenticated: \(authService.isAuthenticated)")
            print("🏠 [ROOT]   - profile exists: \(profileService.currentProfile != nil)")
            print("🏠 [ROOT]   - onboardingVersion: \(profileService.currentProfile?.onboardingVersion.map { String($0) } ?? "nil")")
            print("🏠 [ROOT]   - shouldShowOnboarding will be: \(shouldShowOnboarding)")

            withAnimation(.easeOut(duration: 0.3)) {
                isCheckingSession = false
            }
            print("🏠 [ROOT] ========== ROOT TASK END ==========")
        }
        .onChange(of: profileService.currentProfile?.onboardingVersion) { oldValue, newValue in
            print("🏠 [ROOT] ⚡️ ONBOARDING VERSION CHANGED: \(oldValue.map { String($0) } ?? "nil") -> \(newValue.map { String($0) } ?? "nil")")
            print("🏠 [ROOT] ⚡️ shouldShowOnboarding is now: \(shouldShowOnboarding)")
        }
        .onChange(of: authService.isAuthenticated) { wasAuthenticated, isAuthenticated in
            print("🏠 [ROOT] ⚡️ AUTH STATE CHANGED: \(wasAuthenticated) -> \(isAuthenticated)")

            // User just signed in - fetch profile
            if !wasAuthenticated && isAuthenticated {
                print("🏠 [ROOT] ⚡️ User just signed in - fetching profile...")
                Task {
                    await profileService.fetchProfile()
                    await streakService.fetchStats()
                    await gamificationService.loadGamificationData()
                    print("🏠 [ROOT] ⚡️ Profile and gamification fetch complete after sign-in")
                }
            }

            // User signed out - reset profile and gamification state
            if wasAuthenticated && !isAuthenticated {
                print("🏠 [ROOT] ⚡️ User signed out - resetting profile and gamification")
                profileService.reset()
                gamificationService.reset()
            }
        }
    }

    // MARK: - Helpers

    private func saveUserLocationForPreGeneration() async {
        if let location = await LocationService.shared.getCurrentLocation() {
            await StyleumAPI.shared.saveLocationForPreGeneration(
                latitude: location.latitude,
                longitude: location.longitude
            )
        }
    }
}

#Preview {
    RootView()
}
