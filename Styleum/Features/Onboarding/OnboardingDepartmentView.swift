import SwiftUI

/// Step 3: Style department selection (womenswear/menswear) - Single select
struct OnboardingDepartmentView: View {
    @Binding var selectedDepartment: String
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("I mostly shop")
                    .font(AppTypography.displayLarge)
                    .foregroundColor(AppColors.textPrimary)
                Text("in...")
                    .font(AppTypography.clashDisplayItalic(32))
                    .foregroundColor(AppColors.textPrimary)
            }
            .padding(.top, AppSpacing.xl)

            Text("This helps us show relevant styles")
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .padding(.top, AppSpacing.sm)

            // Options - simple radio buttons
            VStack(spacing: AppSpacing.sm) {
                DepartmentOption(
                    title: "Womenswear",
                    isSelected: selectedDepartment == "womenswear",
                    action: {
                        HapticManager.shared.selection()
                        selectedDepartment = "womenswear"
                    }
                )

                DepartmentOption(
                    title: "Menswear",
                    isSelected: selectedDepartment == "menswear",
                    action: {
                        HapticManager.shared.selection()
                        selectedDepartment = "menswear"
                    }
                )
            }
            .padding(.top, AppSpacing.lg)

            Spacer()

            // Continue button
            Button {
                HapticManager.shared.medium()
                onContinue()
            } label: {
                Text("Continue")
                    .font(AppTypography.labelLarge)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(selectedDepartment.isEmpty ? AppColors.textMuted : AppColors.black)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(selectedDepartment.isEmpty)
            .padding(.bottom, AppSpacing.xl)
        }
        .padding(.horizontal, AppSpacing.pageMargin)
        .background(AppColors.background)
    }
}

/// Radio button option for department selection
struct DepartmentOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(AppTypography.bodyLarge)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                // Radio indicator
                Circle()
                    .strokeBorder(isSelected ? AppColors.black : AppColors.border, lineWidth: 2)
                    .background(Circle().fill(isSelected ? AppColors.black : Color.clear))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding(AppSpacing.md)
            .background(AppColors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMd))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    OnboardingDepartmentView(
        selectedDepartment: .constant(""),
        onContinue: {}
    )
}
