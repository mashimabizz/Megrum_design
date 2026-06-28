import MegrumDesign
import SwiftUI

enum HomePullRefreshPresentation {
    static let triggerDistance: CGFloat = 86

    static func effectivePullOffset(scrollOffset: CGFloat, manualOffset: CGFloat) -> CGFloat {
        max(max(0, scrollOffset), max(0, manualOffset))
    }

    static func progress(for pullOffset: CGFloat, isRefreshing: Bool) -> CGFloat {
        guard !isRefreshing else {
            return 1
        }
        guard pullOffset > 0 else {
            return 0
        }
        return min(1, pullOffset / triggerDistance)
    }

    static func indicatorOpacity(progress: CGFloat) -> CGFloat {
        min(1, max(0, progress))
    }

    static func indicatorScale(progress: CGFloat) -> CGFloat {
        0.72 + min(1, max(0, progress)) * 0.28
    }
}

struct HomePullRefreshScrollView<Content: View>: View {
    var coordinateSpaceName: String
    var indicatorTopPadding: CGFloat
    var onRefresh: () async -> Void
    @ViewBuilder var content: () -> Content

    @State private var pullOffset: CGFloat = 0
    @State private var manualPullOffset: CGFloat = 0
    @State private var isRefreshing = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                HomePullRefreshOffsetReader(coordinateSpaceName: coordinateSpaceName)
                content()
                    .frame(minHeight: geometry.size.height, alignment: .top)
            }
            .scrollBounceBehavior(.always)
            .coordinateSpace(name: coordinateSpaceName)
            .refreshable {
                await performRefresh()
            }
            .simultaneousGesture(manualPullGesture)
        }
        .overlay(alignment: .top) {
            HomePullRefreshIndicator(
                progress: progress,
                isRefreshing: isRefreshing
            )
            .padding(.top, indicatorTopPadding)
        }
        .onPreferenceChange(HomePullRefreshOffsetPreferenceKey.self) { value in
            pullOffset = max(0, value)
        }
    }

    private var progress: CGFloat {
        HomePullRefreshPresentation.progress(
            for: HomePullRefreshPresentation.effectivePullOffset(
                scrollOffset: pullOffset,
                manualOffset: manualPullOffset
            ),
            isRefreshing: isRefreshing
        )
    }

    private var manualPullGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard canTrackManualPull(for: value) else {
                    manualPullOffset = 0
                    return
                }
                manualPullOffset = value.translation.height
            }
            .onEnded { value in
                let reachedRefreshDistance = canTrackManualPull(for: value)
                    && value.translation.height >= HomePullRefreshPresentation.triggerDistance
                manualPullOffset = 0
                guard reachedRefreshDistance else {
                    return
                }
                Task { @MainActor in
                    await performRefresh()
                }
            }
    }

    private func canTrackManualPull(for value: DragGesture.Value) -> Bool {
        pullOffset >= -1
            && value.translation.height > 0
            && value.translation.height > abs(value.translation.width)
    }

    @MainActor
    private func performRefresh() async {
        guard !isRefreshing else {
            return
        }
        isRefreshing = true
        defer {
            isRefreshing = false
        }
        await onRefresh()
    }
}

private struct HomePullRefreshIndicator: View {
    var progress: CGFloat
    var isRefreshing: Bool

    var body: some View {
        ProgressView()
            .controlSize(.small)
            .tint(MegrumTheme.lavender)
            .padding(10)
            .background(.ultraThinMaterial, in: Circle())
            .overlay {
                Circle()
                    .stroke(MegrumTheme.lavender.opacity(0.18 + 0.28 * progress), lineWidth: 1)
            }
            .scaleEffect(HomePullRefreshPresentation.indicatorScale(progress: progress))
            .opacity(HomePullRefreshPresentation.indicatorOpacity(progress: progress))
            .offset(y: -18 + 18 * progress)
            .animation(.spring(response: 0.22, dampingFraction: 0.86), value: progress)
            .animation(.easeInOut(duration: 0.16), value: isRefreshing)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct HomePullRefreshOffsetReader: View {
    var coordinateSpaceName: String

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: HomePullRefreshOffsetPreferenceKey.self,
                    value: proxy.frame(in: .named(coordinateSpaceName)).minY
                )
        }
        .frame(height: 0)
    }
}

private struct HomePullRefreshOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
