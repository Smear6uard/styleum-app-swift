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
        let _ = print("🏠 [ROOT] 🔄 Body re-evaluated - isAuth: \(authService.isAuthenticated), hasUser: \(authService.currentUser != nil)")
        Group {
            if isCheckingSession {
                // Splash screen while checking session
                SplashView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .onAppear {
                        print("🏠 [ROOT] 📱 SHOWING: SplashView (isCheckingSession=true)")
                    }
            } else if !authService.isAuthenticated {
                // Not logged in - show login
                LoginScreen()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .onAppear {
                        print("🏠 [ROOT] 📱 SHOWING: LoginScreen")
                        print("🏠 [ROOT] Reason: isAuthenticated=false")
                    }
            } else if authService.isAuthenticated && profileService.isLoading {
                // Authenticated and profile is actively loading - show splash
                SplashView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .onAppear {
                        print("🏠 [ROOT] 📱 SHOWING: SplashView (profile loading)")
                        print("🏠 [ROOT] Reason: isAuthenticated=true, isLoading=true")
                    }
            } else if !profileService.hasFetchedOnce {
                // Authenticated but haven't attempted profile fetch yet - show splash
                SplashView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .onAppear {
                        print("🏠 [ROOT] 📱 SHOWING: SplashView (waiting for profile fetch)")
                        print("🏠 [ROOT] Reason: isAuthenticated=true, hasFetchedOnce=false")
                    }
            } else if shouldShowOnboarding {
                // Profile loaded, needs onboarding - smooth crossfade
                OnboardingContainerView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .environment(AppCoordinator())
                    .onAppear {
                        print("🏠 [ROOT] 📱 SHOWING: OnboardingContainerView")
                        print("🏠 [ROOT] Reason: isAuthenticated=true, shouldShowOnboarding=true")
                    }
            } else if profileService.currentProfile != nil {
                // Profile loaded, onboarding complete - show main app
                MainTabView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .achievementCelebration()
                    .levelUpCelebration()
                    .streakMilestoneCelebration()
                    .dailyGoalCelebration()
                    .firstMilestoneCelebration()
                    .streakProtection()
                    .referralCelebration()
                    .xpToastOverlay()
                    .onAppear {
                        print("🏠 [ROOT] 📱 SHOWING: MainTabView")
                        print("🏠 [ROOT] Reason: isAuthenticated=true, shouldShowOnboarding=false, profile loaded")
                    }
            } else {
                // Authenticated but profile still loading or failed - keep showing splash
                // This handles: hasFetchedOnce=true, currentProfile=nil, isLoading=false
                SplashView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .onAppear {
                        print("🏠 [ROOT] 📱 SHOWING: SplashView (profile state unknown)")
                        print("🏠 [ROOT] Reason: isAuthenticated=true, hasFetchedOnce=true, currentProfile=nil")
                        print("🏠 [ROOT] Profile error: \(profileService.error?.localizedDescription ?? "none")")
                        // If there's an error and we've fetched, try to refetch
                        if profileService.error != nil && profileService.hasFetchedOnce {
                            print("🏠 [ROOT] ⚠️ Profile fetch had error, attempting retry...")
                            Task {
                                try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1s before retry
                                await profileService.fetchProfile()
                            }
                        }
                    }
            }
        }
        .animation(AppAnimations.springGentle, value: isCheckingSession)
        .animation(AppAnimations.springGentle, value: authService.isAuthenticated)
        .animation(AppAnimations.springGentle, value: profileService.isLoading)
        .animation(AppAnimations.springGentle, value: shouldShowOnboarding)
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

            // Brief delay for splash (reduced for smoother feel)
            print("🏠 [ROOT] Step 5: Waiting 0.5s splash delay...")
            try? await Task.sleep(nanoseconds: 500_000_000)
            print("🏠 [ROOT] Step 5 Complete.")

            print("🏠 [ROOT] Step 6: Setting isCheckingSession=false with animation")
            print("🏠 [ROOT] Final state check:")
            print("🏠 [ROOT]   - isAuthenticated: \(authService.isAuthenticated)")
            print("🏠 [ROOT]   - profile exists: \(profileService.currentProfile != nil)")
            print("🏠 [ROOT]   - onboardingVersion: \(profileService.currentProfile?.onboardingVersion.map { String($0) } ?? "nil")")
            print("🏠 [ROOT]   - shouldShowOnboarding will be: \(shouldShowOnboarding)")

            // Smooth transition with spring animation
            withAnimation(AppAnimations.springGentle) {
                isCheckingSession = false
            }
            print("🏠 [ROOT] ========== ROOT TASK END ==========")
        }
        .onChange(of: profileService.currentProfile?.onboardingVersion) { oldValue, newValue in
            print("🏠 [ROOT] ⚡️ ONBOARDING VERSION CHANGED: \(oldValue.map { String($0) } ?? "nil") -> \(newValue.map { String($0) } ?? "nil")")
            print("🏠 [ROOT] ⚡️ shouldShowOnboarding is now: \(shouldShowOnboarding)")

            // Check for pending referral code when onboarding completes
            if let version = newValue, version >= 2 {
                applyPendingReferralCodeIfNeeded()
                
                // Trigger tier onboarding check after onboarding completes
                // Check if user just completed onboarding (oldValue was < 2 or nil, newValue is >= 2)
                let wasInOnboarding = oldValue == nil || (oldValue ?? 0) < 2
                let justCompleted = wasInOnboarding && version >= 2
                
                if justCompleted {
                    print("🏠 [ROOT] ⚡️ Onboarding just completed - checking for tier onboarding")
                    Task {
                        let tierManager = TierManager.shared
                        await tierManager.refresh()
                        // Small delay for smooth transition
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                        if !tierManager.hasSeenTierOnboarding && tierManager.isFree {
                            print("🏠 [ROOT] ✅ Posting notification to show tier onboarding")
                            NotificationCenter.default.post(name: .showTierOnboarding, object: nil)
                        }
                    }
                }
            }
        }
        .onChange(of: authService.isAuthenticated) { wasAuthenticated, isAuthenticated in
            print("🏠 [ROOT] ⚡️ AUTH STATE CHANGED: \(wasAuthenticated) -> \(isAuthenticated)")

            // User just signed in - fetch profile
            if !wasAuthenticated && isAuthenticated {
                print("🏠 [ROOT] ⚡️ User just signed in - fetching profile...")
                print("🏠 [ROOT] ⚡️ Current state - hasFetchedOnce: \(profileService.hasFetchedOnce), isLoading: \(profileService.isLoading), currentProfile: \(profileService.currentProfile != nil ? "exists" : "nil")")
                Task {
                    // Ensure we wait for profile fetch to complete
                    await profileService.fetchProfile()
                    print("🏠 [ROOT] ⚡️ Profile fetch complete - hasFetchedOnce: \(profileService.hasFetchedOnce), currentProfile: \(profileService.currentProfile != nil ? "exists" : "nil")")
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

    /// Applies any pending referral code from deep links after onboarding completes
    private func applyPendingReferralCodeIfNeeded() {
        guard let pendingCode = ReferralService.shared.getPendingCode() else {
            return
        }

        print("📨 [Referral] Found pending code after onboarding: \(pendingCode)")

        Task {
            do {
                let result = try await ReferralService.shared.applyCode(pendingCode)
                ReferralService.shared.clearPendingCode()

                switch result {
                case .success(let daysEarned):
                    print("📨 [Referral] Successfully applied pending code, earned \(daysEarned) days")
                    // Show celebration is handled elsewhere (e.g., via notification or direct UI)
                default:
                    print("📨 [Referral] Pending code application result: \(result)")
                }
            } catch {
                print("📨 [Referral] Failed to apply pending code: \(error)")
                ReferralService.shared.clearPendingCode()
            }
        }
    }

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
