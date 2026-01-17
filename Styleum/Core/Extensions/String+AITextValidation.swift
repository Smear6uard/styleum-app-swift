import Foundation

extension String {
    /// Returns true if this AI-generated text is meaningful and specific enough to display.
    /// Returns false if the text is too short, empty, or contains generic filler phrases.
    ///
    /// The principle: "No text is better than bad text"
    var isMeaningfulAIText: Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)

        // Rule 1: Empty or too short (less than 20 characters)
        guard trimmed.count >= 20 else { return false }

        // Rule 2: Check for generic filler phrases (case-insensitive)
        let lowercased = trimmed.lowercased()
        for phrase in Self.genericAIPhrases {
            if lowercased.contains(phrase) {
                return false
            }
        }

        return true
    }

    /// Returns self if the text is meaningful, otherwise nil.
    /// Useful for conditional display with optional binding.
    var ifMeaningful: String? {
        isMeaningfulAIText ? self : nil
    }

    /// List of generic AI phrases that indicate low-quality filler text.
    /// These phrases are vague and don't describe specific outfit items or colors.
    private static let genericAIPhrases: [String] = [
        // Color-related generic phrases
        "complement each other",
        "colors complement",
        "complement nicely",
        "complements the",
        "complementary colors",
        "harmonious colors",
        "color harmony",
        "colors work well",
        "colors go well",
        "nice color",
        "great colors",

        // General fit/combination phrases
        "works well together",
        "work well together",
        "goes well with",
        "go well with",
        "pairs nicely",
        "pair nicely",
        "great combination",
        "nice combination",
        "good combination",
        "perfect combination",
        "excellent combination",

        // Generic outfit praise
        "nice outfit",
        "great outfit",
        "good outfit",
        "perfect outfit",
        "lovely outfit",

        // Generic look phrases
        "cohesive look",
        "polished look",
        "balanced look",
        "well-balanced",
        "ties the look together",
        "brings the look together",
        "completes the look",

        // Vague style descriptors
        "looks great",
        "looks good",
        "looks nice",
        "looks stylish"
    ]
}
