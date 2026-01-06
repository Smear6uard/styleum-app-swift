import SwiftUI

/// Segmented progress bar for onboarding flow
struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        GeometryReader { _ in
            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Rectangle()
                        .fill(index < currentStep ? Color.black : Color.black.opacity(0.15))
                        .frame(height: 2)
                }
            }
        }
        .frame(height: 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        OnboardingProgressBar(currentStep: 0, totalSteps: 6)
        OnboardingProgressBar(currentStep: 2, totalSteps: 6)
        OnboardingProgressBar(currentStep: 4, totalSteps: 6)
        OnboardingProgressBar(currentStep: 6, totalSteps: 6)
    }
    .padding()
}
