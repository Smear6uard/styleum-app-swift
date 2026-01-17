import SwiftUI

/// Standalone static view for App Store screenshot purposes.
/// No dependencies on RevenueCat, TierManager, or any services.
struct ProUpgradeScreenshotView: View {
    @Environment(\.dismiss) private var dismiss

    private let features = [
        "Unlimited wardrobe items",
        "4 daily outfit suggestions",
        "75 Style Me credits per month"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Header
                VStack(spacing: 8) {
                    Text("Styleum Pro")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color.primary)

                    Text("$9.99/month")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.secondary)
                }

                // Features
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.primary)

                            Text(feature)
                                .font(.system(size: 17))
                                .foregroundStyle(Color.primary)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Subscribe button and footer
                VStack(spacing: 16) {
                    Button {
                        // No action - for screenshot only
                    } label: {
                        Text("Subscribe")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Text("Cancel anytime")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    ProUpgradeScreenshotView()
}
