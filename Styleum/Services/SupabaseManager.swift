import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey
        )
    }

    var currentUserId: String? {
        client.auth.currentUser?.id.uuidString
    }

    var isAuthenticated: Bool {
        client.auth.currentUser != nil
    }
}

// MARK: - Database Tables
enum DBTable: String {
    case wardrobeItems = "wardrobe_items"
    case profiles = "profiles"
    case achievementDefinitions = "achievement_definitions"
    case userAchievements = "user_achievements"
    case userStats = "user_stats"
    case userStyleVectors = "user_style_vectors"
    case vibeCentroids = "vibe_centroids"
    case dailyQueue = "daily_queue"
    case dailyLog = "daily_log"
    case savedOutfits = "saved_outfits"
    case outfitSuggestions = "outfit_suggestions"
    case userStreaks = "user_streaks"
}


// MARK: - Storage Buckets
enum StorageBucket: String {
    case wardrobe = "wardrobe"
    case profiles = "profiles"
    case outfits = "outfits"
}
