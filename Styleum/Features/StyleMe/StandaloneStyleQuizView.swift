import SwiftUI

/// Standalone style quiz for users who skipped during onboarding
struct StandaloneStyleQuizView: View {
    @Environment(AppCoordinator.self) var coordinator
    @State private var profileService = ProfileService.shared
    @State private var isSubmitting = false

    var body: some View {
        StyleSwipeView(
            department: profileService.currentProfile?.departments?.first ?? "womenswear",
            onComplete: { liked, disliked in
                submitStyleQuiz(liked: liked, disliked: disliked)
            }
        )
        .interactiveDismissDisabled()
    }

    private func submitStyleQuiz(liked: [String], disliked: [String]) {
        guard !isSubmitting else { return }

        // If user skipped again (no likes), just dismiss
        if liked.isEmpty {
            coordinator.dismissFullScreen()
            return
        }

        isSubmitting = true

        Task {
            do {
                try await StyleumAPI.shared.submitStyleQuiz(
                    likedStyleIds: liked,
                    dislikedStyleIds: disliked
                )
                HapticManager.shared.success()
                await profileService.fetchProfile()
                coordinator.dismissFullScreen()
            } catch {
                print("Style quiz submission error: \(error)")
                isSubmitting = false
                coordinator.dismissFullScreen()
            }
        }
    }
}

#Preview {
    StandaloneStyleQuizView()
        .environment(AppCoordinator())
}
