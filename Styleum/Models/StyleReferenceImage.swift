import Foundation

/// Style reference image for onboarding swipes
struct StyleReferenceImage: Codable, Identifiable {
    let id: String
    let imageUrl: String
    let styleTags: [String]
    let vibe: String

    enum CodingKeys: String, CodingKey {
        case id
        case imageUrl = "image_url"
        case styleTags = "style_tags"
        case vibe
    }
}

/// API response wrapper for style images
struct StyleImagesResponse: Codable {
    let images: [StyleReferenceImage]
}

/// Request body for completing onboarding
struct CompleteOnboardingRequest: Encodable {
    let firstName: String
    let departments: [String]
    let likedStyleIds: [String]
    let dislikedStyleIds: [String]
    let favoriteBrands: [String]
    let bodyShape: String?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case departments
        case likedStyleIds = "liked_style_ids"
        case dislikedStyleIds = "disliked_style_ids"
        case favoriteBrands = "favorite_brands"
        case bodyShape = "body_shape"
    }
}
