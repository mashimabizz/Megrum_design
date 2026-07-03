import CoreGraphics
import Foundation

struct TradeDetailSlidePresentationState: Equatable {
    var visibleRoute: TradeDetailRoute?
    var isDetailPresented = false
    var dragOffset: CGFloat = 0
    var isTrackingDismissDrag = false
    var transitionToken = UUID()

    var hasVisibleRoute: Bool {
        visibleRoute != nil
    }

    func contentOffset(screenWidth: CGFloat) -> CGFloat {
        TradeDetailSlidePresentationResolver.contentOffset(
            isPresented: isDetailPresented,
            dragOffset: dragOffset,
            screenWidth: screenWidth
        )
    }

    @discardableResult
    mutating func preparePresentation(route: TradeDetailRoute, token: UUID = UUID()) -> UUID {
        transitionToken = token
        visibleRoute = route
        isDetailPresented = false
        dragOffset = 0
        isTrackingDismissDrag = false
        return token
    }

    func canCompletePresentation(token: UUID, route: TradeDetailRoute, currentRoute: TradeDetailRoute?) -> Bool {
        transitionToken == token && visibleRoute == route && currentRoute == route
    }

    mutating func markPresented() {
        isDetailPresented = true
    }

    @discardableResult
    mutating func prepareDismissal(token: UUID = UUID()) -> UUID? {
        guard visibleRoute != nil else {
            resetDismissDrag()
            return nil
        }
        transitionToken = token
        isTrackingDismissDrag = false
        return token
    }

    mutating func markDismissed() {
        isDetailPresented = false
    }

    func canCompleteDismissal(token: UUID) -> Bool {
        transitionToken == token
    }

    mutating func completeDismissal() {
        visibleRoute = nil
        dragOffset = 0
        isTrackingDismissDrag = false
    }

    mutating func beginTrackingDismissDragIfNeeded(translation: CGSize, screenWidth: CGFloat) -> Bool {
        guard isTrackingDismissDrag
                || TradeDetailSlideBackSwipeResolver.interactiveOffset(
                    translation: translation,
                    screenWidth: screenWidth
                ) != nil
        else {
            return false
        }
        isTrackingDismissDrag = true
        setDragOffset(max(0, min(translation.width, screenWidth)))
        return true
    }

    func shouldDismiss(
        translation: CGSize,
        predictedEndTranslationWidth: CGFloat,
        screenWidth: CGFloat
    ) -> Bool {
        TradeDetailSlideBackSwipeResolver.shouldDismiss(
            translation: translation,
            predictedEndTranslationWidth: predictedEndTranslationWidth,
            screenWidth: screenWidth
        )
    }

    mutating func stopTrackingDismissDrag() {
        isTrackingDismissDrag = false
    }

    mutating func setDragOffset(_ offset: CGFloat) {
        dragOffset = offset
    }

    mutating func resetDismissDrag() {
        isTrackingDismissDrag = false
        dragOffset = 0
    }
}
