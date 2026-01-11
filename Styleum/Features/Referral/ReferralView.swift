//
//  ReferralView.swift
//  Styleum
//
//  Main referral hub with code display, share, stats, and how-it-works.
//

import SwiftUI

struct ReferralView: View {
    @Environment(AppCoordinator.self) private var coordinator
    private let referralService = ReferralService.shared
    @State private var showCopiedToast = false
    @State private var showApplyCodeSheet = false
    @State private var isAnimating = false
    @State private var loadError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // MARK: - Referral Code Card
                referralCodeCard

                // MARK: - Share Button
                AppButton(
                    label: "Share with Friends",
                    icon: .share,
                    iconPosition: .leading
                ) {
                    shareReferralCode()
                }

                // MARK: - Stats Section
                if let stats = referralService.stats {
                    statsSection(stats)
                }

                // MARK: - How It Works
                howItWorksCard

                // MARK: - Have a Code Link
                Button {
                    HapticManager.shared.light()
                    showApplyCodeSheet = true
                } label: {
                    Text("Have a referral code?")
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColors.brownPrimary)
                }
                .padding(.top, AppSpacing.sm)
            }
            .padding(AppSpacing.pageMargin)
        }
        .background(AppColors.background)
        .navigationTitle("Invite Friends")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showApplyCodeSheet) {
            ApplyCodeSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                copiedToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task {
            await loadData()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
    }

    // MARK: - Referral Code Card

    private var referralCodeCard: some View {
        VStack(spacing: AppSpacing.md) {
            Text("YOUR REFERRAL CODE")
                .font(AppTypography.kicker)
                .foregroundColor(AppColors.textSecondary)

            Button {
                copyCode()
            } label: {
                VStack(spacing: AppSpacing.sm) {
                    if let code = referralService.referralCode {
                        Text(code)
                            .font(AppTypography.editorial(28, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .tracking(4)
                    } else if let error = loadError {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 24))
                                .foregroundColor(AppColors.textMuted)
                            Text(error)
                                .font(AppTypography.bodySmall)
                                .foregroundColor(AppColors.textSecondary)
                            Button("Retry") {
                                loadError = nil
                                Task { await loadData() }
                            }
                            .font(AppTypography.labelMedium)
                            .foregroundColor(AppColors.brownPrimary)
                        }
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.lg)
                .padding(.horizontal, AppSpacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                        .fill(AppColors.brownPrimary.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                        .strokeBorder(AppColors.border, lineWidth: 1)
                )
            }
            .buttonStyle(CodeCardButtonStyle())
            .disabled(referralService.referralCode == nil && loadError == nil)

            Text(loadError != nil ? "" : "Tap to copy")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textMuted)
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusLg)
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 10)
    }

    // MARK: - Stats Section

    private func statsSection(_ stats: ReferralStats) -> some View {
        HStack(spacing: 0) {
            statItem(value: stats.totalReferrals, label: "Invited")
            Divider()
                .frame(height: 40)
            statItem(value: stats.completedReferrals, label: "Joined")
            Divider()
                .frame(height: 40)
            statItem(value: stats.totalDaysEarned, label: "Days Earned")
        }
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusMd)
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 10)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: isAnimating)
    }

    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(AppTypography.headingLarge)
                .foregroundColor(AppColors.brownPrimary)
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - How It Works Card

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("HOW IT WORKS")
                .font(AppTypography.kicker)
                .foregroundColor(AppColors.textSecondary)

            VStack(spacing: AppSpacing.md) {
                howItWorksStep(
                    number: 1,
                    title: "Share your code",
                    description: "Send your unique code to friends"
                )

                howItWorksStep(
                    number: 2,
                    title: "They sign up",
                    description: "Your friend creates an account with your code"
                )

                howItWorksStep(
                    number: 3,
                    title: "You both win",
                    description: "Get 7 days of Styleum Pro each!"
                )
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.backgroundSecondary)
        .cornerRadius(AppSpacing.radiusLg)
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 10)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: isAnimating)
    }

    private func howItWorksStep(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            // Step number circle
            Text("\(number)")
                .font(AppTypography.labelMedium)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(AppColors.brownPrimary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.labelLarge)
                    .foregroundColor(AppColors.textPrimary)

                Text(description)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Copied Toast

    private var copiedToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppColors.success)
            Text("Copied to clipboard")
                .font(AppTypography.labelMedium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(AppSpacing.radiusMd)
        .padding(.bottom, 32)
    }

    // MARK: - Actions

    private func loadData() async {
        do {
            try await referralService.fetchReferralInfo()
            // Check if code loaded successfully after fetch
            if referralService.referralCode == nil {
                loadError = "Couldn't load your code"
            }
        } catch {
            print("❌ [Referral] Failed to load data: \(error)")
            loadError = "Network error. Tap to retry."
        }
    }

    private func copyCode() {
        guard let code = referralService.referralCode else { return }

        UIPasteboard.general.string = code
        HapticManager.shared.success()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showCopiedToast = true
        }

        // Auto-hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.25)) {
                showCopiedToast = false
            }
        }
    }

    private func shareReferralCode() {
        HapticManager.shared.medium()

        let message = referralService.getShareMessage()
        let activityVC = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )

        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks,
            .print
        ]

        // Use foregroundActive scene filter and isKeyWindow check for reliable presentation
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
            let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
            let rootVC = keyWindow.rootViewController else {
            print("❌ [Referral] Failed to find key window for share sheet")
            return
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        // iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(
                x: topVC.view.bounds.midX,
                y: topVC.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        // Dispatch to main thread to ensure smooth presentation
        DispatchQueue.main.async {
            topVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Code Card Button Style

private struct CodeCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReferralView()
            .environment(AppCoordinator())
    }
}
