import SwiftUI

/// Standalone style quiz for users who skipped during onboarding or want to retake
struct StandaloneStyleQuizView: View {
    @Environment(AppCoordinator.self) var coordinator
    @State private var profileService = ProfileService.shared
    @State private var isSubmitting = false

    // Style quiz state - kept here to survive StyleSwipeView recreation
    @State private var likedIds: [String] = []
    @State private var dislikedIds: [String] = []

    var body: some View {
        StyleSwipeView(
            department: profileService.currentProfile?.departments?.first ?? "womenswear",
            likedIds: $likedIds,
            dislikedIds: $dislikedIds,
            onComplete: {
                submitStyleQuiz()
            }
        )
        .interactiveDismissDisabled()
    }

    private func submitStyleQuiz() {
        guard !isSubmitting else { return }

        // If user skipped again (no likes), just dismiss
        if likedIds.isEmpty {
            coordinator.dismissFullScreen()
            return
        }

        isSubmitting = true

        Task {
            do {
                try await StyleumAPI.shared.submitStyleQuiz(
                    likedStyleIds: likedIds,
                    dislikedStyleIds: dislikedIds
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
