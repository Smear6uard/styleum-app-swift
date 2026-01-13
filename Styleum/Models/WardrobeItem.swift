import Foundation

struct WardrobeItem: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let userId: String
    var photoUrl: String?
    var thumbnailUrl: String?
    var category: ClothingCategory?
    var subcategory: String?
    var itemName: String?
    var styleBucket: String?
    var styleVibes: [String]?
    var primaryColor: String?
    var secondaryColors: [String]?
    var colorHex: String?
    var material: String?
    var fabricType: String?
    var fit: String?
    var formality: Int?
    var seasonality: String?
    var seasons: [String]?
    var occasions: [String]?
    var occasion: String?
    var brand: String?
    var size: String?
    var condition: String?
    var price: Double?
    var cost: Double?
    var purchaseDate: Date?
    var timesWorn: Int
    var wearCount: Int?
    var lastWorn: Date?
    var lastWornAt: Date?
    var tags: [String]?
    var customTags: [String]?
    var denseCaption: String?
    var ocrText: String?
    var vibeScores: [String: Double]?
    var eraDetected: String?
    var eraConfidence: Double?
    var isUnorthodox: Bool?
    var unorthodoxDescription: String?
    var notableDetails: String?
    var constructionNotes: String?
    var qualitySignals: [String]?
    var notes: String?
    var isFavorite: Bool?
    var userVerified: Bool?
    var feedbackLog: [[String: String]]?
    var aiMetadata: [String: String]?
    var embedding: [Double]?
    var photoUrlClean: String?
    var studioModeAt: Date?
    var styleDescription: String?
    let createdAt: Date?
    var updatedAt: Date?

    var hasAnalysis: Bool {
        denseCaption != nil || styleBucket != nil
    }

    var displayPhotoUrl: String? {
        // Priority: processed (studio mode) > thumbnail > original
        photoUrlClean ?? thumbnailUrl ?? photoUrl
    }

    var hasStudioMode: Bool {
        photoUrlClean != nil
    }

    /// Item is processing until background-removed image is available
    var isProcessing: Bool {
        photoUrlClean == nil
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case photoUrl = "original_image_url"
        case thumbnailUrl = "thumbnail_url"
        case category
        case subcategory
        case itemName = "item_name"
        case styleBucket = "style_bucket"
        case styleVibes = "style_vibes"
        case primaryColor = "primary_color"
        case secondaryColors = "secondary_colors"
        case colorHex = "color_hex"
        case material
        case fabricType = "fabric_type"
        case fit
        case formality
        case seasonality
        case seasons
        case occasions
        case occasion
        case brand
        case size
        case condition
        case price
        case cost
        case purchaseDate = "purchase_date"
        case timesWorn = "times_worn"
        case wearCount = "wear_count"
        case lastWorn = "last_worn"
        case lastWornAt = "last_worn_at"
        case tags
        case customTags = "custom_tags"
        case denseCaption = "dense_caption"
        case ocrText = "ocr_text"
        case vibeScores = "vibe_scores"
        case eraDetected = "era"
        case eraConfidence = "era_confidence"
        case isUnorthodox = "is_unorthodox"
        case unorthodoxDescription = "unorthodox_description"
        case notableDetails = "notable_details"
        case constructionNotes = "construction_notes"
        case qualitySignals = "quality_signals"
        case notes
        case isFavorite = "is_favorite"
        case userVerified = "user_verified"
        case feedbackLog = "feedback_log"
        case aiMetadata = "ai_metadata"
        case embedding
        case photoUrlClean = "processed_image_url"
        case studioModeAt = "studio_mode_at"
        case styleDescription = "style_description"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        photoUrl = try container.decodeIfPresent(String.self, forKey: .photoUrl)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        category = try container.decodeIfPresent(ClothingCategory.self, forKey: .category)
        subcategory = try container.decodeIfPresent(String.self, forKey: .subcategory)
        itemName = try container.decodeIfPresent(String.self, forKey: .itemName)
        styleBucket = try container.decodeIfPresent(String.self, forKey: .styleBucket)
        styleVibes = try container.decodeIfPresent([String].self, forKey: .styleVibes)
        primaryColor = try container.decodeIfPresent(String.self, forKey: .primaryColor)
        secondaryColors = try container.decodeIfPresent([String].self, forKey: .secondaryColors)
        colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex)
        material = try container.decodeIfPresent(String.self, forKey: .material)
        fabricType = try container.decodeIfPresent(String.self, forKey: .fabricType)
        fit = try container.decodeIfPresent(String.self, forKey: .fit)
        formality = try container.decodeIfPresent(Int.self, forKey: .formality)
        seasonality = try container.decodeIfPresent(String.self, forKey: .seasonality)
        seasons = try container.decodeIfPresent([String].self, forKey: .seasons)
        occasions = try container.decodeIfPresent([String].self, forKey: .occasions)
        occasion = try container.decodeIfPresent(String.self, forKey: .occasion)
        brand = try container.decodeIfPresent(String.self, forKey: .brand)
        size = try container.decodeIfPresent(String.self, forKey: .size)
        condition = try container.decodeIfPresent(String.self, forKey: .condition)
        price = try container.decodeIfPresent(Double.self, forKey: .price)
        cost = try container.decodeIfPresent(Double.self, forKey: .cost)
        purchaseDate = try container.decodeIfPresent(Date.self, forKey: .purchaseDate)
        timesWorn = try container.decodeIfPresent(Int.self, forKey: .timesWorn) ?? 0
        wearCount = try container.decodeIfPresent(Int.self, forKey: .wearCount)
        lastWorn = try container.decodeIfPresent(Date.self, forKey: .lastWorn)
        lastWornAt = try container.decodeIfPresent(Date.self, forKey: .lastWornAt)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        customTags = try container.decodeIfPresent([String].self, forKey: .customTags)
        denseCaption = try container.decodeIfPresent(String.self, forKey: .denseCaption)
        ocrText = try container.decodeIfPresent(String.self, forKey: .ocrText)
        vibeScores = try container.decodeIfPresent([String: Double].self, forKey: .vibeScores)
        eraDetected = try container.decodeIfPresent(String.self, forKey: .eraDetected)
        eraConfidence = try container.decodeIfPresent(Double.self, forKey: .eraConfidence)
        isUnorthodox = try container.decodeIfPresent(Bool.self, forKey: .isUnorthodox)
        unorthodoxDescription = try container.decodeIfPresent(String.self, forKey: .unorthodoxDescription)
        notableDetails = try container.decodeIfPresent(String.self, forKey: .notableDetails)
        constructionNotes = try container.decodeIfPresent(String.self, forKey: .constructionNotes)
        qualitySignals = try container.decodeIfPresent([String].self, forKey: .qualitySignals)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite)
        userVerified = try container.decodeIfPresent(Bool.self, forKey: .userVerified)
        feedbackLog = try container.decodeIfPresent([[String: String]].self, forKey: .feedbackLog)
        aiMetadata = try container.decodeIfPresent([String: String].self, forKey: .aiMetadata)
        // Skip embedding - it's a pgvector string from Supabase, only used server-side
        embedding = nil
        photoUrlClean = try container.decodeIfPresent(String.self, forKey: .photoUrlClean)
        studioModeAt = try container.decodeIfPresent(Date.self, forKey: .studioModeAt)
        styleDescription = try container.decodeIfPresent(String.self, forKey: .styleDescription)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    // MARK: - Equatable
    static func == (lhs: WardrobeItem, rhs: WardrobeItem) -> Bool {
        lhs.id == rhs.id && lhs.updatedAt == rhs.updatedAt
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
