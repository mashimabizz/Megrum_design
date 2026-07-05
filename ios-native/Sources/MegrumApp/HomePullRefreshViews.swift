import MegrumDesign
import SwiftUI

enum HomePullRefreshPresentation {
    static let triggerDistance: CGFloat = 86

    static func effectivePullOffset(scrollOffset: CGFloat) -> CGFloat {
        max(0, scrollOffset)
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
    /// 旧・独自インジケータの位置。二重ローディング表示（システムの
    /// refreshable スピナー＋独自）の解消のため独自側を廃止し、iOS標準の
    /// スピナーのみにした。呼び出し互換のため引数は残している。
    var indicatorTopPadding: CGFloat = 0
    var onRefresh: () async -> Void
    @ViewBuilder var content: () -> Content

    @State private var presentationState = HomePullRefreshPresentationState()

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
        }
        .onPreferenceChange(HomePullRefreshOffsetPreferenceKey.self) { value in
            presentationState.updateScrollOffset(value)
        }
    }

    @MainActor
    private func performRefresh() async {
        guard presentationState.beginRefreshIfNeeded() else {
            return
        }
        defer {
            presentationState.finishRefresh()
        }
        await onRefresh()
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
