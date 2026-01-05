import Foundation

struct AIAnalysisResult: Codable, Equatable {
    let denseCaption: String
    let ocrText: String?
    let era: EraAnalysis?
    let vibeScores: [String: Double]
    let isUnorthodox: Bool
    let unorthodoxDescription: String?
    let tags: [String]
    let styleBucket: String?
    let formality: String?
    let seasonality: String?
    let analyzedAt: Date?

    enum CodingKeys: String, CodingKey {
        case denseCaption = "dense_caption"
        case ocrText = "ocr_text"
        case era
        case vibeScores = "vibe_scores"
        case isUnorthodox = "is_unorthodox"
        case unorthodoxDescription = "unorthodox_description"
        case tags
        case styleBucket = "style_bucket"
        case formality
        case seasonality
        case analyzedAt = "analyzed_at"
    }
}

struct EraAnalysis: Codable, Equatable {
    let detected: String
    let confidence: Double
    let reasoning: String?

    var isVintage: Bool {
        detected != "modern" && confidence > 0.6
    }
}

struct UserStyleProfile: Codable, Equatable {
    let userId: String
    let styleVector: [Double]?
    let totalInteractions: Int
    let wearsCount: Int
    let likesCount: Int
    let rejectsCount: Int
    let editsCount: Int
    let dominantVibes: [String: Double]?
    let avoidedVibes: [String: Double]?
    let lastInteractionAt: Date?

    var hasLearnedPreferences: Bool { totalInteractions >= 10 }

    static func empty(userId: String) -> UserStyleProfile {
        UserStyleProfile(
            userId: userId,
            styleVector: nil,
            totalInteractions: 0,
            wearsCount: 0,
            likesCount: 0,
            rejectsCount: 0,
            editsCount: 0,
            dominantVibes: nil,
            avoidedVibes: nil,
            lastInteractionAt: nil
        )
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case styleVector = "style_vector"
        case totalInteractions = "total_interactions"
        case wearsCount = "wears_count"
        case likesCount = "likes_count"
        case rejectsCount = "rejects_count"
        case editsCount = "edits_count"
        case dominantVibes = "dominant_vibes"
        case avoidedVibes = "avoided_vibes"
        case lastInteractionAt = "last_interaction_at"
    }
}
