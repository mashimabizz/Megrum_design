import CoreGraphics

struct HomePullRefreshPresentationState: Equatable {
    var pullOffset: CGFloat = 0
    var isRefreshing = false

    var progress: CGFloat {
        HomePullRefreshPresentation.progress(
            for: HomePullRefreshPresentation.effectivePullOffset(scrollOffset: pullOffset),
            isRefreshing: isRefreshing
        )
    }

    mutating func updateScrollOffset(_ value: CGFloat) {
        pullOffset = max(0, value)
    }

    mutating func beginRefreshIfNeeded() -> Bool {
        guard !isRefreshing else {
            return false
        }
        isRefreshing = true
        return true
    }

    mutating func finishRefresh() {
        isRefreshing = false
        pullOffset = 0
    }
}
