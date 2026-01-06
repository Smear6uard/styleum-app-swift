import Foundation
import Supabase

// MARK: - StyleumAPI
/// Central API client for all backend communication.
/// All data operations go through this client to the Hono API.
@Observable
final class StyleumAPI {
    static let shared = StyleumAPI()

    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        self.baseURL = Config.apiBaseURL + "/api"

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        // Note: Don't use .convertFromSnakeCase - WardrobeItem has explicit CodingKeys
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        // Note: Don't use .convertToSnakeCase - models have explicit CodingKeys
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Auth Token

    private func getAuthToken() async throws -> String {
        print("🌐 [API] Getting auth token...")
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            print("🌐 [API] ✅ Got auth token (length: \(session.accessToken.count) chars)")
            return session.accessToken
        } catch {
            print("🌐 [API] ❌ Failed to get auth token: \(error)")
            throw error
        }
    }

    // MARK: - Generic Request

    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        retryOnAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token
        let token = try await getAuthToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Add body if present
        if let body = body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Handle error status codes
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            // Try to refresh session once
            if retryOnAuth {
                do {
                    _ = try await SupabaseManager.shared.client.auth.refreshSession()
                    // Retry with new token
                    return try await self.request(
                        endpoint: endpoint,
                        method: method,
                        body: body,
                        retryOnAuth: false
                    )
                } catch {
                    print("Session refresh failed: \(error)")
                    throw APIError.unauthorized
                }
            }
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 429:
            throw APIError.rateLimited
        default:
            // Try to parse error message from response
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw APIError.serverError(message: errorResponse.error ?? "Unknown error")
            }
            throw APIError.serverError(message: "Server error: \(httpResponse.statusCode)")
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError(error)
        }
    }

    /// Request that returns no data (204 No Content or empty response)
    private func requestNoContent(
        endpoint: String,
        method: String,
        body: Encodable? = nil,
        retryOnAuth: Bool = true
    ) async throws {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let token = try await getAuthToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        if let body = body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            // Try to refresh session once
            if retryOnAuth {
                do {
                    _ = try await SupabaseManager.shared.client.auth.refreshSession()
                    // Retry with new token
                    try await self.requestNoContent(
                        endpoint: endpoint,
                        method: method,
                        body: body,
                        retryOnAuth: false
                    )
                    return
                } catch {
                    print("Session refresh failed: \(error)")
                    throw APIError.unauthorized
                }
            }
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 409:
            // Check if this is an onboarding already complete error
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data),
               errorResponse.code == "ONBOARDING_ALREADY_COMPLETE" {
                throw APIError.onboardingAlreadyComplete(version: errorResponse.onboardingVersion)
            }
            throw APIError.serverError(message: "Conflict")
        case 429:
            throw APIError.rateLimited
        default:
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw APIError.serverError(message: errorResponse.error ?? "Unknown error")
            }
            throw APIError.serverError(message: "Server error: \(httpResponse.statusCode)")
        }
    }

    // MARK: - Items

    // Response wrappers for API responses
    private struct ItemResponse: Decodable {
        let item: WardrobeItem
    }

    private struct ItemsResponse: Decodable {
        let items: [WardrobeItem]
    }

    func fetchWardrobe() async throws -> [WardrobeItem] {
        let response: ItemsResponse = try await request(endpoint: "/items")
        return response.items
    }

    func getItem(id: String) async throws -> WardrobeItem {
        let response: ItemResponse = try await request(endpoint: "/items/\(id)")
        return response.item
    }

    func uploadItem(imageUrl: String, category: String? = nil, name: String? = nil) async throws -> WardrobeItem {
        struct UploadItemRequest: Encodable {
            let imageUrl: String
            let category: String?
            let itemName: String?

            enum CodingKeys: String, CodingKey {
                case imageUrl = "image_url"
                case category
                case itemName = "item_name"
            }
        }
        let response: ItemResponse = try await request(
            endpoint: "/items",
            method: "POST",
            body: UploadItemRequest(imageUrl: imageUrl, category: category, itemName: name)
        )
        return response.item
    }

    func uploadItemsBatch(imageUrls: [String]) async throws -> [WardrobeItem] {
        struct BatchUploadRequest: Encodable {
            let imageUrls: [String]
        }
        return try await request(
            endpoint: "/items/batch",
            method: "POST",
            body: BatchUploadRequest(imageUrls: imageUrls)
        )
    }

    func updateItem(id: String, updates: WardrobeItemUpdate) async throws -> WardrobeItem {
        try await request(
            endpoint: "/items/\(id)",
            method: "PUT",
            body: updates
        )
    }

    func deleteItem(id: String) async throws {
        try await requestNoContent(endpoint: "/items/\(id)", method: "DELETE")
    }

    func archiveItem(id: String) async throws {
        try await requestNoContent(endpoint: "/items/\(id)/archive", method: "POST")
    }

    func fetchWardrobeInsights() async throws -> WardrobeInsights {
        try await request(endpoint: "/items/insights")
    }

    func applyStudioMode(itemId: String) async throws -> StudioModeResult {
        try await request(endpoint: "/items/\(itemId)/studio-mode", method: "POST")
    }

    // MARK: - Outfits

    func getGeneratedOutfits() async throws -> [ScoredOutfit] {
        try await request(endpoint: "/outfits")
    }

    func generateOutfits(
        occasion: String?,
        mood: String?,
        boldnessLevel: Int = 3,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) async throws -> GenerateOutfitsResult {
        struct GenerateRequest: Encodable {
            let occasion: String?
            let mood: String?
            let boldnessLevel: Int
            let latitude: Double?
            let longitude: Double?
        }
        return try await request(
            endpoint: "/outfits/generate",
            method: "POST",
            body: GenerateRequest(
                occasion: occasion,
                mood: mood,
                boldnessLevel: boldnessLevel,
                latitude: latitude,
                longitude: longitude
            )
        )
    }

    func regenerateOutfit(currentIds: [String], feedback: String, occasion: String?) async throws -> RegenerateOutfitResult {
        struct RegenerateRequest: Encodable {
            let currentOutfitIds: [String]
            let feedback: String
            let occasion: String?
        }
        return try await request(
            endpoint: "/outfits/regenerate",
            method: "POST",
            body: RegenerateRequest(currentOutfitIds: currentIds, feedback: feedback, occasion: occasion)
        )
    }

    func wearOutfit(id: String, photoUrl: String?) async throws -> WearOutfitResponse {
        struct WearRequest: Encodable {
            let photoUrl: String?
        }
        return try await request(
            endpoint: "/outfits/\(id)/wear",
            method: "POST",
            body: WearRequest(photoUrl: photoUrl)
        )
    }

    func saveOutfit(outfit: ScoredOutfit) async throws {
        struct SaveRequest: Encodable {
            let wardrobeItemIds: [String]
            let score: Int
            let whyItWorks: String
            let stylingTip: String?
            let vibes: [String]
        }
        try await requestNoContent(
            endpoint: "/outfits/save",
            method: "POST",
            body: SaveRequest(
                wardrobeItemIds: outfit.wardrobeItemIds,
                score: outfit.score,
                whyItWorks: outfit.whyItWorks,
                stylingTip: outfit.stylingTip,
                vibes: outfit.vibes
            )
        )
    }

    func getOutfitHistory() async throws -> [OutfitHistory] {
        try await request(endpoint: "/outfits/history")
    }

    // MARK: - Profile

    func getProfile() async throws -> Profile {
        print("🌐 [API] ========== GET PROFILE START ==========")
        print("🌐 [API] Endpoint: /profile")
        do {
            let profile: Profile = try await request(endpoint: "/profile")
            print("🌐 [API] ✅ Profile received successfully")
            print("🌐 [API] Profile ID: \(profile.id)")
            print("🌐 [API] Profile firstName: \(profile.firstName ?? "nil")")
            print("🌐 [API] Profile email: \(profile.email ?? "nil")")
            print("🌐 [API] Profile onboardingVersion: \(profile.onboardingVersion.map { String($0) } ?? "nil")")
            print("🌐 [API] Profile styleQuizCompleted: \(profile.styleQuizCompleted.map { String($0) } ?? "nil")")
            print("🌐 [API] Profile departments: \(profile.departments ?? [])")
            print("🌐 [API] ========== GET PROFILE END ==========")
            return profile
        } catch {
            print("🌐 [API] ❌ Get profile failed: \(error)")
            print("🌐 [API] Error type: \(type(of: error))")
            print("🌐 [API] ========== GET PROFILE END (ERROR) ==========")
            throw error
        }
    }

    func updateProfile(_ updates: ProfileUpdate) async throws -> Profile {
        print("🌐 [API] ========== UPDATE PROFILE START ==========")
        print("🌐 [API] Endpoint: /profile (PUT)")
        print("🌐 [API] Updates: \(updates)")
        do {
            let profile: Profile = try await request(endpoint: "/profile", method: "PUT", body: updates)
            print("🌐 [API] ✅ Profile updated successfully")
            print("🌐 [API] Updated profile ID: \(profile.id)")
            print("🌐 [API] Updated onboardingVersion: \(profile.onboardingVersion.map { String($0) } ?? "nil")")
            print("🌐 [API] ========== UPDATE PROFILE END ==========")
            return profile
        } catch {
            print("🌐 [API] ❌ Update profile failed: \(error)")
            print("🌐 [API] ========== UPDATE PROFILE END (ERROR) ==========")
            throw error
        }
    }

    // MARK: - Gamification

    func getGamificationStats() async throws -> GamificationStats {
        try await request(endpoint: "/gamification/stats")
    }

    func getAchievements() async throws -> [Achievement] {
        try await request(endpoint: "/achievements")
    }

    func markAchievementSeen(id: String) async throws {
        try await requestNoContent(endpoint: "/achievements/\(id)/seen", method: "POST")
    }

    func useStreakFreeze() async throws -> GamificationStats {
        try await request(endpoint: "/gamification/streak-freeze", method: "POST")
    }

    func restoreStreak() async throws -> GamificationStats {
        try await request(endpoint: "/gamification/restore-streak", method: "POST")
    }

    // MARK: - Subscription

    func getSubscriptionStatus() async throws -> SubscriptionStatus {
        try await request(endpoint: "/subscriptions/status")
    }

    func getLimits() async throws -> UsageLimits {
        try await request(endpoint: "/subscriptions/limits")
    }

    // MARK: - Onboarding

    /// Get style reference images for onboarding swipes
    func getOnboardingStyleImages(department: String) async throws -> StyleImagesResponse {
        try await request(endpoint: "/onboarding/style-images?department=\(department)")
    }

    /// Complete onboarding with all collected data
    func completeOnboarding(
        firstName: String,
        departments: Set<String>,
        likedStyleIds: [String],
        dislikedStyleIds: [String],
        favoriteBrands: Set<String>,
        bodyShape: String?
    ) async throws {
        print("🌐 [API] ========== COMPLETE ONBOARDING START ==========")
        print("🌐 [API] Endpoint: /onboarding/complete (POST)")
        print("🌐 [API] firstName: \(firstName)")
        print("🌐 [API] departments: \(departments)")
        print("🌐 [API] likedStyleIds count: \(likedStyleIds.count)")
        print("🌐 [API] dislikedStyleIds count: \(dislikedStyleIds.count)")
        print("🌐 [API] favoriteBrands: \(favoriteBrands)")
        print("🌐 [API] bodyShape: \(bodyShape ?? "nil")")

        let body = CompleteOnboardingRequest(
            firstName: firstName,
            departments: Array(departments),
            likedStyleIds: likedStyleIds,
            dislikedStyleIds: dislikedStyleIds,
            favoriteBrands: Array(favoriteBrands),
            bodyShape: bodyShape
        )

        do {
            try await requestNoContent(
                endpoint: "/onboarding/complete",
                method: "POST",
                body: body
            )
            print("🌐 [API] ✅ Onboarding completed successfully")
            print("🌐 [API] ========== COMPLETE ONBOARDING END ==========")
        } catch {
            print("🌐 [API] ❌ Complete onboarding failed: \(error)")
            print("🌐 [API] Error type: \(type(of: error))")
            print("🌐 [API] ========== COMPLETE ONBOARDING END (ERROR) ==========")
            throw error
        }
    }

    /// Submit style quiz results (for users who skipped during onboarding)
    func submitStyleQuiz(
        likedStyleIds: [String],
        dislikedStyleIds: [String]
    ) async throws {
        print("🌐 [API] ========== SUBMIT STYLE QUIZ START ==========")
        print("🌐 [API] Endpoint: /style-quiz/submit (POST)")
        print("🌐 [API] likedStyleIds count: \(likedStyleIds.count)")
        print("🌐 [API] dislikedStyleIds count: \(dislikedStyleIds.count)")

        struct SubmitStyleQuizRequest: Encodable {
            let likedStyleIds: [String]
            let dislikedStyleIds: [String]
        }

        let body = SubmitStyleQuizRequest(
            likedStyleIds: likedStyleIds,
            dislikedStyleIds: dislikedStyleIds
        )

        do {
            try await requestNoContent(
                endpoint: "/style-quiz/submit",
                method: "POST",
                body: body
            )
            print("🌐 [API] ✅ Style quiz submitted successfully")
            print("🌐 [API] ========== SUBMIT STYLE QUIZ END ==========")
        } catch {
            print("🌐 [API] ❌ Submit style quiz failed: \(error)")
            print("🌐 [API] Error type: \(type(of: error))")
            print("🌐 [API] ========== SUBMIT STYLE QUIZ END (ERROR) ==========")
            throw error
        }
    }
}

// MARK: - API Error

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case onboardingAlreadyComplete(version: Int?)
    case serverError(message: String)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Please sign in again"
        case .forbidden:
            return "Access denied"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Too many requests. Please wait."
        case .onboardingAlreadyComplete:
            return "Onboarding already completed"
        case .serverError(let message):
            return message
        case .decodingError:
            return "Failed to process response"
        }
    }
}

// MARK: - API Response Models

struct APIErrorResponse: Decodable {
    let error: String?
    let message: String?
    let code: String?
    let onboardingVersion: Int?
}

struct GamificationStats: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let totalDaysActive: Int
    let streakFreezes: Int
    let xp: Int
    let level: Int

    // Provide defaults for optional fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        longestStreak = try container.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 0
        totalDaysActive = try container.decodeIfPresent(Int.self, forKey: .totalDaysActive) ?? 0
        streakFreezes = try container.decodeIfPresent(Int.self, forKey: .streakFreezes) ?? 0
        xp = try container.decodeIfPresent(Int.self, forKey: .xp) ?? 0
        level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 1
    }
}

struct WearOutfitResponse: Decodable {
    let success: Bool
    let streakUpdate: StreakUpdateInfo?
    let newAchievements: [UnlockedAchievement]?
}

struct StreakUpdateInfo: Decodable {
    let currentStreak: Int
    let longestStreak: Int
    let streakIncreased: Bool
    let streakReset: Bool
}

struct SubscriptionStatus: Decodable {
    let tier: String
    let expiresAt: Date?
    let features: [String]

    enum CodingKeys: String, CodingKey {
        case tier
        case expiresAt = "expires_at"
        case features
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tier = try container.decodeIfPresent(String.self, forKey: .tier) ?? "free"
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        features = try container.decodeIfPresent([String].self, forKey: .features) ?? []
    }
}

struct UsageLimits: Decodable {
    let creditsRemaining: Int
    let creditsTotal: Int
    let creditsResetsAt: Date?
    let itemsLimit: Int
    let itemsUsed: Int

    /// Computed property for display
    var creditsUsed: Int {
        creditsTotal - creditsRemaining
    }

    enum CodingKeys: String, CodingKey {
        case credits
        case itemsLimit = "items_limit"
        case itemsUsed = "items_used"
    }

    enum CreditsKeys: String, CodingKey {
        case remaining
        case total
        case resetsAt = "resets_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Parse nested credits object
        if let creditsContainer = try? container.nestedContainer(keyedBy: CreditsKeys.self, forKey: .credits) {
            creditsRemaining = try creditsContainer.decodeIfPresent(Int.self, forKey: .remaining) ?? 5
            creditsTotal = try creditsContainer.decodeIfPresent(Int.self, forKey: .total) ?? 5
            creditsResetsAt = try creditsContainer.decodeIfPresent(Date.self, forKey: .resetsAt)
        } else {
            // Fallback defaults (free tier)
            creditsRemaining = 5
            creditsTotal = 5
            creditsResetsAt = nil
        }

        itemsLimit = try container.decodeIfPresent(Int.self, forKey: .itemsLimit) ?? 50
        itemsUsed = try container.decodeIfPresent(Int.self, forKey: .itemsUsed) ?? 0
    }

    // Memberwise initializer for previews
    init(creditsRemaining: Int = 5, creditsTotal: Int = 5, creditsResetsAt: Date? = nil, itemsLimit: Int = 50, itemsUsed: Int = 0) {
        self.creditsRemaining = creditsRemaining
        self.creditsTotal = creditsTotal
        self.creditsResetsAt = creditsResetsAt
        self.itemsLimit = itemsLimit
        self.itemsUsed = itemsUsed
    }
}

struct OutfitHistory: Decodable, Identifiable {
    let id: String
    let outfitId: String
    let wornAt: Date
    let photoUrl: String?
}

struct GenerateOutfitsResult: Decodable {
    let outfits: [ScoredOutfit]
    let weather: WeatherContext?
}

struct RegenerateOutfitResult: Decodable {
    let success: Bool
    let outfit: ScoredOutfit?
    let error: String?
}

struct StudioModeResult: Decodable {
    let success: Bool
    let photoUrlClean: String?
    let error: String?
}

// MARK: - AnyEncodable Helper

struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T) {
        encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}
