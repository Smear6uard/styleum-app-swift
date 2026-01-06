import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        print("🔌 [SUPABASE] ========== INIT START ==========")
        print("🔌 [SUPABASE] Supabase URL: \(Config.supabaseURL)")
        print("🔌 [SUPABASE] Anon key exists: \(!Config.supabaseAnonKey.isEmpty)")
        print("🔌 [SUPABASE] Anon key length: \(Config.supabaseAnonKey.count)")

        client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
        print("🔌 [SUPABASE] ✅ Client created successfully")
        print("🔌 [SUPABASE] ========== INIT END ==========")
    }

    var currentUserId: String? {
        let userId = client.auth.currentUser?.id.uuidString
        print("🔌 [SUPABASE] currentUserId accessed: \(userId ?? "nil")")
        return userId
    }

    var isAuthenticated: Bool {
        let isAuth = client.auth.currentUser != nil
        print("🔌 [SUPABASE] isAuthenticated accessed: \(isAuth)")
        return isAuth
    }
}

// MARK: - Database Tables
enum DBTable: String {
    case wardrobeItems = "wardrobe_items"
    case profiles = "user_profiles"
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
