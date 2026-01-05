import SwiftUI

struct ProgressBar: View {
    let progress: Double // 0.0 to 1.0
    var height: CGFloat = 8
    var backgroundColor: Color = AppColors.filterTagBg
    var foregroundColor: Color = AppColors.slate
    var animated: Bool = true

    @State private var animatedProgress: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor)

                // Foreground
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(foregroundColor)
                    .frame(width: geo.size.width * (animated ? animatedProgress : progress))
            }
        }
        .frame(height: height)
        .onAppear {
            if animated {
                withAnimation(.easeOut(duration: 0.8)) {
                    animatedProgress = progress
                }
            }
        }
        .onChange(of: progress) { _, newValue in
            if animated {
                withAnimation(.easeOut(duration: 0.3)) {
                    animatedProgress = newValue
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        ProgressBar(progress: 0.3)
        ProgressBar(progress: 0.7, foregroundColor: AppColors.success)
        ProgressBar(progress: 1.0, height: 12, foregroundColor: .orange)
    }
    .padding()
}
