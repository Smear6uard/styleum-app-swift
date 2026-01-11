//
//  ReferralService.swift
//  Styleum
//
//  Handles referral code generation, application, and stats tracking.
//

import Foundation

// MARK: - Models

struct ReferralStats {
    let totalReferrals: Int
    let completedReferrals: Int
    let pendingReferrals: Int
    let totalDaysEarned: Int

    init(from response: ReferralStatsResponse) {
        self.totalReferrals = response.totalReferrals
        self.completedReferrals = response.completedReferrals
        self.pendingReferrals = response.pendingReferrals
        self.totalDaysEarned = response.totalDaysEarned
    }

    // For initial/empty state
    init() {
        self.totalReferrals = 0
        self.completedReferrals = 0
        self.pendingReferrals = 0
        self.totalDaysEarned = 0
    }
}

enum ApplyCodeResult {
    case success(daysEarned: Int)
    case alreadyApplied
    case invalidCode
    case ownCode
}

enum ReferralError: LocalizedError {
    case invalidCode
    case alreadyApplied
    case cannotUseOwnCode
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidCode:
            return "This referral code doesn't exist"
        case .alreadyApplied:
            return "You've already used a referral code"
        case .cannotUseOwnCode:
            return "You can't use your own referral code"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Service

@Observable
@MainActor
final class ReferralService {
    static let shared = ReferralService()

    // MARK: - State

    var referralCode: String?
    var shareUrl: String?
    var stats: ReferralStats?
    var isLoading = false

    // MARK: - Private

    private let api = StyleumAPI.shared

    // MARK: - UserDefaults Keys (namespaced to avoid collisions)

    private let pendingCodeKey = "com.sameerstudios.Styleum.pendingReferralCode"
    private let pendingCodeTimestampKey = "com.sameerstudios.Styleum.pendingReferralCodeTimestamp"
    private let hasAppliedCodeKey = "com.sameerstudios.Styleum.hasAppliedReferralCode"

    // Pending code expires after 48 hours
    private let pendingCodeExpirySeconds: TimeInterval = 48 * 60 * 60

    // MARK: - Init

    private init() {}

    // MARK: - Fetch Referral Info (Code + Stats)

    func fetchReferralInfo() async throws {
        isLoading = true
        defer { isLoading = false }

        print("📨 [Referral] Fetching referral info...")

        do {
            let response = try await api.getReferralInfo()
            referralCode = response.code
            shareUrl = response.shareUrl
            stats = ReferralStats(from: response.stats)

            print("📨 [Referral] ✅ Got code: \(response.code)")
            print("📨 [Referral] ✅ Stats - total: \(response.stats.totalReferrals), completed: \(response.stats.completedReferrals), days: \(response.stats.totalDaysEarned)")
        } catch {
            print("📨 [Referral] ❌ Failed to fetch referral info: \(error)")
            throw ReferralError.networkError(error)
        }
    }

    // MARK: - Apply Referral Code

    func applyCode(_ code: String) async throws -> ApplyCodeResult {
        let normalizedCode = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        print("📨 [Referral] Applying code: \(normalizedCode)")

        do {
            let response = try await api.applyReferralCode(normalizedCode)

            if response.success {
                let daysEarned = response.daysEarned ?? 7
                UserDefaults.standard.set(true, forKey: hasAppliedCodeKey)
                print("📨 [Referral] ✅ Code applied successfully, earned \(daysEarned) days")
                return .success(daysEarned: daysEarned)
            } else {
                // Handle error codes from backend
                switch response.code {
                case "already_applied":
                    print("📨 [Referral] ❌ Already applied a code")
                    throw ReferralError.alreadyApplied
                case "invalid_code":
                    print("📨 [Referral] ❌ Invalid code")
                    throw ReferralError.invalidCode
                case "own_code":
                    print("📨 [Referral] ❌ Cannot use own code")
                    throw ReferralError.cannotUseOwnCode
                default:
                    print("📨 [Referral] ❌ Unknown error: \(response.error ?? "unknown")")
                    throw ReferralError.invalidCode
                }
            }
        } catch let error as ReferralError {
            throw error
        } catch {
            print("📨 [Referral] ❌ Network error: \(error)")
            throw ReferralError.networkError(error)
        }
    }

    // MARK: - Validate Code (optional pre-check)

    func validateCode(_ code: String) async throws -> (valid: Bool, referrerName: String?) {
        let normalizedCode = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        print("📨 [Referral] Validating code: \(normalizedCode)")

        do {
            let response = try await api.validateReferralCode(normalizedCode)
            print("📨 [Referral] Validation result - valid: \(response.valid), referrer: \(response.referrerName ?? "unknown")")
            return (response.valid, response.referrerName)
        } catch {
            print("📨 [Referral] ❌ Validation failed: \(error)")
            throw ReferralError.networkError(error)
        }
    }

    // MARK: - Pending Code (for deep links before auth)

    func storePendingCode(_ code: String) {
        let normalizedCode = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(normalizedCode, forKey: pendingCodeKey)
        UserDefaults.standard.set(Date(), forKey: pendingCodeTimestampKey)
        print("📨 [Referral] Stored pending code: \(normalizedCode)")
    }

    func getPendingCode() -> String? {
        // Check if code exists and hasn't expired
        guard let timestamp = UserDefaults.standard.object(forKey: pendingCodeTimestampKey) as? Date else {
            // No timestamp - clear stale code from before expiration was added
            clearPendingCode()
            return nil
        }

        if Date().timeIntervalSince(timestamp) > pendingCodeExpirySeconds {
            print("📨 [Referral] Pending code expired (older than 48h)")
            clearPendingCode()
            return nil
        }

        return UserDefaults.standard.string(forKey: pendingCodeKey)
    }

    func clearPendingCode() {
        UserDefaults.standard.removeObject(forKey: pendingCodeKey)
        UserDefaults.standard.removeObject(forKey: pendingCodeTimestampKey)
        print("📨 [Referral] Cleared pending code")
    }

    // MARK: - Has Applied Code

    func hasAppliedCode() -> Bool {
        UserDefaults.standard.bool(forKey: hasAppliedCodeKey)
    }

    // MARK: - Share URL

    func getShareURL() -> URL? {
        if let shareUrl = shareUrl {
            return URL(string: shareUrl)
        }
        // Fallback if shareUrl not loaded yet
        guard let code = referralCode else { return nil }
        return URL(string: "https://styleum.app/r/\(code)")
    }

    func getShareMessage() -> String {
        let code = referralCode ?? "STYLEUM"
        let link = getShareURL()?.absoluteString ?? "https://styleum.app"

        return """
        Join me on Styleum! Get AI-powered outfit recommendations daily.

        Use my code: \(code)
        \(link)
        """
    }

    // MARK: - Reset (for sign out)

    func reset() {
        referralCode = nil
        shareUrl = nil
        stats = nil
        isLoading = false
        print("📨 [Referral] Service reset")
    }
}
