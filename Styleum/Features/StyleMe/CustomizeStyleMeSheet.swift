import SwiftUI

struct CustomizeStyleMeSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedOccasion: String? = "Casual"
    @State private var boldnessLevel: Double = 0.5

    private let occasions = ["Casual", "Work", "Date Night", "Special Event", "Workout"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Occasion
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("OCCASION")
                            .font(AppTypography.kicker)
                            .foregroundColor(AppColors.textMuted)
                            .tracking(1)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppSpacing.xs) {
                                ForEach(occasions, id: \.self) { occasion in
                                    AppChip(
                                        label: occasion,
                                        isSelected: selectedOccasion == occasion
                                    ) {
                                        selectedOccasion = occasion
                                    }
                                }
                            }
                        }
                    }

                    // Boldness
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("BOLDNESS")
                            .font(AppTypography.kicker)
                            .foregroundColor(AppColors.textMuted)
                            .tracking(1)

                        HStack {
                            Text("Subtle")
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColors.textSecondary)

                            Slider(value: $boldnessLevel)
                                .tint(AppColors.slate)

                            Text("Bold")
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }

                    Spacer(minLength: AppSpacing.xl)
                }
                .padding(AppSpacing.pageMargin)
            }
            .background(AppColors.background)
            .navigationTitle("Customize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    CustomizeStyleMeSheet()
}
