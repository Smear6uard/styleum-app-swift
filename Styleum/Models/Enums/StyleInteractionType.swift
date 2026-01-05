import Foundation

enum StyleInteractionType: String, Codable {
    case wear
    case like
    case save
    case reject
    case skip
    case tagEdit = "tag_edit"
    case vibeConfirm = "vibe_confirm"
    case vibeReject = "vibe_reject"

    var weight: Double {
        switch self {
        case .wear: return 1.0
        case .like, .save: return 0.5
        case .reject: return -0.5
        case .skip: return -0.1
        case .tagEdit: return 2.0
        case .vibeConfirm: return 1.5
        case .vibeReject: return -1.0
        }
    }
}
