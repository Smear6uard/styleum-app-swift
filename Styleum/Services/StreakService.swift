import Foundation

@Observable
final class StreakService {
    static let shared = StreakService()

    private let api = StyleumAPI.shared

    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalDaysActive: Int = 0
    var streakFreezes: Int = 0
    var xp: Int = 0
    var level: Int = 1
    var isLoading = false
    var error: Error?

    private init() {}

    // MARK: - Fetch Gamification Stats

    func fetchStats() async {
        guard SupabaseManager.shared.currentUserId != nil else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let stats = try await api.getGamificationStats()

            currentStreak = stats.currentStreak
            longestStreak = stats.longestStreak
            totalDaysActive = stats.totalDaysActive
            streakFreezes = stats.streakFreezes
            xp = stats.xp
            level = stats.level

            self.error = nil
        } catch {
            self.error = error
        }
    }

    // MARK: - Use Streak Freeze

    func useStreakFreeze() async -> Bool {
        guard SupabaseManager.shared.currentUserId != nil else { return false }
        guard streakFreezes > 0 else { return false }

        do {
            let stats = try await api.useStreakFreeze()

            currentStreak = stats.currentStreak
            longestStreak = stats.longestStreak
            streakFreezes = stats.streakFreezes

            HapticManager.shared.success()
            return true
        } catch {
            self.error = error
            HapticManager.shared.error()
            return false
        }
    }

    // MARK: - Restore Streak (Pro only)

    func restoreStreak() async -> Bool {
        guard SupabaseManager.shared.currentUserId != nil else { return false }

        do {
            let stats = try await api.restoreStreak()

            currentStreak = stats.currentStreak
            longestStreak = stats.longestStreak

            HapticManager.shared.streakMilestone()
            return true
        } catch {
            self.error = error
            HapticManager.shared.error()
            return false
        }
    }

    // MARK: - Check Streak Milestone

    func checkStreakMilestone(_ streak: Int) {
        let milestones = [3, 7, 14, 30, 100]

        if milestones.contains(streak) {
            HapticManager.shared.streakMilestone()
        }
    }

    // MARK: - Reset State

    func reset() {
        currentStreak = 0
        longestStreak = 0
        totalDaysActive = 0
        streakFreezes = 0
        xp = 0
        level = 1
        isLoading = false
        error = nil
    }
}

// MARK: - Streak Result

struct StreakResult {
    let success: Bool
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var streakIncreased: Bool = false
    var streakReset: Bool = false
    var newlyUnlocked: [UnlockedAchievement] = []
}
