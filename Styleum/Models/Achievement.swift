import SwiftUI

// MARK: - API Response Wrapper

struct AchievementsResponse: Codable {
    let achievements: [Achievement]
}

// MARK: - Achievement Model

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
    let isUnlocked: Bool
    var seenAt: Date?
    let sortOrder: Int

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
        case title = "name"
        case description
        case category
        case rarity
        case currentProgress = "progress"
        case targetProgress = "target"
        case iconName = "icon_name"
        case xpReward = "xp_reward"
        case isUnlocked = "is_unlocked"
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
        isUnlocked: Bool,
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
        self.isUnlocked = isUnlocked
        self.seenAt = seenAt
        self.sortOrder = sortOrder
    }

    // Custom decoder with defaults for fields not in backend response
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decode(AchievementCategory.self, forKey: .category)
        rarity = try container.decodeIfPresent(AchievementRarity.self, forKey: .rarity) ?? .common
        currentProgress = try container.decodeIfPresent(Int.self, forKey: .currentProgress) ?? 0
        targetProgress = try container.decodeIfPresent(Int.self, forKey: .targetProgress) ?? 1
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName) ?? "star.fill"
        xpReward = try container.decodeIfPresent(Int.self, forKey: .xpReward) ?? 0
        isUnlocked = try container.decodeIfPresent(Bool.self, forKey: .isUnlocked) ?? false
        seenAt = try container.decodeIfPresent(Date.self, forKey: .seenAt)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
    }
}

// MARK: - Achievement Update Response

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
