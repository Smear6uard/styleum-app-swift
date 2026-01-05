import Vision
import UIKit

/// On-device content moderation using Apple Vision framework.
/// Blocks inappropriate images before they're uploaded to the server.
actor ContentModerationService {
    static let shared = ContentModerationService()

    private init() {}

    /// Check if image is safe to upload
    /// Returns true if safe, false if flagged as sensitive
    func isSafeForUpload(_ image: UIImage) async throws -> Bool {
        guard let cgImage = image.cgImage else {
            throw ContentModerationError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: true) // Allow if can't classify
                    return
                }

                // Check for sensitive content classifications
                let sensitiveCategories = [
                    "explicit",
                    "nudity",
                    "sexual",
                    "adult",
                    "racy"
                ]

                for result in results {
                    let identifier = result.identifier.lowercased()
                    let confidence = result.confidence

                    for category in sensitiveCategories {
                        if identifier.contains(category) && confidence > 0.7 {
                            print("[ContentModeration] Flagged: \(identifier) (\(confidence))")
                            continuation.resume(returning: false)
                            return
                        }
                    }
                }

                continuation.resume(returning: true)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

// MARK: - Content Moderation Error

enum ContentModerationError: LocalizedError {
    case invalidImage
    case flaggedContent

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to process image"
        case .flaggedContent:
            return "This image can't be used. Please try a different photo."
        }
    }
}
