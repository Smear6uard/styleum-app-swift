import Foundation

struct OutfitCandidate: Identifiable, Equatable {
    var id: String { "\(top.id)_\(bottom.id)_\(shoes.id)" }
    let top: WardrobeItem
    let bottom: WardrobeItem
    let shoes: WardrobeItem
    let outerwear: WardrobeItem?
    let accessory: WardrobeItem?
    var ruleScore: Int

    var allItems: [WardrobeItem] {
        var items = [top, bottom, shoes]
        if let outerwear = outerwear { items.append(outerwear) }
        if let accessory = accessory { items.append(accessory) }
        return items
    }
}

struct ScoredOutfit: Identifiable, Codable, Equatable {
    let id: String
    let wardrobeItemIds: [String]
    let score: Int
    let whyItWorks: String
    let stylingTip: String?
    let vibes: [String]
    let occasion: String?
    let createdAt: Date?
    // New v2 fields
    let headline: String?
    let colorHarmony: String?
    let vibe: String?
    let changesMade: String?
    let items: [OutfitItemRole]?

    enum CodingKeys: String, CodingKey {
        case id
        case wardrobeItemIds = "wardrobeItemIds"
        case score
        case whyItWorks = "whyItWorks"
        case stylingTip = "stylingTip"
        case vibes
        case occasion
        case createdAt = "created_at"
        case headline
        case colorHarmony = "colorHarmony"
        case vibe
        case changesMade = "changesMade"
        case items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle id - generate if not present
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.wardrobeItemIds = try container.decode([String].self, forKey: .wardrobeItemIds)

        // Handle score - can be Int or Double
        if let intScore = try? container.decode(Int.self, forKey: .score) {
            self.score = intScore
        } else if let doubleScore = try? container.decode(Double.self, forKey: .score) {
            self.score = Int(doubleScore)
        } else {
            self.score = 0
        }

        // Try both key names for backwards compatibility
        if let explanation = try? container.decode(String.self, forKey: .whyItWorks) {
            self.whyItWorks = explanation
        } else {
            self.whyItWorks = ""
        }

        self.stylingTip = try container.decodeIfPresent(String.self, forKey: .stylingTip)
        self.vibes = try container.decodeIfPresent([String].self, forKey: .vibes) ?? []
        self.occasion = try container.decodeIfPresent(String.self, forKey: .occasion)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.headline = try container.decodeIfPresent(String.self, forKey: .headline)
        self.colorHarmony = try container.decodeIfPresent(String.self, forKey: .colorHarmony)
        self.vibe = try container.decodeIfPresent(String.self, forKey: .vibe)
        self.changesMade = try container.decodeIfPresent(String.self, forKey: .changesMade)
        self.items = try container.decodeIfPresent([OutfitItemRole].self, forKey: .items)
    }

    // Memberwise initializer for previews and testing
    init(
        id: String,
        wardrobeItemIds: [String],
        score: Int,
        whyItWorks: String,
        stylingTip: String? = nil,
        vibes: [String] = [],
        occasion: String? = nil,
        createdAt: Date? = nil,
        headline: String? = nil,
        colorHarmony: String? = nil,
        vibe: String? = nil,
        changesMade: String? = nil,
        items: [OutfitItemRole]? = nil
    ) {
        self.id = id
        self.wardrobeItemIds = wardrobeItemIds
        self.score = score
        self.whyItWorks = whyItWorks
        self.stylingTip = stylingTip
        self.vibes = vibes
        self.occasion = occasion
        self.createdAt = createdAt
        self.headline = headline
        self.colorHarmony = colorHarmony
        self.vibe = vibe
        self.changesMade = changesMade
        self.items = items
    }
}

struct OutfitItemRole: Codable, Equatable, Identifiable {
    let id: String
    let role: String // "top", "bottom", "footwear", "outerwear", "accessory"
    let imageUrl: String?
    let category: String?
    let subcategory: String?
    let itemName: String?
    let colors: ItemColors?

    enum CodingKeys: String, CodingKey {
        case id, role, category, subcategory, colors
        case imageUrl = "imageUrl"
        case itemName = "itemName"
    }
}

struct ItemColors: Codable, Equatable {
    let primary: String?
    let secondary: [String]?
    let hex: String?
}

// MARK: - Feedback Type for Regeneration
enum FeedbackType: String, CaseIterable {
    case moreCasual = "more_casual"
    case moreFormal = "more_formal"
    case moreBold = "more_bold"
    case moreClassic = "more_classic"
    case differentColors = "different_colors"
    case differentVibe = "different_vibe"

    var displayName: String {
        switch self {
        case .moreCasual: return "More casual"
        case .moreFormal: return "More formal"
        case .moreBold: return "More bold"
        case .moreClassic: return "More classic"
        case .differentColors: return "Different colors"
        case .differentVibe: return "Different vibe"
        }
    }

    var iconName: String {
        switch self {
        case .moreCasual: return "arrow.down"
        case .moreFormal: return "arrow.up"
        case .moreBold: return "sparkles"
        case .moreClassic: return "clock"
        case .differentColors: return "paintpalette"
        case .differentVibe: return "wand.and.stars"
        }
    }
}

struct WeatherContext: Codable, Equatable {
    let tempFahrenheit: Double
    let condition: String
    let humidity: Double?
    let windMph: Double?
    let description: String?

    var isCold: Bool { tempFahrenheit < 50 }
    var isWarm: Bool { tempFahrenheit >= 75 }
    var needsJacket: Bool { isCold || condition.lowercased().contains("rain") }

    var weatherSymbol: String {
        let cond = condition.lowercased()
        if cond.contains("rain") { return "cloud.rain.fill" }
        if cond.contains("cloud") { return "cloud.fill" }
        if cond.contains("snow") { return "snowflake" }
        if cond.contains("wind") { return "wind" }
        return "sun.max.fill"
    }

    enum CodingKeys: String, CodingKey {
        case tempFahrenheit = "temp_fahrenheit"
        case condition
        case humidity
        case windMph = "wind_mph"
        case description
    }
}

struct StylePreferences: Codable, Equatable {
    var styleGoal: String?
    var avoidColors: [String]?
    var preferredStyles: [StyleBucket]?
    var boldnessLevel: Int
    var occasion: String?
    var timeOfDay: String?

    init(
        styleGoal: String? = nil,
        avoidColors: [String]? = nil,
        preferredStyles: [StyleBucket]? = nil,
        boldnessLevel: Int = 3,
        occasion: String? = nil,
        timeOfDay: String? = nil
    ) {
        self.styleGoal = styleGoal
        self.avoidColors = avoidColors
        self.preferredStyles = preferredStyles
        self.boldnessLevel = boldnessLevel
        self.occasion = occasion
        self.timeOfDay = timeOfDay
    }

    enum CodingKeys: String, CodingKey {
        case styleGoal = "style_goal"
        case avoidColors = "avoid_colors"
        case preferredStyles = "preferred_styles"
        case boldnessLevel = "boldness_level"
        case occasion
        case timeOfDay = "time_of_day"
    }
}
