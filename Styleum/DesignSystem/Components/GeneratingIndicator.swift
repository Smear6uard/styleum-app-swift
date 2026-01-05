import SwiftUI
import Combine

struct GeneratingIndicator: View {
    @State private var dotCount = 0

    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            Text("Creating")
                .font(AppTypography.labelMedium)
                .foregroundColor(AppColors.textSecondary)

            HStack(spacing: 2) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(AppColors.textMuted)
                        .frame(width: 4, height: 4)
                        .opacity(index < dotCount ? 1 : 0.3)
                }
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                dotCount = (dotCount + 1) % 4
            }
        }
    }
}

#Preview {
    GeneratingIndicator()
}
