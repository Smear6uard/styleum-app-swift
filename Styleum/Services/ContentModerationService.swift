import Vision
import UIKit

actor ContentModerationService {
    static let shared = ContentModerationService()

    private init() {}

    func isSafeForUpload(_ image: UIImage) async throws -> Bool {
        #if targetEnvironment(simulator)
        print("[ContentModeration] Skipping in simulator - Vision ML not supported")
        return true
        #else
        guard let cgImage = image.cgImage else {
            throw ContentModerationError.invalidImage
        }

        // Run on background thread to avoid blocking and prevent cancellation
        return try await Task.detached(priority: .userInitiated) {
            try self.performModerationCheck(cgImage: cgImage)
        }.value
        #endif
    }

    private nonisolated func performModerationCheck(cgImage: CGImage) throws -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var isSafe = true
        var completionError: Error?

        let request = VNClassifyImageRequest { request, error in
            defer { semaphore.signal() }

            if let error = error {
                completionError = error
                return
            }

            guard let results = request.results as? [VNClassificationObservation] else {
                return
            }

            let sensitiveCategories = ["explicit", "nudity", "sexual", "adult", "racy"]

            for result in results {
                let identifier = result.identifier.lowercased()
                if result.confidence > 0.7 {
                    for category in sensitiveCategories {
                        if identifier.contains(category) {
                            isSafe = false
                            return
                        }
                    }
                }
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        // Wait for completion (perform is synchronous, but callback may be async)
        _ = semaphore.wait(timeout: .now() + 5.0)

        if let error = completionError {
            throw error
        }

        return isSafe
    }
}

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
