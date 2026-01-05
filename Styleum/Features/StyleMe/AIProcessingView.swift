import SwiftUI

struct AIProcessingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isVisible = true

    var body: some View {
        AIProcessingOverlay(isVisible: $isVisible)
            .onAppear {
                // Auto-dismiss after processing simulation
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    dismiss()
                }
            }
    }
}

#Preview {
    AIProcessingView()
}
