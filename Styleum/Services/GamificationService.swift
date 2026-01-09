import Foundation
import SwiftUI

/// Central service for all gamification state and logic.
/// This is the single source of truth for XP, levels, streaks, daily challenges, and activity tracking.
@Observable
final class GamificationService {
    static let shared = GamificationService()

    private let api = StyleumAPI.shared

    // MARK: - Core Stats

    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalDaysActive: Int = 0
    var streakFreezes: Int = 0
    var xp: Int = 0
    var level: Int = 1
    var dailyGoalXP: Int = 50  // XP target for daily goal
    var dailyXPEarned: Int = 0  // XP earned today

    // MARK: - Streak State

    var streakFrozenToday: Bool = false
    var hasEngagedToday: Bool = false
    var streakAtRisk: Bool { !hasEngagedToday && currentStreak > 0 }
    var hoursUntilStreakLoss: Int = 24

    // MARK: - Activity History (for calendar)

    var activityHistory: [DayActivity] = []

    // MARK: - Daily Challenges

    var dailyChallenges: [DailyChallenge] = []
    var challengesResetsAt: Date?

    // MARK: - Weekly Challenge

    var weeklyChallenge: WeeklyChallenge?

    // MARK: - Loading State

    var isLoading = false
    var error: Error?

    // MARK: - Computed Properties

    /// XP needed for current level
    var xpForCurrentLevel: Int {
        xpRequiredForLevel(level)
    }

    /// XP needed for next level
    var xpForNextLevel: Int {
        xpRequiredForLevel(level + 1)
    }

    /// XP progress within current level (0.0 - 1.0)
    var levelProgress: Double {
        let currentLevelXP = xpForCurrentLevel
        let nextLevelXP = xpForNextLevel
        let xpInLevel = xp - currentLevelXP
        let xpNeeded = nextLevelXP - currentLevelXP
        return xpNeeded > 0 ? min(max(Double(xpInLevel) / Double(xpNeeded), 0), 1) : 0
    }

    /// XP within current level
    var xpInCurrentLevel: Int {
        max(0, xp - xpForCurrentLevel)
    }

    /// XP remaining to next level
    var xpToNextLevel: Int {
        max(0, xpForNextLevel - xp)
    }

    /// Daily goal progress (0.0 - 1.0)
    var dailyGoalProgress: Double {
        dailyGoalXP > 0 ? min(Double(dailyXPEarned) / Double(dailyGoalXP), 1.0) : 0
    }

    /// Daily goal completed
    var dailyGoalComplete: Bool {
        dailyXPEarned >= dailyGoalXP
    }

    /// Level title based on level
    var levelTitle: String {
        switch level {
        case 1: return "Style Novice"
        case 2: return "Fashion Curious"
        case 3: return "Wardrobe Builder"
        case 4: return "Style Explorer"
        case 5: return "Outfit Crafter"
        case 6: return "Trend Spotter"
        case 7: return "Look Curator"
        case 8: return "Style Confident"
        case 9: return "Fashion Forward"
        case 10: return "Wardrobe Master"
        case 11...15: return "Style Expert"
        case 16...20: return "Fashion Authority"
        case 21...30: return "Style Icon"
        case 31...50: return "Fashion Legend"
        default: return "Style Deity"
        }
    }

    /// Challenges completed today
    var completedChallengesCount: Int {
        dailyChallenges.filter { $0.isCompleted }.count
    }

    /// Total challenges today
    var totalChallengesCount: Int {
        dailyChallenges.count
    }

    /// Any challenges ready to claim
    var hasClaimableChallenges: Bool {
        dailyChallenges.contains { $0.isClaimable }
    }

    /// All daily challenges complete
    var allChallengesComplete: Bool {
        !dailyChallenges.isEmpty && dailyChallenges.allSatisfy { $0.isCompleted }
    }

    /// Time until challenges reset
    var timeUntilReset: String? {
        guard let resetsAt = challengesResetsAt else { return nil }
        let interval = resetsAt.timeIntervalSinceNow
        guard interval > 0 else { return nil }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Load All Gamification Data

    /// Convenience method to load all gamification data at once
    func loadGamificationData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchStats()
            }
            group.addTask {
                await self.fetchDailyChallenges()
            }
            group.addTask {
                await self.fetchActivityHistory()
            }
            group.addTask {
                await self.fetchWeeklyChallenge()
            }
        }
    }

    // MARK: - Reset State

    /// Reset all gamification state (for sign out)
    func reset() {
        currentStreak = 0
        longestStreak = 0
        totalDaysActive = 0
        streakFreezes = 0
        xp = 0
        level = 1
        dailyGoalXP = 50
        dailyXPEarned = 0
        streakFrozenToday = false
        hasEngagedToday = false
        hoursUntilStreakLoss = 24
        activityHistory = []
        dailyChallenges = []
        challengesResetsAt = nil
        weeklyChallenge = nil
        isLoading = false
        error = nil
    }

    // MARK: - XP Calculation

    /// XP required to reach a specific level
    private func xpRequiredForLevel(_ level: Int) -> Int {
        // Level 1 = 0 XP, Level 2 = 100 XP, Level 3 = 250 XP, etc.
        // Formula: sum of (50 * n) for n from 1 to (level - 1)
        guard level > 1 else { return 0 }
        return (1..<level).reduce(0) { $0 + (50 + ($1 - 1) * 25) }
    }

    /// Calculate level from XP
    private func levelFromXP(_ xp: Int) -> Int {
        var level = 1
        while xpRequiredForLevel(level + 1) <= xp {
            level += 1
        }
        return level
    }

    // MARK: - Fetch All Stats

    func fetchStats() async {
        guard SupabaseManager.shared.currentUserId != nil else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let stats = try await api.getGamificationStats()

            let oldLevel = level

            // Update all stats
            currentStreak = stats.currentStreak
            longestStreak = stats.longestStreak
            totalDaysActive = stats.totalDaysActive
            streakFreezes = stats.streakFreezes
            xp = stats.xp
            level = stats.level
            dailyXPEarned = stats.dailyXPEarned ?? 0
            dailyGoalXP = stats.dailyGoalXP ?? 50
            hasEngagedToday = stats.hasEngagedToday ?? false
            streakFrozenToday = stats.streakFrozenToday ?? false
            hoursUntilStreakLoss = stats.hoursUntilStreakLoss ?? 24

            // Check for level up
            if stats.level > oldLevel && oldLevel > 0 {
                NotificationCenter.default.post(
                    name: .levelUp,
                    object: LevelUpInfo(newLevel: stats.level, oldLevel: oldLevel, levelTitle: levelTitle)
                )
            }

            self.error = nil

        } catch {
            self.error = error
        }
    }

    // MARK: - Fetch Daily Challenges

    func fetchDailyChallenges() async {
        guard SupabaseManager.shared.currentUserId != nil else { return }

        do {
            let response = try await api.getDailyChallenges()
            dailyChallenges = response.challenges
            challengesResetsAt = response.resetsAt
        } catch {
            print("Failed to fetch daily challenges: \(error)")
        }
    }

    // MARK: - Fetch Activity History

    func fetchActivityHistory(days: Int = 7) async {
        guard SupabaseManager.shared.currentUserId != nil else { return }

        do {
            activityHistory = try await api.getActivityHistory(days: days)
        } catch {
            print("Failed to fetch activity history: \(error)")
        }
    }

    // MARK: - Fetch Weekly Challenge

    func fetchWeeklyChallenge() async {
        guard SupabaseManager.shared.currentUserId != nil else { return }

        do {
            weeklyChallenge = try await api.getWeeklyChallenge()
        } catch {
            print("Failed to fetch weekly challenge: \(error)")
        }
    }

    // MARK: - Award XP (Local optimistic update)

    func awardXP(_ amount: Int, reason: XPReason, showToast: Bool = true) {
        let oldLevel = level
        let oldDailyXP = dailyXPEarned

        xp += amount
        dailyXPEarned += amount
        level = levelFromXP(xp)
        hasEngagedToday = true

        if showToast {
            XPToastManager.shared.showToast(
                amount: amount,
                reason: reason,
                isBonus: reason == .verifiedWear
            )
        }

        // Check for level up
        if level > oldLevel {
            HapticManager.shared.achievementUnlock()
            NotificationCenter.default.post(
                name: .levelUp,
                object: LevelUpInfo(newLevel: level, oldLevel: oldLevel, levelTitle: levelTitle)
            )
        }

        // Check daily goal completion
        let wasGoalComplete = oldDailyXP >= dailyGoalXP
        if dailyXPEarned >= dailyGoalXP && !wasGoalComplete {
            HapticManager.shared.success()
            NotificationCenter.default.post(name: .dailyGoalComplete, object: nil)
        }
    }

    // MARK: - Update Challenge Progress (Local)

    func updateChallengeProgress(for type: DailyChallengeType, increment: Int = 1) {
        guard let index = dailyChallenges.firstIndex(where: { $0.type == type && !$0.isCompleted }) else {
            return
        }

        dailyChallenges[index].progress = min(
            dailyChallenges[index].progress + increment,
            dailyChallenges[index].target
        )

        // Haptic if now claimable
        if dailyChallenges[index].isClaimable {
            HapticManager.shared.success()
            NotificationCenter.default.post(
                name: .challengeReadyToClaim,
                object: dailyChallenges[index]
            )
        }
    }

    // MARK: - Claim Challenge Reward

    func claimChallenge(_ challenge: DailyChallenge) async -> Bool {
        guard SupabaseManager.shared.currentUserId != nil else { return false }
        guard challenge.isClaimable else { return false }

        do {
            let response = try await api.claimDailyChallenge(id: challenge.id)

            // Update local state
            if let index = dailyChallenges.firstIndex(where: { $0.id == challenge.id }) {
                dailyChallenges[index] = response.challenge
            }

            // Award XP with toast
            awardXP(response.xpAwarded, reason: .challengeComplete)

            HapticManager.shared.success()

            // Check if all challenges complete
            if allChallengesComplete {
                NotificationCenter.default.post(name: .allChallengesComplete, object: nil)
            }

            return true

        } catch {
            HapticManager.shared.error()
            return false
        }
    }

    // MARK: - Streak Freeze

    func useStreakFreeze() async -> Bool {
        guard SupabaseManager.shared.currentUserId != nil else { return false }
        guard streakFreezes > 0 else { return false }

        do {
            let stats = try await api.useStreakFreeze()

            currentStreak = stats.currentStreak
            longestStreak = stats.longestStreak
            streakFreezes = stats.streakFreezes
            streakFrozenToday = true

            HapticManager.shared.success()

            XPToastManager.shared.showToast(
                amount: 0,
                reason: .streakFreeze,
                isBonus: false,
                customMessage: "Streak frozen!"
            )

            return true

        } catch {
            HapticManager.shared.error()
            return false
        }
    }

    // MARK: - Restore Streak (Pro)

    func restoreStreak() async -> Bool {
        guard SupabaseManager.shared.currentUserId != nil else { return false }

        do {
            let stats = try await api.restoreStreak()

            currentStreak = stats.currentStreak
            longestStreak = stats.longestStreak

            // Deduct XP for restore
            xp = max(0, xp - 500)

            HapticManager.shared.streakMilestone()

            NotificationCenter.default.post(name: .streakRestored, object: nil)

            return true

        } catch {
            HapticManager.shared.error()
            return false
        }
    }

    // MARK: - Milestone Check

    func checkStreakMilestone(_ streak: Int) -> StreakMilestone? {
        let milestones: [StreakMilestone] = [
            StreakMilestone(days: 7, label: "Week", icon: "flame"),
            StreakMilestone(days: 14, label: "Fortnight", icon: "flame.fill"),
            StreakMilestone(days: 30, label: "Month", icon: "star"),
            StreakMilestone(days: 60, label: "Devoted", icon: "star.fill"),
            StreakMilestone(days: 90, label: "Master", icon: "crown"),
            StreakMilestone(days: 365, label: "Legend", icon: "crown.fill")
        ]

        return milestones.first { $0.days == streak }
    }

    var currentMilestone: StreakMilestone? {
        let milestones: [StreakMilestone] = [
            StreakMilestone(days: 7, label: "Week", icon: "flame"),
            StreakMilestone(days: 14, label: "Fortnight", icon: "flame.fill"),
            StreakMilestone(days: 30, label: "Month", icon: "star"),
            StreakMilestone(days: 60, label: "Devoted", icon: "star.fill"),
            StreakMilestone(days: 90, label: "Master", icon: "crown"),
            StreakMilestone(days: 365, label: "Legend", icon: "crown.fill")
        ]
        return milestones.last { $0.days <= currentStreak }
    }

    var nextMilestone: StreakMilestone? {
        let milestones: [StreakMilestone] = [
            StreakMilestone(days: 7, label: "Week", icon: "flame"),
            StreakMilestone(days: 14, label: "Fortnight", icon: "flame.fill"),
            StreakMilestone(days: 30, label: "Month", icon: "star"),
            StreakMilestone(days: 60, label: "Devoted", icon: "star.fill"),
            StreakMilestone(days: 90, label: "Master", icon: "crown"),
            StreakMilestone(days: 365, label: "Legend", icon: "crown.fill")
        ]
        return milestones.first { $0.days > currentStreak }
    }
}

// MARK: - Supporting Types

struct StreakMilestone {
    let days: Int
    let label: String
    let icon: String
}

struct LevelUpInfo {
    let newLevel: Int
    let oldLevel: Int
    let levelTitle: String
}

enum XPReason: String {
    case outfitWorn = "Outfit worn"
    case verifiedWear = "Verified wear"
    case itemAdded = "Item added"
    case outfitGenerated = "Looks generated"
    case outfitSaved = "Outfit saved"
    case outfitLiked = "Outfit liked"
    case outfitShared = "Outfit shared"
    case challengeComplete = "Challenge complete"
    case dailyGoal = "Daily goal"
    case streakBonus = "Streak bonus"
    case achievementUnlocked = "Achievement"
    case streakFreeze = "Streak freeze"
    case weeklyChallenge = "Weekly challenge"

    var icon: String {
        switch self {
        case .outfitWorn, .verifiedWear: return "checkmark.circle.fill"
        case .itemAdded: return "plus.circle.fill"
        case .outfitGenerated: return "sparkles"
        case .outfitSaved, .outfitLiked: return "heart.fill"
        case .outfitShared: return "square.and.arrow.up"
        case .challengeComplete: return "star.fill"
        case .dailyGoal: return "target"
        case .streakBonus: return "flame.fill"
        case .achievementUnlocked: return "trophy.fill"
        case .streakFreeze: return "snowflake"
        case .weeklyChallenge: return "calendar"
        }
    }
}

// MARK: - Daily Challenge Model

struct DailyChallenge: Identifiable, Codable, Equatable {
    let id: String
    let type: DailyChallengeType?
    let title: String
    let description: String
    let target: Int
    var progress: Int
    let xpReward: Int
    let iconName: String?
    let isCompleted: Bool
    let isClaimed: Bool
    let date: Date?

    var isClaimable: Bool { progress >= target && !isCompleted && !isClaimed }

    var progressPercent: Double {
        guard target > 0 else { return 0 }
        return min(max(Double(progress) / Double(target), 0), 1)
    }

    var progressText: String {
        "\(progress)/\(target)"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title = "name"
        case description
        case target
        case progress
        case xpReward = "xp_reward"
        case iconName = "icon_name"
        case isCompleted = "is_completed"
        case isClaimed = "is_claimed"
        case date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decodeIfPresent(DailyChallengeType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        target = try container.decode(Int.self, forKey: .target)
        progress = try container.decodeIfPresent(Int.self, forKey: .progress) ?? 0
        xpReward = try container.decodeIfPresent(Int.self, forKey: .xpReward) ?? 0
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        isClaimed = try container.decodeIfPresent(Bool.self, forKey: .isClaimed) ?? false
        date = try container.decodeIfPresent(Date.self, forKey: .date)
    }
}

enum DailyChallengeType: String, Codable, CaseIterable {
    case wearOutfit = "wear_outfit"
    case addItem = "add_item"
    case generateOutfit = "generate_outfit"
    case saveOutfit = "save_outfit"
    case viewWardrobe = "view_wardrobe"

    var displayName: String {
        switch self {
        case .wearOutfit: return "Wear Outfit"
        case .addItem: return "Add Item"
        case .generateOutfit: return "Get Styled"
        case .saveOutfit: return "Save Look"
        case .viewWardrobe: return "Browse"
        }
    }

    var color: Color {
        switch self {
        case .wearOutfit: return AppColors.success
        case .addItem: return AppColors.slate
        case .generateOutfit: return Color(hex: "8B5CF6")
        case .saveOutfit: return Color(hex: "F59E0B")
        case .viewWardrobe: return AppColors.slateDark
        }
    }
}

struct DailyChallengesResponse: Codable {
    let challenges: [DailyChallenge]
    let totalXpAvailable: Int?
    let completedCount: Int?
    let date: Date?
    let resetsAt: Date?

    enum CodingKeys: String, CodingKey {
        case challenges
        case totalXpAvailable = "total_xp_available"
        case completedCount = "completed_count"
        case date
        case resetsAt = "resets_at"
    }
}

struct ChallengeCompletionResponse: Codable {
    let success: Bool
    let challenge: DailyChallenge
    let xpAwarded: Int
    let newTotalXp: Int
    let levelUp: Bool?
    let newLevel: Int?

    enum CodingKeys: String, CodingKey {
        case success, challenge
        case xpAwarded = "xp_awarded"
        case newTotalXp = "new_total_xp"
        case levelUp = "level_up"
        case newLevel = "new_level"
    }
}

// MARK: - Day Activity Model

struct DayActivity: Identifiable, Codable {
    var id: String { date.ISO8601Format() }
    let date: Date
    let hasActivity: Bool
    let xpEarned: Int
    let outfitsWorn: Int
    let itemsAdded: Int
    let challengesCompleted: Int

    enum CodingKeys: String, CodingKey {
        case date
        case hasActivity = "has_activity"
        case xpEarned = "xp_earned"
        case outfitsWorn = "outfits_worn"
        case itemsAdded = "items_added"
        case challengesCompleted = "challenges_completed"
    }
}

// MARK: - Weekly Challenge Model

struct WeeklyChallenge: Codable {
    let id: String
    let title: String
    let description: String
    let target: Int
    var progress: Int
    let xpReward: Int
    let endsAt: Date
    var completedAt: Date?

    var isCompleted: Bool { completedAt != nil }
    var isClaimable: Bool { progress >= target && completedAt == nil }
    var progressPercent: Double {
        guard target > 0 else { return 0 }
        return min(Double(progress) / Double(target), 1)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, target, progress
        case xpReward = "xp_reward"
        case endsAt = "ends_at"
        case completedAt = "completed_at"
    }
}

// MARK: - Extended Gamification Stats

struct GamificationStats: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let totalDaysActive: Int
    let streakFreezes: Int
    let xp: Int
    let level: Int
    let dailyXPEarned: Int?
    let dailyGoalXP: Int?
    let hasEngagedToday: Bool?
    let streakFrozenToday: Bool?
    let hoursUntilStreakLoss: Int?

    enum CodingKeys: String, CodingKey {
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case totalDaysActive = "total_days_active"
        case streakFreezes = "streak_freezes"
        case xp, level
        case dailyXPEarned = "daily_xp_earned"
        case dailyGoalXP = "daily_goal_xp"
        case hasEngagedToday = "has_engaged_today"
        case streakFrozenToday = "streak_frozen_today"
        case hoursUntilStreakLoss = "hours_until_streak_loss"
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let levelUp = Notification.Name("levelUp")
    static let dailyGoalComplete = Notification.Name("dailyGoalComplete")
    static let challengeReadyToClaim = Notification.Name("challengeReadyToClaim")
    static let allChallengesComplete = Notification.Name("allChallengesComplete")
    static let streakRestored = Notification.Name("streakRestored")
    static let streakAtRisk = Notification.Name("streakAtRisk")
    static let streakMilestoneReached = Notification.Name("streakMilestoneReached")
}
