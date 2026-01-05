import SwiftUI
import Kingfisher

struct AvatarView: View {
    var imageURL: String?
    var initials: String?
    var size: AvatarSize = .medium

    enum AvatarSize {
        case small, medium, large, xlarge

        var dimension: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 48
            case .large: return 72
            case .xlarge: return 100
            }
        }

        var font: Font {
            switch self {
            case .small: return AppTypography.labelSmall
            case .medium: return AppTypography.labelLarge
            case .large: return AppTypography.headingMedium
            case .xlarge: return AppTypography.displayMedium
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 24
            case .large: return 32
            case .xlarge: return 44
            }
        }
    }

    var body: some View {
        Group {
            if let imageURL = imageURL, let url = URL(string: imageURL) {
                KFImage(url)
                    .placeholder {
                        placeholderView
                    }
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderView
            }
        }
        .frame(width: size.dimension, height: size.dimension)
        .clipShape(Circle())
    }

    @ViewBuilder
    private var placeholderView: some View {
        Circle()
            .fill(AppColors.filterTagBg)
            .overlay(
                Group {
                    if let initials = initials {
                        Text(initials.prefix(2).uppercased())
                            .font(size.font)
                            .foregroundColor(AppColors.textSecondary)
                    } else {
                        Image(symbol: .profile)
                            .font(.system(size: size.iconSize, weight: .medium))
                            .foregroundColor(AppColors.textMuted)
                    }
                }
            )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        AvatarView(initials: "SA", size: .small)
        AvatarView(initials: "SA", size: .medium)
        AvatarView(initials: "SA", size: .large)
        AvatarView(size: .xlarge)
    }
}
