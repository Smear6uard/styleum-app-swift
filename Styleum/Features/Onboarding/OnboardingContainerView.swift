import SwiftUI

/// Onboarding step enumeration
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case name = 1
    case department = 2
    case styleSwipes = 3
    case referralSource = 4
    case complete = 5
}

/// Main coordinator view for the onboarding flow
struct OnboardingContainerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppCoordinator.self) var coordinator
    @State private var currentStep: OnboardingStep = .welcome
    @State private var userData = OnboardingUserData()
    @State private var isSubmitting = false
    @State private var profileService = ProfileService.shared

    var body: some View {
        ZStack {
            // Background - changes based on step
            if currentStep == .welcome {
                Color.black.ignoresSafeArea()
            } else {
                AppColors.background.ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // Progress bar (only on name, department, styleSwipes)
                if showsProgressBar {
                    OnboardingProgressBar(
                        currentStep: progressStep,
                        totalSteps: 3  // name, department, styleSwipes
                    )
                    .padding(.horizontal, AppSpacing.pageMargin)
                    .padding(.top, 8)
                }

                // Content
                TabView(selection: $currentStep) {
                    OnboardingWelcomeView(onContinue: { nextStep() })
                        .tag(OnboardingStep.welcome)

                    OnboardingNameView(
                        name: $userData.firstName,
                        onContinue: { nextStep() }
                    )
                    .tag(OnboardingStep.name)

                    OnboardingDepartmentView(
                        selectedDepartment: $userData.department,
                        onContinue: { nextStep() }
                    )
                    .tag(OnboardingStep.department)

                    StyleSwipeView(
                        department: userData.department.isEmpty ? "womenswear" : userData.department,
                        onComplete: { liked, disliked in
                            print("📋 [ONBOARDING] StyleSwipeView completed")
                            print("📋 [ONBOARDING] Liked styles: \(liked.count)")
                            print("📋 [ONBOARDING] Disliked styles: \(disliked.count)")
                            userData.likedStyleIds = liked
                            userData.dislikedStyleIds = disliked
                            nextStep()
                        }
                    )
                    .tag(OnboardingStep.styleSwipes)

                    OnboardingReferralSourceView(
                        onSelect: { source in
                            print("📋 [ONBOARDING] Referral source selected: \(source)")
                            userData.referralSource = source
                            nextStep()
                        },
                        onSkip: {
                            print("📋 [ONBOARDING] Referral source skipped")
                            nextStep()
                        }
                    )
                    .tag(OnboardingStep.referralSource)

                    OnboardingCompleteView(
                        firstName: userData.firstName,
                        onContinue: { completeOnboarding() }
                    )
                    .tag(OnboardingStep.complete)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .interactiveDismissDisabled()
        .onAppear {
            print("📋 [ONBOARDING] ========== ONBOARDING CONTAINER APPEARED ==========")
            print("📋 [ONBOARDING] Starting at step: \(currentStep)")
            print("📋 [ONBOARDING] ProfileService.currentProfile: \(profileService.currentProfile?.id ?? "nil")")
            print("📋 [ONBOARDING] Profile onboardingVersion: \(profileService.currentProfile?.onboardingVersion.map { String($0) } ?? "nil")")
        }
    }

    // MARK: - Progress Bar Logic

    private var showsProgressBar: Bool {
        switch currentStep {
        case .name, .department, .styleSwipes:
            return true
        default:
            return false
        }
    }

    /// Maps current step to progress bar step (1-indexed)
    private var progressStep: Int {
        switch currentStep {
        case .name: return 1
        case .department: return 2
        case .styleSwipes: return 3
        default: return 0
        }
    }

    // MARK: - Navigation

    private func nextStep() {
        print("📋 [ONBOARDING] nextStep() called from step: \(currentStep)")
        if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            print("📋 [ONBOARDING] Moving to step: \(next)")
            withAnimation {
                currentStep = next
            }
            HapticManager.shared.light()
        } else {
            print("📋 [ONBOARDING] ⚠️ No next step available from: \(currentStep)")
        }
    }

    // MARK: - Completion

    @MainActor
    private func completeOnboarding() {
        print("📋 [ONBOARDING] ========== COMPLETE ONBOARDING START ==========")
        print("📋 [ONBOARDING] Timestamp: \(Date())")
        print("📋 [ONBOARDING] isSubmitting: \(isSubmitting)")

        guard !isSubmitting else {
            print("📋 [ONBOARDING] ⚠️ Already submitting - returning early")
            return
        }
        isSubmitting = true
        print("📋 [ONBOARDING] Set isSubmitting=true")

        print("📋 [ONBOARDING] User data summary:")
        print("📋 [ONBOARDING]   - firstName: \(userData.firstName)")
        print("📋 [ONBOARDING]   - department: \(userData.department)")
        print("📋 [ONBOARDING]   - likedStyleIds count: \(userData.likedStyleIds.count)")
        print("📋 [ONBOARDING]   - dislikedStyleIds count: \(userData.dislikedStyleIds.count)")
        print("📋 [ONBOARDING]   - referralSource: \(userData.referralSource ?? "nil")")

        let totalSwipes = userData.likedStyleIds.count + userData.dislikedStyleIds.count
        if totalSwipes == 0 {
            print("📋 [ONBOARDING] ⚠️ USER SKIPPED STYLE QUIZ - 0 swipes!")
            print("📋 [ONBOARDING] ⚠️ Backend should set style_quiz_completed=FALSE")
        } else {
            print("📋 [ONBOARDING] ✅ User completed style quiz with \(totalSwipes) swipes")
            print("📋 [ONBOARDING] ✅ Backend should set style_quiz_completed=TRUE")
        }

        Task { @MainActor in
            do {
                print("📋 [ONBOARDING] Calling StyleumAPI.completeOnboarding()...")
                // Send onboarding data to API
                try await StyleumAPI.shared.completeOnboarding(
                    firstName: userData.firstName,
                    departments: Set([userData.department]),  // Single value wrapped in Set for API
                    likedStyleIds: userData.likedStyleIds,
                    dislikedStyleIds: userData.dislikedStyleIds,
                    favoriteBrands: Set<String>(),  // Empty - removed from flow
                    bodyShape: nil  // Removed from flow
                )

                print("📋 [ONBOARDING] ✅ API call successful")

                HapticManager.shared.success()

                print("📋 [ONBOARDING] Refreshing profile to get updated values...")
                // Refresh profile to get updated onboardingVersion
                await profileService.fetchProfile()
                print("📋 [ONBOARDING] Profile refreshed:")
                print("📋 [ONBOARDING]   - onboardingVersion: \(profileService.currentProfile?.onboardingVersion.map { String($0) } ?? "nil")")
                print("📋 [ONBOARDING]   - styleQuizCompleted: \(profileService.currentProfile?.styleQuizCompleted.map { String($0) } ?? "nil")")
                print("📋 [ONBOARDING] ⚠️ If styleQuizCompleted=true but user skipped, there's a backend bug!")

                // Note: No need to call dismissFullScreen() - RootView will automatically
                // switch to MainTabView when shouldShowOnboarding becomes false
                print("📋 [ONBOARDING] ✅ Profile updated, RootView should now show MainTabView")
                print("📋 [ONBOARDING] ========== COMPLETE ONBOARDING END (SUCCESS) ==========")
            } catch APIError.onboardingAlreadyComplete(let version) {
                // Onboarding was already completed - treat as success
                print("📋 [ONBOARDING] ⚠️ Onboarding already completed (version: \(version ?? -1))")
                print("📋 [ONBOARDING] Treating as success and continuing...")
                HapticManager.shared.success()

                print("📋 [ONBOARDING] Refreshing profile...")
                // Refresh profile to get current onboardingVersion
                await profileService.fetchProfile()

                print("📋 [ONBOARDING] ✅ Profile updated, RootView should now show MainTabView")
                print("📋 [ONBOARDING] ========== COMPLETE ONBOARDING END (ALREADY COMPLETE) ==========")
            } catch {
                print("📋 [ONBOARDING] ❌ Onboarding completion error!")
                print("📋 [ONBOARDING] Error type: \(type(of: error))")
                print("📋 [ONBOARDING] Error description: \(error.localizedDescription)")
                print("📋 [ONBOARDING] Full error: \(error)")
                isSubmitting = false
                print("📋 [ONBOARDING] Set isSubmitting=false")
                // On error, still try to refresh profile - maybe it completed but we got a network error
                print("📋 [ONBOARDING] Refreshing profile to check status...")
                await profileService.fetchProfile()
                print("📋 [ONBOARDING] Profile after error: onboardingVersion=\(profileService.currentProfile?.onboardingVersion.map { String($0) } ?? "nil")")
                print("📋 [ONBOARDING] ========== COMPLETE ONBOARDING END (ERROR) ==========")
            }
        }
    }
}

#Preview {
    OnboardingContainerView()
}
