import SwiftUI

struct RootView: View {
    @State private var authService = AuthService.shared
    @State private var streakService = StreakService.shared
    @State private var isCheckingSession = true

    var body: some View {
        Group {
            if isCheckingSession {
                // Splash screen
                SplashView()
            } else if authService.isAuthenticated {
                MainTabView()
                    .achievementCelebration()
            } else {
                LoginScreen()
            }
        }
        .task {
            await authService.checkSession()

            // Brief delay for splash
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            withAnimation(.easeOut(duration: 0.3)) {
                isCheckingSession = false
            }

            // Fetch gamification stats when user is authenticated
            if authService.isAuthenticated {
                await streakService.fetchStats()
            }
        }
    }
}

#Preview {
    RootView()
}
