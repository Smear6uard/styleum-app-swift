import SwiftUI
import UIKit
import UserNotifications

struct OutfitResultsView: View {
    /// When true, view is displayed inline (StyleMeScreen). When false, displayed as modal (HomeScreen fullScreenCover).
    var isInlineMode: Bool = false

    @Environment(\.dismiss) private var dismiss
    @Environment(AppCoordinator.self) private var coordinator
    @State private var wardrobeService = WardrobeService.shared
    @State private var outfitRepo = OutfitRepository.shared
    @State private var shareService = ShareService.shared
    @State private var tierManager = TierManager.shared

    @State private var currentIndex = 0
    @State private var isSaved = false
    @State private var isRegenerating = false

    // Drawer state
    @State private var drawerExpanded = false
    @State private var dragOffset: CGFloat = 0

    // Sheet states
    @State private var showVerifySheet = false
    @State private var showWearConfirmation = false
    @State private var showRegenerateSheet = false
    @State private var showProPaywall = false

    // XP Toast
    @State private var showXPToast = false
    @State private var xpAmount = 0
    @State private var isXPBonus = false

    // Drawer constants - increased peek for better content visibility
    private let drawerPeekHeight: CGFloat = 200
    private let drawerExpandedHeight: CGFloat = 420

    private var outfits: [ScoredOutfit] { outfitRepo.todaysOutfits }
    private var currentOutfit: ScoredOutfit? {
        guard currentIndex < outfits.count else { return nil }
        return outfits[currentIndex]
    }

    // Tier-aware outfit limits
    private var unlockedOutfitCount: Int {
        tierManager.isPro ? outfits.count : min(outfits.count, tierManager.tierInfo?.limits.dailyOutfits ?? 2)
    }

    private var isCurrentOutfitLocked: Bool {
        !tierManager.isPro && currentIndex >= unlockedOutfitCount
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background
                Color(hex: "FAFAF8").ignoresSafeArea()

                // Bug Fix: In inline mode, if outfits array is empty, show loading state
                // instead of empty state (data may still be syncing)
                if isInlineMode && outfits.isEmpty {
                    loadingState
                } else if let outfit = currentOutfit {
                    // MARK: - Hero Image (horizontal paging)
                    TabView(selection: $currentIndex) {
                        ForEach(Array(outfits.enumerated()), id: \.offset) { index, outfit in
                            // Show locked card for outfits beyond tier limit
                            if !tierManager.isPro && index >= unlockedOutfitCount {
                                lockedOutfitView(outfit, geometry: geometry)
                                    .tag(index)
                            } else {
                                outfitHeroImage(outfit, geometry: geometry)
                                    .tag(index)
                                    .contextMenu {
                                        Button {
                                            shareOutfit(outfit)
                                        } label: {
                                            Label("Share", systemImage: "square.and.arrow.up")
                                        }

                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                isSaved.toggle()
                                            }
                                            if isSaved {
                                                GamificationService.shared.awardXP(2, reason: .outfitLiked)
                                            }
                                            HapticManager.shared.medium()
                                        } label: {
                                            Label(isSaved ? "Unlike" : "Like", systemImage: isSaved ? "heart.slash" : "heart")
                                        }

                                        Button {
                                            wearOutfit()
                                        } label: {
                                            Label("Wear This", systemImage: "checkmark.circle")
                                        }

                                        Divider()

                                        Button {
                                            showRegenerateSheet = true
                                        } label: {
                                            Label("Regenerate", systemImage: "arrow.clockwise")
                                        }
                                    }
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea()

                    // MARK: - Top Bar
                    VStack {
                        topBar
                        Spacer()
                    }

                    // MARK: - Bottom Drawer
                    bottomDrawer(outfit: outfit, geometry: geometry)
                } else {
                    emptyState
                }
            }
        }
        .navigationBarHidden(true)
        .overlay(alignment: .top) {
            if showXPToast {
                XPToast(amount: xpAmount, isBonus: isXPBonus, isShowing: $showXPToast)
                    .padding(.top, 60)
            }
        }
        .sheet(isPresented: $showVerifySheet) {
            if let outfit = currentOutfit {
                VerifyOutfitSheet(
                    outfit: outfit,
                    onVerify: { image in
                        handleVerifiedWear(image: image)
                    },
                    onSkip: {
                        handleUnverifiedWear()
                    }
                )
            }
        }
        .sheet(isPresented: $showWearConfirmation) {
            if let outfit = currentOutfit {
                WearConfirmationView(
                    outfit: outfit,
                    onConfirm: {
                        showWearConfirmation = false
                        handleWearConfirmed()
                    },
                    onCancel: {
                        showWearConfirmation = false
                    }
                )
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showRegenerateSheet) {
            if let outfit = currentOutfit {
                RegenerateSheet(
                    currentOutfit: outfit,
                    isPro: tierManager.isPro,
                    onRegenerate: { feedback in
                        regenerateOutfit(with: feedback)
                    },
                    onUpgrade: {
                        coordinator.navigate(to: .subscription)
                    }
                )
            }
        }
        .sheet(isPresented: $showProPaywall) {
            ProUpgradeView(trigger: .lockedOutfits)
        }
        .onChange(of: currentIndex) { _, _ in
            isSaved = false
            drawerExpanded = false
            HapticManager.shared.selection()
        }
    }

    // MARK: - Hero Image

    private func outfitHeroImage(_ outfit: ScoredOutfit, geometry: GeometryProxy) -> some View {
        let availableHeight = geometry.size.height - drawerPeekHeight - 100 // top bar + padding

        return VStack {
            if let heroUrl = heroImageUrl(for: outfit) {
                AsyncImage(url: URL(string: heroUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: max(1, geometry.size.width))
                            .frame(maxHeight: max(1, availableHeight))
                    case .failure, .empty:
                        imagePlaceholder
                    @unknown default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
            Spacer()
        }
        .padding(.top, 90)
    }

    private var imagePlaceholder: some View {
        CardImageSkeleton()
            .frame(height: 300)
            .cornerRadius(AppSpacing.radiusMd)
    }

    private func heroImageUrl(for outfit: ScoredOutfit) -> String? {
        if let items = outfit.items, let firstItem = items.first {
            return firstItem.imageUrl
        }
        if let firstItemId = outfit.wardrobeItemIds.first,
           let wardrobeItem = wardrobeService.items.first(where: { $0.id == firstItemId }) {
            return wardrobeItem.displayPhotoUrl
        }
        return nil
    }

    // MARK: - Locked Outfit View

    private func lockedOutfitView(_ outfit: ScoredOutfit, geometry: GeometryProxy) -> some View {
        let availableHeight = geometry.size.height - drawerPeekHeight - 100

        return VStack {
            LockedOutfitCard(
                imageURL: URL(string: heroImageUrl(for: outfit) ?? ""),
                onUnlock: {
                    showProPaywall = true
                }
            )
            .frame(maxWidth: geometry.size.width - 48)
            .frame(maxHeight: availableHeight)
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.top, 90)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                HapticManager.shared.light()
                if isInlineMode {
                    // Clear outfits to return to default StyleMe state
                    outfitRepo.clearSessionOutfits()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            if !outfits.isEmpty {
                Text("\(currentIndex + 1) of \(outfits.count)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Button {
                HapticManager.shared.medium()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isSaved.toggle()
                }
                // Award XP when liking (not un-liking)
                if isSaved {
                    GamificationService.shared.awardXP(2, reason: .outfitLiked)
                }
            } label: {
                Image(systemName: isSaved ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSaved ? .red : AppColors.textPrimary)
                    .frame(width: 44, height: 44)
                    .symbolEffect(.bounce, value: isSaved)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 50)
    }

    // MARK: - Bottom Drawer

    private func bottomDrawer(outfit: ScoredOutfit, geometry: GeometryProxy) -> some View {
        let currentHeight = drawerExpanded ? drawerExpandedHeight : drawerPeekHeight

        return VStack(spacing: 0) {
            // Drag handle
            drawerHandle

            // Peeking content (always visible)
            peekingContent(outfit: outfit)

            if drawerExpanded {
                // Expanded content
                expandedContent(outfit: outfit)
            }

            Spacer(minLength: 0)

            // Action buttons (always visible)
            actionButtons(outfit: outfit)
                .padding(.bottom, 34)
        }
        .frame(height: currentHeight + dragOffset)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 20, y: -5)
        )
        .gesture(drawerGesture)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: drawerExpanded)
    }

    // MARK: - Drag Handle

    private var drawerHandle: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(hex: "D0D0D0"))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                drawerExpanded.toggle()
            }
        }
    }

    // MARK: - Peeking Content (Always Visible)

    private func peekingContent(outfit: ScoredOutfit) -> some View {
        VStack(spacing: 12) {
            // Outfit narrative headline - contextual story
            Text(outfit.narrativeHeadline)
                .font(AppTypography.editorial(18, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // Item thumbnails row - larger for better visibility
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(outfit.items ?? [], id: \.id) { item in
                        AsyncImage(url: URL(string: item.imageUrl ?? "")) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure, .empty:
                                SkeletonBox(height: 48, width: 48, cornerRadius: 8)
                            @unknown default:
                                SkeletonBox(height: 48, width: 48, cornerRadius: 8)
                            }
                        }
                        .frame(width: 48, height: 48)
                        .cornerRadius(8)
                        .clipped()
                    }
                }
                .padding(.horizontal, 20)
            }

            // "Why it works" - full explanation, not truncated
            if !outfit.whyItWorks.isEmpty {
                Text(outfit.whyItWorks)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Expanded Content

    private func expandedContent(outfit: ScoredOutfit) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Item breakdown with roles
                VStack(alignment: .leading, spacing: 12) {
                    Text("THE PIECES")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(AppColors.textMuted)

                    ForEach(outfit.items ?? [], id: \.id) { item in
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: item.imageUrl ?? "")) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure, .empty:
                                    SkeletonBox(height: 56, width: 56, cornerRadius: 8)
                                @unknown default:
                                    SkeletonBox(height: 56, width: 56, cornerRadius: 8)
                                }
                            }
                            .frame(width: 56, height: 56)
                            .cornerRadius(8)
                            .clipped()

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.role.capitalized)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                                Text(item.itemName ?? item.category ?? "")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                            }

                            Spacer()
                        }
                    }
                }

                // Styling tip
                if let tip = outfit.stylingTip, !tip.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)

                        Text(tip)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                            .italic()
                    }
                    .padding(14)
                    .background(Color(hex: "FFFBEB"))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }

    // MARK: - Action Buttons

    private func actionButtons(outfit: ScoredOutfit) -> some View {
        VStack(spacing: 16) {
            // Outfit name - prominent
            Text(outfit.aiHeadline)
                .font(AppTypography.editorialTitle)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            // Weather context - subtle
            if let weather = outfitRepo.currentWeather {
                Text("Perfect for \(Int(weather.tempFahrenheit))° and \(weather.condition.lowercased())")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
            }

            // Buttons
            HStack(spacing: 12) {
                Button { skipOutfit() } label: {
                    Text("Skip")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "F5F5F5"))
                        .cornerRadius(12)
                }

                Button { wearOutfit() } label: {
                    Text("Wear This")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.textPrimary)
                        .cornerRadius(12)
                }
            }

            // Page dots
            HStack(spacing: 6) {
                ForEach(0..<outfits.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? AppColors.textPrimary : Color(hex: "E0E0E0"))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Gestures

    private var drawerGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation.height
                if drawerExpanded {
                    dragOffset = max(0, translation)
                } else {
                    dragOffset = min(0, translation)
                }
            }
            .onEnded { value in
                let threshold: CGFloat = 50

                if drawerExpanded && value.translation.height > threshold {
                    drawerExpanded = false
                } else if !drawerExpanded && value.translation.height < -threshold {
                    drawerExpanded = true
                }

                dragOffset = 0
            }
    }

    // MARK: - Actions

    private func shareOutfit(_ outfit: ScoredOutfit) {
        HapticManager.shared.light()

        // Get wardrobe items for the outfit
        let items: [WardrobeItem] = outfit.wardrobeItemIds.compactMap { itemId in
            wardrobeService.items.first { $0.id == itemId }
        }

        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        Task {
            await shareService.shareOutfit(
                outfit: outfit,
                items: items,
                occasion: outfit.occasion,
                from: rootVC
            )
        }
    }

    private func skipOutfit() {
        HapticManager.shared.light()
        if currentIndex < outfits.count - 1 {
            withAnimation { currentIndex += 1 }
        } else {
            if isInlineMode {
                outfitRepo.clearSessionOutfits()
            } else {
                dismiss()
            }
        }
    }

    private func wearOutfit() {
        HapticManager.shared.success()
        // Show confirmation view instead of immediate verification
        showWearConfirmation = true
    }

    // MARK: - Loading State (for inline mode while data syncs)

    private var loadingState: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading your looks...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(AppColors.textMuted)

            Text("No looks yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppColors.textPrimary)

            Button("Go back") { dismiss() }
                .foregroundColor(AppColors.textSecondary)
        }
    }

    // MARK: - Wear Handlers

    private func handleVerifiedWear(image: UIImage) {
        guard let outfit = currentOutfit else { return }

        Task {
            try? await outfitRepo.markAsWorn(outfit, photoUrl: nil)

            await MainActor.run {
                xpAmount = 25  // 10 base + 15 verify bonus
                isXPBonus = true
                showXPToast = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    if isInlineMode {
                        outfitRepo.clearSessionOutfits()
                    } else {
                        dismiss()
                    }
                }
            }
        }
    }

    private func handleUnverifiedWear() {
        guard let outfit = currentOutfit else { return }

        Task {
            try? await outfitRepo.markAsWorn(outfit)

            await MainActor.run {
                xpAmount = 10  // Base wear XP only
                isXPBonus = false
                showXPToast = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    if isInlineMode {
                        outfitRepo.clearSessionOutfits()
                    } else {
                        dismiss()
                    }
                }
            }
        }
    }

    /// Called when user confirms wearing the outfit (from WearConfirmationView)
    private func handleWearConfirmed() {
        guard let outfit = currentOutfit else { return }

        Task {
            // Mark as worn without photo (base XP)
            try? await outfitRepo.markAsWorn(outfit, photoUrl: nil)

            // Schedule verification reminder for 2-4 hours later
            scheduleVerificationReminder(for: outfit)

            await MainActor.run {
                xpAmount = 10  // Base wear XP
                isXPBonus = false
                showXPToast = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    if isInlineMode {
                        outfitRepo.clearSessionOutfits()
                    } else {
                        dismiss()
                    }
                }
            }
        }
    }

    /// Schedules a local notification to remind user to verify their outfit photo
    private func scheduleVerificationReminder(for outfit: ScoredOutfit) {
        let content = UNMutableNotificationContent()
        content.title = "Snap your look!"
        content.body = "Verify your outfit for +15 bonus XP"
        content.sound = .default

        // Schedule for 2-4 hours later (random for natural feel)
        let delay = Double.random(in: 7200...14400)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)

        let request = UNNotificationRequest(
            identifier: "verify-outfit-\(outfit.id)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[OutfitResults] Failed to schedule verification reminder: \(error)")
            } else {
                print("[OutfitResults] Verification reminder scheduled for \(Int(delay / 3600)) hours from now")
            }
        }
    }

    // MARK: - Regenerate

    private func regenerateOutfit(with feedback: FeedbackType) {
        guard let outfit = currentOutfit else { return }

        isRegenerating = true
        HapticManager.shared.medium()

        Task {
            if let newOutfit = await outfitRepo.regenerateWithFeedback(
                currentOutfit: outfit,
                feedback: feedback
            ) {
                await MainActor.run {
                    if currentIndex < outfitRepo.sessionOutfits.count {
                        outfitRepo.sessionOutfits[currentIndex] = newOutfit
                    } else if currentIndex < outfitRepo.preGeneratedOutfits.count {
                        outfitRepo.sessionOutfits = outfitRepo.preGeneratedOutfits
                        outfitRepo.sessionOutfits[currentIndex] = newOutfit
                    }
                    isSaved = false
                    isRegenerating = false
                }
            } else {
                await MainActor.run {
                    isRegenerating = false
                }
            }
        }
    }
}

#Preview {
    OutfitResultsView()
        .environment(AppCoordinator())
}
