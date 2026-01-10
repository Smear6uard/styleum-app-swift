//
//  View+ScrollEffects.swift
//  Styleum
//
//  Scroll-linked animation utilities for premium motion design
//

import SwiftUI

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Scroll Offset Reader

/// A view that reports its scroll offset within a named coordinate space
struct ScrollOffsetReader: View {
    let coordinateSpace: String

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named(coordinateSpace)).minY
                )
        }
        .frame(height: 0)
    }
}

// MARK: - Scroll-Linked Header Modifier

/// Applies blur and fade effect to a header based on scroll position
struct ScrollLinkedHeaderModifier: ViewModifier {
    let scrollOffset: CGFloat
    let blurThreshold: CGFloat
    let fadeThreshold: CGFloat
    let maxBlur: CGFloat

    init(
        scrollOffset: CGFloat,
        blurThreshold: CGFloat = 50,
        fadeThreshold: CGFloat = 150,
        maxBlur: CGFloat = 8
    ) {
        self.scrollOffset = scrollOffset
        self.blurThreshold = blurThreshold
        self.fadeThreshold = fadeThreshold
        self.maxBlur = maxBlur
    }

    func body(content: Content) -> some View {
        let normalizedOffset = max(0, -scrollOffset)

        // Calculate blur amount (starts after threshold)
        let blurAmount = min(maxBlur, normalizedOffset / blurThreshold * maxBlur)

        // Calculate opacity (fades out as you scroll)
        let opacity = max(0.3, 1 - (normalizedOffset / fadeThreshold * 0.7))

        content
            .blur(radius: blurAmount)
            .opacity(opacity)
    }
}

// MARK: - Progressive Reveal Modifier

/// Reveals content with fade and slide as it enters the viewport
struct ProgressiveRevealModifier: ViewModifier {
    let delay: Double
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

// MARK: - Parallax Modifier

/// Applies parallax offset based on scroll position
struct ParallaxModifier: ViewModifier {
    let scrollOffset: CGFloat
    let rate: CGFloat // How much slower/faster than scroll (0.5 = half speed)
    let baseOffset: CGFloat

    init(scrollOffset: CGFloat, rate: CGFloat = 0.3, baseOffset: CGFloat = 0) {
        self.scrollOffset = scrollOffset
        self.rate = rate
        self.baseOffset = baseOffset
    }

    func body(content: Content) -> some View {
        let parallaxOffset = (scrollOffset - baseOffset) * rate
        content.offset(y: parallaxOffset)
    }
}

// MARK: - Scroll-Based Scale Modifier

/// Scales content based on scroll position (useful for hero images)
struct ScrollScaleModifier: ViewModifier {
    let scrollOffset: CGFloat
    let scaleRate: CGFloat

    init(scrollOffset: CGFloat, scaleRate: CGFloat = 0.0005) {
        self.scrollOffset = scrollOffset
        self.scaleRate = scaleRate
    }

    func body(content: Content) -> some View {
        // Scale up slightly as you scroll down (pull-to-refresh style)
        let scale = 1 + max(0, scrollOffset) * scaleRate
        content.scaleEffect(scale, anchor: .top)
    }
}

// MARK: - Depth Shadow Modifier

/// Applies dynamic shadow based on scroll position
struct ScrollDepthShadowModifier: ViewModifier {
    let scrollOffset: CGFloat
    let baseOpacity: CGFloat
    let baseRadius: CGFloat
    let baseY: CGFloat

    init(
        scrollOffset: CGFloat,
        baseOpacity: CGFloat = 0.06,
        baseRadius: CGFloat = 8,
        baseY: CGFloat = 2
    ) {
        self.scrollOffset = scrollOffset
        self.baseOpacity = baseOpacity
        self.baseRadius = baseRadius
        self.baseY = baseY
    }

    func body(content: Content) -> some View {
        let normalizedOffset = max(0, -scrollOffset)
        let depthMultiplier = 1 + normalizedOffset * 0.002

        content
            .shadow(
                color: .black.opacity(baseOpacity * depthMultiplier),
                radius: baseRadius * depthMultiplier,
                y: baseY * depthMultiplier
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Applies scroll-linked blur and fade effect for headers
    func scrollLinkedHeader(
        scrollOffset: CGFloat,
        blurThreshold: CGFloat = 50,
        fadeThreshold: CGFloat = 150
    ) -> some View {
        modifier(ScrollLinkedHeaderModifier(
            scrollOffset: scrollOffset,
            blurThreshold: blurThreshold,
            fadeThreshold: fadeThreshold
        ))
    }

    /// Reveals content with a spring animation when it appears
    func progressiveReveal(delay: Double = 0) -> some View {
        modifier(ProgressiveRevealModifier(delay: delay))
    }

    /// Applies parallax effect based on scroll offset
    func parallax(scrollOffset: CGFloat, rate: CGFloat = 0.3, baseOffset: CGFloat = 0) -> some View {
        modifier(ParallaxModifier(scrollOffset: scrollOffset, rate: rate, baseOffset: baseOffset))
    }

    /// Applies scroll-based scale effect
    func scrollScale(scrollOffset: CGFloat, rate: CGFloat = 0.0005) -> some View {
        modifier(ScrollScaleModifier(scrollOffset: scrollOffset, scaleRate: rate))
    }

    /// Applies dynamic depth shadow based on scroll position
    func scrollDepthShadow(scrollOffset: CGFloat) -> some View {
        modifier(ScrollDepthShadowModifier(scrollOffset: scrollOffset))
    }
}

// MARK: - Tab Transition Modifier

/// Applies smooth scale, blur, and opacity transition for tab switching
struct TabTransitionModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .scaleEffect(isActive ? 1 : 0.98)
            .blur(radius: isActive ? 0 : 2)
            .allowsHitTesting(isActive)
    }
}

extension View {
    /// Applies tab transition effect (opacity, scale, blur)
    func tabTransition(isActive: Bool) -> some View {
        modifier(TabTransitionModifier(isActive: isActive))
    }
}

// MARK: - Scroll Container with Offset Tracking

/// A ScrollView wrapper that tracks scroll offset
struct TrackableScrollView<Content: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    @Binding var scrollOffset: CGFloat
    let content: Content

    private let coordinateSpaceName = "trackableScroll"

    init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        scrollOffset: Binding<CGFloat>,
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self._scrollOffset = scrollOffset
        self.content = content()
    }

    var body: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            VStack(spacing: 0) {
                ScrollOffsetReader(coordinateSpace: coordinateSpaceName)
                content
            }
        }
        .coordinateSpace(name: coordinateSpaceName)
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
    }
}
