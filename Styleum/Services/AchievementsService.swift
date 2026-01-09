import Foundation

// Notification for achievement unlocks
extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}

@Observable
final class AchievementsService {
    static let shared = AchievementsService()

    private let api = StyleumAPI.shared

    var achievements: [Achievement] = []
    var isLoading = false
    var error: Error?

    // MARK: - Computed Properties

    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    var totalCount: Int {
        achievements.count
    }

    var unseenCount: Int {
        achievements.filter { $0.isNew }.count
    }

    private init() {}

    // MARK: - Fetch Achievements

    func fetchAchievements() async {
        guard SupabaseManager.shared.currentUserId != nil else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            achievements = try await api.getAchievements()
            self.error = nil
        } catch {
            self.error = error
        }
    }

    // MARK: - Mark Achievement as Seen

    func markAsSeen(achievementId: String) async {
        guard SupabaseManager.shared.currentUserId != nil else { return }

        do {
            try await api.markAchievementSeen(id: achievementId)

            // Update local state
            if let index = achievements.firstIndex(where: { $0.id == achievementId }) {
                achievements[index].seenAt = Date()
            }
        } catch {
            print("Failed to mark achievement as seen: \(error)")
        }
    }

    // MARK: - Get Achievements by Category

    func achievements(for category: AchievementCategory) -> [Achievement] {
        achievements.filter { $0.category == category }
    }

    // MARK: - Get Next Achievement to Unlock

    func nextAchievement(for category: AchievementCategory? = nil) -> Achievement? {
        let filtered = category != nil
            ? achievements.filter { $0.category == category && !$0.isUnlocked }
            : achievements.filter { !$0.isUnlocked }

        return filtered
            .sorted { $0.progressPercent > $1.progressPercent }
            .first
    }

    // MARK: - Reset State

    func reset() {
        achievements = []
        isLoading = false
        error = nil
    }
}
