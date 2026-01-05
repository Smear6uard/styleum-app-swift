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
        guard SupabaseManager.shared.currentUserId != nil else {
            print("[StreakService] No user ID")
            return
        }

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

            print("[StreakService] Fetched stats: streak=\(currentStreak), level=\(level)")
        } catch {
            self.error = error
            print("[StreakService] Fetch error: \(error)")
        }
    }

    // MARK: - Use Streak Freeze

    func useStreakFreeze() async -> Bool {
        guard SupabaseManager.shared.currentUserId != nil else { return false }

        do {
            let stats = try await api.useStreakFreeze()

            currentStreak = stats.currentStreak
            longestStreak = stats.longestStreak
            streakFreezes = stats.streakFreezes

            HapticManager.shared.success()
            print("[StreakService] Used streak freeze, \(streakFreezes) remaining")
            return true
        } catch {
            self.error = error
            print("[StreakService] Use freeze error: \(error)")
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
            print("[StreakService] Restored streak to \(currentStreak)")
            return true
        } catch {
            self.error = error
            print("[StreakService] Restore error: \(error)")
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
