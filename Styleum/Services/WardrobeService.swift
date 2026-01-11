import Foundation
import Supabase
import SwiftUI

#if os(iOS)
import UIKit
#endif

@MainActor
@Observable
final class WardrobeService {
    static let shared = WardrobeService()

    private let supabase = SupabaseManager.shared.client
    private let api = StyleumAPI.shared

    var items: [WardrobeItem] = []
    var isLoading = false
    var error: Error?

    var itemCount: Int { items.count }

    private init() {}

    // MARK: - Fetch All Items

    func fetchItems() async {
        guard SupabaseManager.shared.currentUserId != nil else {
            print("No user ID for fetching items")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            items = try await api.fetchWardrobe()
            print("Fetched \(items.count) wardrobe items")
        } catch {
            self.error = error
            print("Fetch wardrobe error: \(error)")
        }
    }

    // MARK: - Fetch by Category

    func fetchItems(category: ClothingCategory) async -> [WardrobeItem] {
        // Filter from local items (API returns all items)
        return items.filter { $0.category == category }
    }

    // MARK: - Get Single Item

    func getItem(id: String) async -> WardrobeItem? {
        // First check local cache
        if let item = items.first(where: { $0.id == id }) {
            return item
        }

        // Fetch from API if not in cache
        do {
            return try await api.getItem(id: id)
        } catch {
            print("Get item error: \(error)")
            return nil
        }
    }

    // MARK: - Add Item

    #if os(iOS)
    func addItem(image: UIImage, category: ClothingCategory, name: String? = nil) async throws -> WardrobeItem {
        guard let userId = SupabaseManager.shared.currentUserId else {
            throw WardrobeError.notAuthenticated
        }

        // Content moderation check FIRST (before any upload)
        let isSafe = try await ContentModerationService.shared.isSafeForUpload(image)
        guard isSafe else {
            throw ContentModerationError.flaggedContent
        }

        isLoading = true
        defer { isLoading = false }

        // 1. Resize and compress image for upload
        let maxDimension: CGFloat = 1200
        let resizedImage = resizeImage(image, maxDimension: maxDimension)

        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            throw WardrobeError.imageProcessingFailed
        }

        let fileName = "\(userId)/\(UUID().uuidString).jpg"
        print("Uploading image: \(fileName) (\(imageData.count / 1024)KB)")

        // 2. Upload to Supabase Storage (KEEP - direct storage upload)
        try await supabase.storage
            .from(StorageBucket.wardrobe.rawValue)
            .upload(fileName, data: imageData, options: .init(contentType: "image/jpeg"))

        print("Image uploaded")

        // 3. Get public URL
        let publicURL = try supabase.storage
            .from(StorageBucket.wardrobe.rawValue)
            .getPublicURL(path: fileName)

        print("Public URL: \(publicURL.absoluteString)")

        // 4. Call API to create item (replaces DB insert + AI analysis trigger)
        let result = try await api.uploadItem(
            imageUrl: publicURL.absoluteString,
            category: category.rawValue,
            name: name
        )

        print("Item created with ID: \(result.item.id)")

        // 5. Add to local array with animation support
        let isFirstItem = items.isEmpty
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            items.insert(result.item, at: 0)
        }

        HapticManager.shared.success()

        // 6. Award gamification XP and update challenge progress
        GamificationService.shared.awardXP(5, reason: .itemAdded)
        GamificationService.shared.updateChallengeProgress(for: .addItem)

        // 7. First item celebration
        if isFirstItem {
            NotificationCenter.default.post(name: .firstWardrobeItem, object: nil)
        }

        // 8. Referral completion celebration (when referred friend adds first item)
        if result.referralCompleted {
            let daysEarned = result.referralDaysEarned ?? 7
            print("📨 [Referral] Referral completed! Earned \(daysEarned) days")
            NotificationCenter.default.post(
                name: .referralCompleted,
                object: nil,
                userInfo: ["daysEarned": daysEarned]
            )
        }

        // Bug Fix: Refresh achievements to update "Add wardrobe item" progress
        // Backend recalculates achievement progress based on actual item count
        Task {
            await AchievementsService.shared.fetchAchievements()
        }

        return result.item
    }

    // Helper to resize image
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }

        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    #endif

    // MARK: - Update Item

    func updateItem(id: String, updates: WardrobeItemUpdate) async throws {
        isLoading = true
        defer { isLoading = false }

        let updatedItem = try await api.updateItem(id: id, updates: updates)

        // Update local array
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index] = updatedItem
        }

        HapticManager.shared.light()
    }

    // MARK: - Delete Item

    func deleteItem(id: String) async throws {
        isLoading = true
        defer { isLoading = false }

        // Get item to find photo URL for storage cleanup
        if let item = items.first(where: { $0.id == id }),
           let photoUrl = item.photoUrl {
            // Extract file path from URL and delete from storage
            if let path = extractStoragePath(from: photoUrl) {
                _ = try? await supabase.storage
                    .from(StorageBucket.wardrobe.rawValue)
                    .remove(paths: [path])
            }
        }

        // Delete via API
        try await api.deleteItem(id: id)

        // Remove from local array
        items.removeAll { $0.id == id }

        HapticManager.shared.light()
    }

    // MARK: - Delete Multiple Items

    func deleteItems(ids: Set<String>) async throws {
        for id in ids {
            try await deleteItem(id: id)
        }
    }

    // MARK: - Clear Cache

    /// Clears all local wardrobe data (used on account deletion)
    func clearCache() {
        items = []
    }

    // MARK: - Mark as Worn

    func markAsWorn(id: String) async throws {
        guard let item = items.first(where: { $0.id == id }) else { return }

        let updates = WardrobeItemUpdate(
            timesWorn: item.timesWorn + 1,
            lastWorn: Date()
        )

        try await updateItem(id: id, updates: updates)
        HapticManager.shared.medium()
    }

    // MARK: - Toggle Favorite

    func toggleFavorite(id: String) async throws {
        guard let item = items.first(where: { $0.id == id }) else { return }

        let updates = WardrobeItemUpdate(
            isFavorite: !(item.isFavorite ?? false)
        )

        try await updateItem(id: id, updates: updates)
        HapticManager.shared.medium()
    }

    // MARK: - Studio Mode (Background Removal)

    func applyStudioMode(itemId: String) async throws -> String {
        let result = try await api.applyStudioMode(itemId: itemId)

        guard let cleanUrl = result.photoUrlClean else {
            throw WardrobeError.imageProcessingFailed
        }

        // Update local item
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            items[index].photoUrlClean = cleanUrl
            items[index].studioModeAt = Date()
        }

        HapticManager.shared.success()
        return cleanUrl
    }

    // MARK: - Helpers

    private func extractStoragePath(from url: String) -> String? {
        // Extract path after /wardrobe/
        guard let range = url.range(of: "/wardrobe/") else { return nil }
        return String(url[range.upperBound...])
    }

    // MARK: - Computed Properties

    func items(for category: ClothingCategory) -> [WardrobeItem] {
        items.filter { $0.category == category }
    }

    func itemCount(for category: ClothingCategory) -> Int {
        items(for: category).count
    }

    var hasEnoughForOutfits: Bool {
        print("🎨 [WARDROBE] ========== CHECKING hasEnoughForOutfits ==========")
        print("🎨 [WARDROBE] Total items: \(items.count)")

        for item in items {
            print("🎨 [WARDROBE] Item: \(item.itemName ?? "unnamed") - Category: \(item.category?.rawValue ?? "nil")")
        }

        let tops = items(for: .tops)
        let bottoms = items(for: .bottoms)
        let shoes = items(for: .shoes)

        print("🎨 [WARDROBE] Tops count: \(tops.count)")
        print("🎨 [WARDROBE] Bottoms count: \(bottoms.count)")
        print("🎨 [WARDROBE] Shoes count: \(shoes.count)")

        let hasEnough = tops.count >= 1 && bottoms.count >= 1 && shoes.count >= 1
        print("🎨 [WARDROBE] hasEnoughForOutfits: \(hasEnough)")
        print("🎨 [WARDROBE] ===========================================")

        return hasEnough
    }
}

// MARK: - Request Types

struct WardrobeItemUpdate: Encodable {
    var itemName: String?
    var timesWorn: Int?
    var lastWorn: Date?
    var tags: [String]?
    var primaryColor: String?
    var isFavorite: Bool?
    var category: String?
    var styleVibes: [String]?
    var material: String?
    var formality: Int?
    var occasions: [String]?

    enum CodingKeys: String, CodingKey {
        case itemName = "item_name"
        case timesWorn = "times_worn"
        case lastWorn = "last_worn"
        case tags
        case primaryColor = "primary_color"
        case isFavorite = "is_favorite"
        case category
        case styleVibes = "style_vibes"
        case material
        case formality
        case occasions
    }
}

// MARK: - Wardrobe Errors

enum WardrobeError: LocalizedError {
    case notAuthenticated
    case imageProcessingFailed
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to add items to your wardrobe."
        case .imageProcessingFailed:
            return "We had trouble with that photo. Try a different image or take a new one."
        case .uploadFailed:
            return "Couldn't save your item right now. Check your connection and try again."
        }
    }
}
