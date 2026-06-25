import MegrumDesign
import SwiftUI

struct HomeDiscoveryTabSwitcher: View {
    @Binding var selection: HomeDiscoveryPrimaryTab
    var swipeProgress: CGFloat

    var body: some View {
        HStack(alignment: .bottom, spacing: HomeDiscoveryTabSwitcherMetrics.itemSpacing) {
            ForEach(HomeDiscoveryPrimaryTab.allCases) { tab in
                Button {
                    select(tab)
                } label: {
                    HomeDiscoveryTabSwitcherItem(
                        tab: tab,
                        isSelected: selection == tab
                    )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .anchorPreference(
                    key: HomeDiscoveryTabFramePreferenceKey.self,
                    value: .bounds
                ) { anchor in
                    [tab: anchor]
                }
                .contentShape(Rectangle())
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, HomeDiscoveryTabSwitcherMetrics.horizontalPadding)
        .padding(.top, HomeDiscoveryTabSwitcherMetrics.topPadding)
        .padding(.bottom, HomeDiscoveryTabSwitcherMetrics.totalBottomPadding)
        .overlayPreferenceValue(HomeDiscoveryTabFramePreferenceKey.self) { anchors in
            GeometryReader { proxy in
                let frames = anchors.mapValues { proxy[$0] }
                if let indicator = HomeDiscoveryTabIndicatorFrame.interpolated(
                    progress: swipeProgress,
                    frames: frames
                ) {
                    Capsule(style: .continuous)
                        .fill(MegrumTheme.lavender)
                        .frame(
                            width: indicator.width,
                            height: HomeDiscoveryTabSwitcherMetrics.underlineHeight
                        )
                        .offset(
                            x: indicator.minX,
                            y: proxy.size.height
                                - HomeDiscoveryTabSwitcherMetrics.bottomPadding
                                - HomeDiscoveryTabSwitcherMetrics.underlineHeight
                        )
                        .animation(
                            .snappy(duration: HomeDiscoveryTabSwitcherMetrics.selectionAnimationDuration),
                            value: selection
                        )
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func select(_ tab: HomeDiscoveryPrimaryTab) {
        guard selection != tab else {
            return
        }
        withAnimation(.snappy(duration: HomeDiscoveryTabSwitcherMetrics.selectionAnimationDuration)) {
            selection = tab
        }
    }
}

private struct HomeDiscoveryTabSwitcherItem: View {
    var tab: HomeDiscoveryPrimaryTab
    var isSelected: Bool

    var body: some View {
        Text(tab.title)
            .font(
                .system(
                    size: HomeDiscoveryTabSwitcherMetrics.fontSize,
                    weight: isSelected ? .heavy : .bold,
                    design: .rounded
                )
            )
            .foregroundStyle(
                isSelected
                ? MegrumTheme.lavender
                : MegrumTheme.ink.opacity(HomeDiscoveryTabSwitcherMetrics.inactiveTextOpacity)
            )
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(tab.title)
    }
}

enum HomeDiscoveryTabSwitcherMetrics {
    static let itemSpacing: CGFloat = 0
    static let horizontalPadding: CGFloat = 0
    static let topPadding: CGFloat = 8
    static let bottomPadding: CGFloat = 7
    static let fontSize: CGFloat = 17
    static let labelUnderlineSpacing: CGFloat = 8
    static let underlineHeight: CGFloat = 4
    static let inactiveTextOpacity = 0.34
    static let selectionAnimationDuration = 0.22

    static var totalBottomPadding: CGFloat {
        bottomPadding + labelUnderlineSpacing + underlineHeight
    }
}

struct HomeDiscoveryTabIndicatorFrame: Equatable {
    var minX: CGFloat
    var width: CGFloat

    static func interpolated(
        progress: CGFloat,
        frames: [HomeDiscoveryPrimaryTab: CGRect]
    ) -> HomeDiscoveryTabIndicatorFrame? {
        let tabs = HomeDiscoveryPrimaryTab.allCases
        guard !tabs.isEmpty else {
            return nil
        }

        let clampedProgress = min(max(progress, 0), CGFloat(tabs.count - 1))
        let lowerIndex = Int(floor(clampedProgress))
        let upperIndex = Int(ceil(clampedProgress))
        guard
            tabs.indices.contains(lowerIndex),
            tabs.indices.contains(upperIndex),
            let lowerFrame = frames[tabs[lowerIndex]],
            let upperFrame = frames[tabs[upperIndex]]
        else {
            return nil
        }

        let fraction = clampedProgress - CGFloat(lowerIndex)
        return HomeDiscoveryTabIndicatorFrame(
            minX: lowerFrame.minX + ((upperFrame.minX - lowerFrame.minX) * fraction),
            width: lowerFrame.width + ((upperFrame.width - lowerFrame.width) * fraction)
        )
    }
}

private struct HomeDiscoveryTabFramePreferenceKey: PreferenceKey {
    static let defaultValue: [HomeDiscoveryPrimaryTab: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [HomeDiscoveryPrimaryTab: Anchor<CGRect>],
        nextValue: () -> [HomeDiscoveryPrimaryTab: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, newValue in newValue })
    }
}
