import SwiftUI

/// Direction-based collapse for pinned top chrome: scrolling down hides the
/// title row, scrolling up (or returning near the top) shows it again.
struct MegrumTopChromeCollapseTracker {
    private var baselineContentTop: CGFloat?
    private var lastContentTop: CGFloat?

    /// Distance from the resting position within which the chrome always
    /// stays expanded.
    static let expandNearTopThreshold: CGFloat = 40
    static let collapseDelta: CGFloat = -4
    static let expandDelta: CGFloat = 4
    /// Per-sample movement beyond this is a layout event (deferred content
    /// swapping in, rotation, inset changes), not a user scroll: rebaseline
    /// instead of collapsing.
    static let layoutJumpThreshold: CGFloat = 80

    mutating func updatedCollapsedState(contentTop: CGFloat, isCollapsed: Bool) -> Bool {
        guard let lastContentTop, let baselineContentTop else {
            self.baselineContentTop = contentTop
            self.lastContentTop = contentTop
            return false
        }
        let delta = contentTop - lastContentTop
        self.lastContentTop = contentTop
        if abs(delta) > Self.layoutJumpThreshold {
            self.baselineContentTop = contentTop
            return false
        }
        if contentTop >= baselineContentTop - Self.expandNearTopThreshold {
            return false
        }
        if delta <= Self.collapseDelta {
            return true
        }
        if delta >= Self.expandDelta {
            return false
        }
        return isCollapsed
    }

    mutating func reset() {
        baselineContentTop = nil
        lastContentTop = nil
    }
}

enum MegrumTopChromeCollapseAnimation {
    static let animation: Animation = .snappy(duration: 0.25)

    static var titleTransition: AnyTransition {
        .move(edge: .top).combined(with: .opacity)
    }
}

struct MegrumScrollContentTopPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat { .greatestFiniteMagnitude }

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}

enum MegrumScrollContentTopSpace {
    /// Shared named coordinate space attached to scroll views whose content
    /// reports its top for chrome collapsing. Measuring in the scroll view's
    /// own space (instead of global) makes the signal immune to container
    /// animations — tab transitions, slide-ins, deferred layout — so only
    /// genuine user scrolling moves it.
    static let name = "megrum-collapse-scroll"
}

extension View {
    /// Attach to scroll CONTENT: publishes the content's top Y in the named
    /// coordinate space through `MegrumScrollContentTopPreferenceKey`. The
    /// enclosing ScrollView must declare `.coordinateSpace(name:)` with the
    /// same name; read the value with `onPreferenceChange` inside the same
    /// hosting root.
    func megrumReportsScrollContentTop(in coordinateSpaceName: String = MegrumScrollContentTopSpace.name) -> some View {
        background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: MegrumScrollContentTopPreferenceKey.self,
                    value: geometry.frame(in: .named(coordinateSpaceName)).minY
                )
            }
        }
    }
}

/// Hosts scroll content plus a pinned header whose collapse state lives in
/// THIS view: toggling it re-renders only the header, not the (potentially
/// expensive) content passed in by the parent.
struct MegrumCollapsingTopChromeContainer<Content: View, Chrome: View>: View {
    @State private var isCollapsed = false
    @State private var tracker = MegrumTopChromeCollapseTracker()

    private let content: Content
    private let chrome: (_ isCollapsed: Bool) -> Chrome

    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder chrome: @escaping (_ isCollapsed: Bool) -> Chrome
    ) {
        self.content = content()
        self.chrome = chrome
    }

    var body: some View {
        ZStack(alignment: .top) {
            content

            chrome(isCollapsed)
        }
        .onPreferenceChange(MegrumScrollContentTopPreferenceKey.self) { contentTop in
            MainActor.assumeIsolated {
                handleScrollContentTop(contentTop)
            }
        }
    }

    private func handleScrollContentTop(_ contentTop: CGFloat) {
        let newValue = tracker.updatedCollapsedState(
            contentTop: contentTop,
            isCollapsed: isCollapsed
        )
        guard newValue != isCollapsed else {
            return
        }
        withAnimation(MegrumTopChromeCollapseAnimation.animation) {
            isCollapsed = newValue
        }
    }
}
