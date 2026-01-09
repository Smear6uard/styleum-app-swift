import SwiftUI

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showFirstConfirmation = false
    @State private var showFinalConfirmation = false
    @State private var confirmationText = ""
    @State private var isDeleting = false
    @State private var error: Error?

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Warning header
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.red)

                    Text("Delete Your Account")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("This action is permanent and cannot be undone.")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                // What will be deleted
                VStack(alignment: .leading, spacing: 16) {
                    Text("What will be deleted:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    VStack(alignment: .leading, spacing: 12) {
                        deletionItem("Your wardrobe items and photos")
                        deletionItem("All generated outfits")
                        deletionItem("Style preferences and quiz results")
                        deletionItem("Achievement progress")
                        deletionItem("Account and profile information")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color(hex: "FEF2F2"))
                .cornerRadius(12)

                // Subscription reminder
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "creditcard")
                            .foregroundColor(AppColors.textSecondary)
                        Text("Subscription Note")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Text("If you have an active subscription, please cancel it in your device's Settings app before deleting your account to avoid future charges.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppColors.backgroundSecondary)
                .cornerRadius(12)

                Spacer(minLength: 40)

                // Delete button
                Button {
                    showFirstConfirmation = true
                } label: {
                    HStack {
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        }
                        Text(isDeleting ? "Deleting..." : "Delete My Account")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red)
                    .cornerRadius(12)
                }
                .disabled(isDeleting)
                .opacity(isDeleting ? 0.7 : 1)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Are you sure?", isPresented: $showFirstConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Continue", role: .destructive) {
                showFinalConfirmation = true
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This cannot be undone.")
        }
        .alert("Type DELETE to confirm", isPresented: $showFinalConfirmation) {
            TextField("Type DELETE", text: $confirmationText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
            Button("Cancel", role: .cancel) {
                confirmationText = ""
            }
            Button("Delete Forever", role: .destructive) {
                if confirmationText.uppercased() == "DELETE" {
                    deleteAccount()
                }
                confirmationText = ""
            }
        } message: {
            Text("Type DELETE in all caps to permanently delete your account.")
        }
        .alert("Error", isPresented: .init(
            get: { error != nil },
            set: { if !$0 { error = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error?.localizedDescription ?? "An error occurred")
        }
    }

    @ViewBuilder
    private func deletionItem(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.red.opacity(0.7))
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(AppColors.textPrimary)
        }
    }

    private func deleteAccount() {
        isDeleting = true
        HapticManager.shared.medium()

        Task {
            do {
                // 1. Delete account via API (removes all backend data)
                try await StyleumAPI.shared.deleteAccount()

                // 2. Sign out from auth services
                try await AuthService.shared.signOut()

                // 3. Clear all local data
                ProfileService.shared.reset()
                WardrobeService.shared.clearCache()
                OutfitRepository.shared.clearCache()

                // 4. Dismiss view - RootView will automatically show login
                await MainActor.run {
                    HapticManager.shared.success()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    isDeleting = false
                    HapticManager.shared.error()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DeleteAccountView()
    }
}
