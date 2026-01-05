import SwiftUI

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let category: AchievementCategory
    let rarity: AchievementRarity
    var currentProgress: Int
    let targetProgress: Int
    let iconName: String
    let xpReward: Int
    var unlockedAt: Date?
    var seenAt: Date?
    let sortOrder: Int

    var isUnlocked: Bool { unlockedAt != nil }
    var isNew: Bool { isUnlocked && seenAt == nil }

    var progressPercent: Double {
        guard targetProgress > 0 else { return 0 }
        return min(max(Double(currentProgress) / Double(targetProgress), 0), 1)
    }

    var rarityColor: Color {
        rarity.color
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case category
        case rarity
        case currentProgress = "current_progress"
        case targetProgress = "target_progress"
        case iconName = "icon_name"
        case xpReward = "xp_reward"
        case unlockedAt = "unlocked_at"
        case seenAt = "seen_at"
        case sortOrder = "sort_order"
    }

    // Memberwise init for manual construction
    init(
        id: String,
        title: String,
        description: String,
        category: AchievementCategory,
        rarity: AchievementRarity,
        currentProgress: Int,
        targetProgress: Int,
        iconName: String,
        xpReward: Int,
        unlockedAt: Date?,
        seenAt: Date?,
        sortOrder: Int
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.rarity = rarity
        self.currentProgress = currentProgress
        self.targetProgress = targetProgress
        self.iconName = iconName
        self.xpReward = xpReward
        self.unlockedAt = unlockedAt
        self.seenAt = seenAt
        self.sortOrder = sortOrder
    }

    // Custom decoder to handle joined query from achievement_definitions + user_achievements
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decode(AchievementCategory.self, forKey: .category)
        rarity = try container.decode(AchievementRarity.self, forKey: .rarity)
        targetProgress = try container.decode(Int.self, forKey: .targetProgress)
        iconName = try container.decode(String.self, forKey: .iconName)
        xpReward = try container.decodeIfPresent(Int.self, forKey: .xpReward) ?? 0
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0

        // These come from user_achievements join and may be nil
        currentProgress = try container.decodeIfPresent(Int.self, forKey: .currentProgress) ?? 0
        unlockedAt = try container.decodeIfPresent(Date.self, forKey: .unlockedAt)
        seenAt = try container.decodeIfPresent(Date.self, forKey: .seenAt)
    }
}

// Response from update-achievements edge function
struct AchievementUpdateResponse: Codable {
    let success: Bool
    let newlyUnlocked: [UnlockedAchievement]?

    enum CodingKeys: String, CodingKey {
        case success
        case newlyUnlocked = "newly_unlocked"
    }
}

struct UnlockedAchievement: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let rarity: String
    let iconName: String
    let xpReward: Int

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case rarity
        case iconName = "icon_name"
        case xpReward = "xp_reward"
    }
}
