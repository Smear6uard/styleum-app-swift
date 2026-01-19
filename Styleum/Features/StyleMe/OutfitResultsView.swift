import SwiftUI
import UIKit
import UserNotifications

struct OutfitResultsView: View {
    /// When true, view is displayed inline (StyleMeScreen). When false, displayed as modal (HomeScreen fullScreenCover).
    var isInlineMode: Bool = false

    @Environment(\.dismiss) private var dismiss
    @Environment(AppCoordinator.self) private var coordinator
    private let wardrobeService = WardrobeService.shared
    private let outfitRepo = OutfitRepository.shared
    private let shareService = ShareService.shared
    private let tierManager = TierManager.shared

    @State private var currentIndex = 0
    @State private var isSaved = false
    @State private var isRegenerating = false

    // Sheet states
    @State private var showVerifySheet = false
    @State private var showWearConfirmation = false
    @State private var showRegenerateSheet = false
    @State private var showProPaywall = false

    // XP Toast
    @State private var showXPToast = false
    @State private var xpAmount = 0
    @State private var isXPBonus = false

    // Error handling
    @State private var showWearError = false
    @State private var wearErrorMessage = ""

    // Animation state
    @State private var animateItems = false

    // User preferences
    @AppStorage("temperatureUnit") private var temperatureUnit = "fahrenheit"

    private var outfits: [ScoredOutfit] {
        // In inline mode (StyleMeScreen), read sessionOutfits directly to ensure proper observation
        // In modal mode (HomeScreen), use todaysOutfits which has fallback logic
        isInlineMode ? outfitRepo.sessionOutfits : outfitRepo.todaysOutfits
    }
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

    private var isLastOutfit: Bool {
        currentIndex >= outfits.count - 1
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - light cream
                Color(hex: "FAFAF8").ignoresSafeArea()

                if isInlineMode && outfits.isEmpty {
                    loadingState
                } else if currentOutfit != nil {
                    // MARK: - Full Screen Paging
                    TabView(selection: $currentIndex) {
                        ForEach(Array(outfits.enumerated()), id: \.offset) { index, outfit in
                            if !tierManager.isPro && index >= unlockedOutfitCount {
                                lockedOutfitCard(outfit, geometry: geometry)
                                    .tag(index)
                            } else {
                                outfitCard(outfit, geometry: geometry)
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea()

                    // Floating top bar
                    VStack {
                        floatingTopBar
                        Spacer()
                    }
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
                    onVerify: { image in handleVerifiedWear(image: image) },
                    onSkip: { handleUnverifiedWear() }
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
                    onCancel: { showWearConfirmation = false }
                )
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showRegenerateSheet) {
            if let outfit = currentOutfit {
                RegenerateSheet(
                    currentOutfit: outfit,
                    isPro: tierManager.isPro,
                    onRegenerate: { feedback in regenerateOutfit(with: feedback) },
                    onUpgrade: { coordinator.navigate(to: .subscription) }
                )
            }
        }
        .sheet(isPresented: $showProPaywall) {
            ProUpgradeView(trigger: .lockedOutfits)
        }
        .alert("Couldn't Save Your Progress", isPresented: $showWearError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(wearErrorMessage.isEmpty ? "Please try again." : wearErrorMessage)
        }
        .onChange(of: currentIndex) { _, _ in
            isSaved = false
            HapticManager.shared.selection()
        }
        .onChange(of: outfits.count) { oldCount, newCount in
            // Reset carousel index when outfits are regenerated to prevent index out of bounds
            if newCount > 0 && currentIndex >= newCount {
                currentIndex = 0
            }
        }
    }

    // MARK: - Item Categorization

    /// Picks outerwear or top/dress as hero item
    private func selectHeroItem(from outfit: ScoredOutfit) -> OutfitItemRole? {
        let items = outfit.items ?? []
        // Prefer outerwear as hero if present
        if let outerwear = items.first(where: { ["outerwear", "jacket", "coat", "blazer"].contains($0.role.lowercased()) }) {
            return outerwear
        }
        // Otherwise use top or dress
        return items.first(where: { ["top", "shirt", "blouse", "sweater", "dress", "jumpsuit"].contains($0.role.lowercased()) })
    }

    /// Returns bottom item (pants, shorts, skirt)
    private func bottomItem(from outfit: ScoredOutfit) -> OutfitItemRole? {
        let items = outfit.items ?? []
        return items.first(where: { ["bottom", "pants", "shorts", "skirt", "jeans"].contains($0.role.lowercased()) })
    }

    /// Returns footwear item
    private func footwearItem(from outfit: ScoredOutfit) -> OutfitItemRole? {
        let items = outfit.items ?? []
        return items.first(where: { ["footwear", "shoes", "sneakers", "boots", "heels"].contains($0.role.lowercased()) })
    }

    /// Returns outerwear if it's not already the hero
    private func row2Outerwear(from outfit: ScoredOutfit, heroItem: OutfitItemRole?) -> OutfitItemRole? {
        let items = outfit.items ?? []
        let outerwear = items.first(where: { ["outerwear", "jacket", "coat", "blazer"].contains($0.role.lowercased()) })
        // Only return if different from hero
        if let outerwear = outerwear, outerwear.id != heroItem?.id {
            return outerwear
        }
        return nil
    }

    /// Returns accessory items (non-primary)
    private func accessoryItems(for outfit: ScoredOutfit) -> [OutfitItemRole] {
        let items = outfit.items ?? []
        let primaryRoles = ["top", "bottom", "outerwear", "footwear", "jacket", "coat", "sweater", "dress", "jumpsuit", "pants", "shorts", "skirt", "jeans", "shirt", "blouse", "shoes", "sneakers", "boots", "heels", "blazer"]
        return items.filter { !primaryRoles.contains($0.role.lowercased()) }
    }

    /// Primary items for locked outfit display
    private func primaryItems(for outfit: ScoredOutfit) -> [OutfitItemRole] {
        let primaryRoles = ["top", "bottom", "outerwear", "footwear", "jacket", "coat", "sweater", "dress", "jumpsuit"]
        return (outfit.items ?? []).filter { item in
            primaryRoles.contains(item.role.lowercased())
        }
    }

    // MARK: - Outfit Card (Light Editorial Layout)

    private func outfitCard(_ outfit: ScoredOutfit, geometry: GeometryProxy) -> some View {
        let heroItem = selectHeroItem(from: outfit)
        let bottom = bottomItem(from: outfit)
        let footwear = footwearItem(from: outfit)
        let outerwear = row2Outerwear(from: outfit, heroItem: heroItem)
        let accessories = accessoryItems(for: outfit)

        return ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Top spacing for floating bar
                Spacer().frame(height: 100)

                // Editorial header
                outfitHeader(outfit)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 24)

                // Hero item (38% of screen height)
                if let hero = heroItem {
                    OutfitItemCard(item: hero, size: .hero)
                        .frame(height: geometry.size.height * 0.38)
                        .padding(.horizontal, 24)
                        .opacity(animateItems ? 1 : 0)
                        .scaleEffect(animateItems ? 1 : 0.96)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: animateItems)
                }

                Spacer().frame(height: 16)

                // Row 1: Bottom + Footwear
                HStack(spacing: 12) {
                    if let bottom = bottom {
                        OutfitItemCard(item: bottom, size: .medium)
                            .frame(height: 140)
                    }
                    if let footwear = footwear {
                        OutfitItemCard(item: footwear, size: .medium)
                            .frame(height: 140)
                    }
                }
                .padding(.horizontal, 24)
                .opacity(animateItems ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: animateItems)

                // Row 2: Outerwear (if not hero) + Accessories
                if outerwear != nil || !accessories.isEmpty {
                    Spacer().frame(height: 12)

                    HStack(spacing: 12) {
                        if let outerwear = outerwear {
                            OutfitItemCard(item: outerwear, size: .medium)
                                .frame(height: 120)
                        }
                        ForEach(accessories.prefix(2), id: \.id) { accessory in
                            OutfitItemCard(item: accessory, size: .small)
                                .frame(width: 80, height: 80)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .opacity(animateItems ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: animateItems)
                }

                Spacer().frame(height: 24)

                // Outfit info section
                outfitInfoSection(outfit)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 24)

                // Action buttons
                actionButtons(outfit: outfit)
                    .padding(.horizontal, 24)

                // Page indicator
                if outfits.count > 1 {
                    Spacer().frame(height: 20)
                    pageIndicator
                }

                Spacer().frame(height: 40)
            }
        }
        .onAppear {
            animateItems = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation { animateItems = true }
            }
        }
        .contextMenu {
            Button { shareOutfit(outfit) } label: {
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
            Button { wearOutfit() } label: {
                Label("Wear This", systemImage: "checkmark.circle")
            }
            Divider()
            Button { showRegenerateSheet = true } label: {
                Label("Regenerate", systemImage: "arrow.clockwise")
            }
        }
    }

    // MARK: - Outfit Header

    private func outfitHeader(_ outfit: ScoredOutfit) -> some View {
        VStack(spacing: 8) {
            // Outfit name (all caps, tracked, bolder)
            Text(outfit.aiHeadline.uppercased())
                .font(.system(size: 20, weight: .bold))
                .tracking(3)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Match score and vibe
            HStack(spacing: 8) {
                Text("\(outfit.score)% match")
                Text("\u{00B7}")
                Text(outfit.vibe ?? outfit.vibes.first?.lowercased() ?? "styled")
            }
            .font(.system(size: 12))
            .foregroundColor(AppColors.textSecondary)

            // Weather context
            if let weather = outfitRepo.currentWeather ?? outfitRepo.preGeneratedWeather {
                Text("\(weather.formattedTemperature(unit: temperatureUnit)) and \(weather.condition.lowercased())")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }

    // MARK: - Outfit Info Section

    private func outfitInfoSection(_ outfit: ScoredOutfit) -> some View {
        VStack(spacing: 12) {
            // Why it works description
            if let explanation = outfit.whyItWorks.ifMeaningful {
                Text(explanation)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textPrimary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }

            // Styling tip with arrow prefix (NOT boxed)
            if let tip = outfit.stylingTip?.ifMeaningful {
                Text("\u{2192} \(tip)")
                    .font(.system(size: 14).italic())
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }
        }
    }

    // MARK: - Action Buttons

    private func actionButtons(outfit: ScoredOutfit) -> some View {
        VStack(spacing: 12) {
            // Primary: WEAR THIS - Dark filled button
            Button { wearOutfit() } label: {
                Text("WEAR THIS")
                    .font(.system(size: 14, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(AppColors.textPrimary)
                    .cornerRadius(12)
            }
            .buttonStyle(ScaleButtonStyle())

            // Secondary: SHARE LOOK - White outlined button
            Button { shareOutfit(outfit) } label: {
                Text("SHARE LOOK")
                    .font(.system(size: 14, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.textPrimary, lineWidth: 1.5)
                    )
            }

            // Tertiary: Skip | Refresh
            HStack(spacing: 24) {
                Button { skipOutfit() } label: {
                    Text(isLastOutfit ? "Done" : "Skip")
                }

                Button { showRegenerateSheet = true } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Color(hex: "666666"))
        }
    }

    // MARK: - Page Indicator (Light Theme)

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<outfits.count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? AppColors.textPrimary : Color(hex: "E0E0E0"))
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Floating Top Bar (Light Style)

    private var floatingTopBar: some View {
        HStack {
            // X button - dark on light background
            Button {
                HapticManager.shared.light()
                if isInlineMode {
                    outfitRepo.clearSessionOutfits()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close")
            .accessibilityHint(isInlineMode ? "Returns to Style Me screen" : "Dismisses outfit view")

            Spacer()

            // Page counter
            if !outfits.isEmpty {
                Text("\(currentIndex + 1) / \(outfits.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
            }

            Spacer()

            // Heart button
            Button {
                HapticManager.shared.medium()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isSaved.toggle()
                }
                if isSaved {
                    GamificationService.shared.awardXP(2, reason: .outfitLiked)
                }
            } label: {
                Image(systemName: isSaved ? "heart.fill" : "heart")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isSaved ? .red : AppColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .symbolEffect(.bounce, value: isSaved)
            }
            .accessibilityLabel(isSaved ? "Unlike outfit" : "Like outfit")
            .accessibilityHint("Double tap to \(isSaved ? "remove from" : "add to") your liked outfits")
        }
        .padding(.horizontal, 20)
        .padding(.top, 54)
    }

    // MARK: - Locked Outfit Card

    private func lockedOutfitCard(_ outfit: ScoredOutfit, geometry: GeometryProxy) -> some View {
        VStack {
            Spacer().frame(height: 120)

            LockedOutfitCard(
                imageURL: URL(string: primaryItems(for: outfit).first?.imageUrl ?? ""),
                onUnlock: { showProPaywall = true }
            )
            .frame(maxWidth: geometry.size.width - 48)
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Loading & Empty States

    private var loadingState: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(AppColors.textSecondary)
            Text("Loading your looks...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
            Text("No looks yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
            Button("Go back") { dismiss() }
                .foregroundColor(AppColors.textSecondary)
        }
    }

    // MARK: - Actions

    private func shareOutfit(_ outfit: ScoredOutfit) {
        HapticManager.shared.light()
        let items: [WardrobeItem] = outfit.wardrobeItemIds.compactMap { itemId in
            wardrobeService.items.first { $0.id == itemId }
        }
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        Task {
            await shareService.shareOutfit(outfit: outfit, items: items, occasion: outfit.occasion, from: rootVC)
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
        showWearConfirmation = true
    }

    // MARK: - Wear Handlers

    private func handleVerifiedWear(image: UIImage) {
        guard let outfit = currentOutfit else { return }
        Task {
            do {
                try await outfitRepo.markAsWorn(outfit, photoUrl: nil)
                await MainActor.run {
                    xpAmount = 25
                    isXPBonus = true
                    showXPToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        if isInlineMode { outfitRepo.clearSessionOutfits() } else { dismiss() }
                    }
                }
            } catch {
                await MainActor.run {
                    wearErrorMessage = error.localizedDescription
                    showWearError = true
                    HapticManager.shared.error()
                }
            }
        }
    }

    private func handleUnverifiedWear() {
        guard let outfit = currentOutfit else { return }
        Task {
            do {
                try await outfitRepo.markAsWorn(outfit)
                await MainActor.run {
                    xpAmount = 10
                    isXPBonus = false
                    showXPToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        if isInlineMode { outfitRepo.clearSessionOutfits() } else { dismiss() }
                    }
                }
            } catch {
                await MainActor.run {
                    wearErrorMessage = error.localizedDescription
                    showWearError = true
                    HapticManager.shared.error()
                }
            }
        }
    }

    private func handleWearConfirmed() {
        guard let outfit = currentOutfit else { return }
        Task {
            do {
                try await outfitRepo.markAsWorn(outfit, photoUrl: nil)
                scheduleVerificationReminder(for: outfit)
                await MainActor.run {
                    xpAmount = 10
                    isXPBonus = false
                    showXPToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        if isInlineMode { outfitRepo.clearSessionOutfits() } else { dismiss() }
                    }
                }
            } catch {
                await MainActor.run {
                    wearErrorMessage = error.localizedDescription
                    showWearError = true
                    HapticManager.shared.error()
                }
            }
        }
    }

    private func scheduleVerificationReminder(for outfit: ScoredOutfit) {
        let content = UNMutableNotificationContent()
        content.title = "Snap your look!"
        content.body = "Verify your outfit for +15 bonus XP"
        content.sound = .default

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
            }
        }
    }

    // MARK: - Regenerate

    private func regenerateOutfit(with feedback: FeedbackType) {
        guard let outfit = currentOutfit else { return }
        isRegenerating = true
        HapticManager.shared.medium()

        Task {
            if let newOutfit = await outfitRepo.regenerateWithFeedback(currentOutfit: outfit, feedback: feedback) {
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
                await MainActor.run { isRegenerating = false }
            }
        }
    }
}

#Preview {
    OutfitResultsView()
        .environment(AppCoordinator())
}
