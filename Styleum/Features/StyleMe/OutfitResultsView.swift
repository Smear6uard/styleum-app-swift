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

    // Animation state for staggered fade-in
    @State private var animateItems = false

    // MARK: - Item Categorization

    /// Selects the hero item - outerwear if present, otherwise top/dress
    private func selectHeroItem(from outfit: ScoredOutfit) -> OutfitItemRole? {
        let items = outfit.items ?? []
        let outerRoles = ["outerwear", "jacket", "coat", "blazer"]

        // Prefer statement outerwear as hero
        if let outer = items.first(where: { outerRoles.contains($0.role.lowercased()) }) {
            return outer
        }
        // Otherwise, top or dress
        return items.first(where: { ["top", "dress", "jumpsuit"].contains($0.role.lowercased()) })
    }

    /// Bottom item (pants, shorts, skirt)
    private func bottomItem(from outfit: ScoredOutfit) -> OutfitItemRole? {
        (outfit.items ?? []).first { $0.role.lowercased() == "bottom" }
    }

    /// Footwear item
    private func footwearItem(from outfit: ScoredOutfit) -> OutfitItemRole? {
        (outfit.items ?? []).first { $0.role.lowercased() == "footwear" }
    }

    /// Outerwear for row 2 (only if not used as hero)
    private func row2Outerwear(from outfit: ScoredOutfit, heroItem: OutfitItemRole?) -> OutfitItemRole? {
        let outerRoles = ["outerwear", "jacket", "coat", "blazer"]
        guard let outer = (outfit.items ?? []).first(where: { outerRoles.contains($0.role.lowercased()) }) else {
            return nil
        }
        // Don't show if it's already the hero
        return outer.id == heroItem?.id ? nil : outer
    }

    /// Accessory items shown as thumbnails
    private func accessoryItems(for outfit: ScoredOutfit) -> [OutfitItemRole] {
        let primaryRoles = ["top", "bottom", "outerwear", "footwear", "jacket", "coat", "sweater", "dress", "jumpsuit"]
        return (outfit.items ?? []).filter { item in
            !primaryRoles.contains(item.role.lowercased())
        }
    }

    /// Primary items for legacy stacked view (fallback)
    private func primaryItems(for outfit: ScoredOutfit) -> [OutfitItemRole] {
        let primaryRoles = ["top", "bottom", "outerwear", "footwear", "jacket", "coat", "sweater", "dress", "jumpsuit"]
        return (outfit.items ?? []).filter { item in
            primaryRoles.contains(item.role.lowercased())
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
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

    // MARK: - Outfit Card (Full-Screen Editorial Grid)

    private func outfitCard(_ outfit: ScoredOutfit, geometry: GeometryProxy) -> some View {
        let heroItem = selectHeroItem(from: outfit)
        let bottom = bottomItem(from: outfit)
        let footwear = footwearItem(from: outfit)
        let outerwear = row2Outerwear(from: outfit, heroItem: heroItem)
        let accessories = accessoryItems(for: outfit)
        let hasRow2 = outerwear != nil || !accessories.isEmpty

        return ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Top spacing for floating bar
                Spacer().frame(height: 100)

                // MARK: - Editorial Header
                outfitHeader(outfit)
                    .padding(.bottom, 20)

                // MARK: - Hero Piece (40% height)
                if let hero = heroItem {
                    OutfitItemCard(item: hero, size: .hero)
                        .frame(height: geometry.size.height * 0.38)
                        .padding(.horizontal, 24)
                        .opacity(animateItems ? 1 : 0)
                        .scaleEffect(animateItems ? 1 : 0.95)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: animateItems)
                }

                // MARK: - Row 1: Core Pieces (Bottom + Footwear)
                HStack(spacing: 12) {
                    if let bottomItem = bottom {
                        OutfitItemCard(item: bottomItem, size: .medium)
                            .opacity(animateItems ? 1 : 0)
                            .scaleEffect(animateItems ? 1 : 0.95)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: animateItems)
                    }
                    if let footwearItem = footwear {
                        OutfitItemCard(item: footwearItem, size: .medium)
                            .opacity(animateItems ? 1 : 0)
                            .scaleEffect(animateItems ? 1 : 0.95)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25), value: animateItems)
                    }
                }
                .frame(height: geometry.size.height * 0.18)
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // MARK: - Row 2: Optional (Outerwear + Accessories)
                if hasRow2 {
                    optionalRow2(outerwear: outerwear, accessories: accessories)
                        .padding(.top, 16)
                        .opacity(animateItems ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35), value: animateItems)
                }

                // MARK: - Outfit Info
                outfitInfoSection(outfit)
                    .padding(.top, 24)
                    .padding(.horizontal, 24)

                // MARK: - Action Buttons
                actionButtons(outfit: outfit)
                    .padding(.top, 24)
                    .padding(.horizontal, 24)

                // Page indicator
                pageIndicator
                    .padding(.top, 16)
                    .padding(.bottom, 40)
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

    // MARK: - Optional Row 2 (Outerwear + Accessories)

    private func optionalRow2(outerwear: OutfitItemRole?, accessories: [OutfitItemRole]) -> some View {
        HStack(spacing: 12) {
            if let outer = outerwear {
                OutfitItemCard(item: outer, size: .medium)
                    .frame(maxWidth: accessories.isEmpty ? .infinity : nil)
            }

            if !accessories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(accessories.prefix(4), id: \.id) { accessory in
                            OutfitItemCard(item: accessory, size: .small)
                                .frame(width: 72, height: 72)
                        }
                        if accessories.count > 4 {
                            Text("+\(accessories.count - 4)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                                .frame(width: 40, height: 72)
                        }
                    }
                }
            }
        }
        .frame(height: outerwear != nil ? 100 : 72)
        .padding(.horizontal, 24)
    }

    // MARK: - Editorial Header

    private func outfitHeader(_ outfit: ScoredOutfit) -> some View {
        VStack(spacing: 6) {
            Text(outfit.aiHeadline)
                .font(AppTypography.editorialSubhead)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                if let vibe = outfit.vibe ?? outfit.vibes.first {
                    Text(vibe.capitalized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
                Text("·")
                    .foregroundColor(AppColors.textMuted)
                Text("\(outfit.score)% match")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Stacked Items View

    private func stackedItemsView(items: [OutfitItemRole], geometry: GeometryProxy) -> some View {
        let itemCount = items.count
        let baseHeight: CGFloat = 140
        let overlapOffset: CGFloat = 100

        return ZStack(alignment: .top) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                itemCard(item, width: geometry.size.width - 48 - CGFloat(index * 16))
                    .offset(y: CGFloat(index) * overlapOffset)
                    .zIndex(Double(itemCount - index))
            }
        }
        .frame(height: CGFloat(itemCount) * overlapOffset + baseHeight)
    }

    private func itemCard(_ item: OutfitItemRole, width: CGFloat) -> some View {
        VStack(spacing: 0) {
            AsyncImage(url: URL(string: item.imageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    Rectangle()
                        .fill(Color(hex: "F0F0F0"))
                        .overlay(
                            Image(systemName: "tshirt")
                                .font(.system(size: 24))
                                .foregroundColor(Color(hex: "CCCCCC"))
                        )
                @unknown default:
                    Rectangle().fill(Color(hex: "F0F0F0"))
                }
            }
            .frame(width: width, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
    }

    // MARK: - Accessories Row

    private func accessoriesRow(_ items: [OutfitItemRole]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACCESSORIES")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundColor(AppColors.textMuted)
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items, id: \.id) { item in
                        VStack(spacing: 6) {
                            AsyncImage(url: URL(string: item.imageUrl ?? "")) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure, .empty:
                                    Rectangle()
                                        .fill(Color(hex: "F0F0F0"))
                                @unknown default:
                                    Rectangle().fill(Color(hex: "F0F0F0"))
                                }
                            }
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)

                            Text(item.role.capitalized)
                                .font(.system(size: 11))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Outfit Info Section

    private func outfitInfoSection(_ outfit: ScoredOutfit) -> some View {
        VStack(spacing: 16) {
            // Headline
            Text(outfit.aiHeadline)
                .font(AppTypography.editorialTitle)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            // Weather context
            if let weather = outfitRepo.currentWeather {
                HStack(spacing: 6) {
                    Image(systemName: weatherIcon(for: weather.condition))
                        .font(.system(size: 14))
                    Text("\(Int(weather.tempFahrenheit))° and \(weather.condition.lowercased())")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
            }

            // Why it works
            if !outfit.whyItWorks.isEmpty {
                Text(outfit.whyItWorks)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Styling tip - editorial design
            if let tip = outfit.stylingTip, !tip.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("STYLING TIP")
                        .font(.system(size: 10, weight: .medium))
                        .tracking(1.2)
                        .foregroundColor(Color(hex: "94A3B8"))

                    Text(tip)
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                }
                .padding(.top, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color(hex: "E2E8F0"))
                        .frame(height: 1)
                }
            }

            // Color harmony - editorial design
            if let harmony = outfit.colorHarmony, !harmony.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("COLOR PALETTE")
                        .font(.system(size: 10, weight: .medium))
                        .tracking(1.2)
                        .foregroundColor(Color(hex: "94A3B8"))

                    Text(harmony)
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                }
                .padding(.top, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color(hex: "E2E8F0"))
                        .frame(height: 1)
                }
            }
        }
    }

    private func weatherIcon(for condition: String) -> String {
        let lowered = condition.lowercased()
        if lowered.contains("sun") || lowered.contains("clear") { return "sun.max.fill" }
        if lowered.contains("cloud") { return "cloud.fill" }
        if lowered.contains("rain") { return "cloud.rain.fill" }
        if lowered.contains("snow") { return "snowflake" }
        if lowered.contains("wind") { return "wind" }
        return "cloud.sun.fill"
    }

    // MARK: - Action Buttons

    private func actionButtons(outfit: ScoredOutfit) -> some View {
        VStack(spacing: 12) {
            // Primary: Wear This
            Button { wearOutfit() } label: {
                Text("Wear This")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.textPrimary)
                    .cornerRadius(AppSpacing.radiusLg)
            }

            // Secondary actions row
            HStack(spacing: 12) {
                Button { skipOutfit() } label: {
                    Text(isLastOutfit ? "Done" : "Skip")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(AppSpacing.radiusMd)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                                .stroke(Color(hex: "E0E0E0"), lineWidth: 1)
                        )
                }

                Button { showRegenerateSheet = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                        Text("Refresh")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(AppSpacing.radiusMd)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.radiusMd)
                            .stroke(Color(hex: "E0E0E0"), lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<outfits.count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? AppColors.textPrimary : Color(hex: "E0E0E0"))
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Floating Top Bar

    private var floatingTopBar: some View {
        HStack {
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

            if !outfits.isEmpty {
                Text("\(currentIndex + 1) / \(outfits.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(AppSpacing.radiusXl)
            }

            Spacer()

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
                .foregroundColor(AppColors.textMuted)
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
