import CoreGraphics

struct InteractiveBackSwipePresentationState: Equatable {
    var dragOffset: CGFloat = 0
    var isTrackingBackSwipe = false
    var containerWidth = InteractiveBackSwipeResolver.defaultScreenWidth

    mutating func updateContainerWidth(_ width: CGFloat) {
        let normalizedWidth = max(width, 1)
        guard abs(containerWidth - normalizedWidth) > 0.5 else {
            return
        }
        containerWidth = normalizedWidth
    }

    mutating func beginTrackingIfNeeded(translation: CGSize) -> Bool {
        guard isTrackingBackSwipe
                || InteractiveBackSwipeResolver.trackedOffset(
                    translation: translation,
                    screenWidth: containerWidth
                ) != nil
        else {
            return false
        }
        isTrackingBackSwipe = true
        return true
    }

    func trackedOffset(translation: CGSize) -> CGFloat {
        InteractiveBackSwipeResolver.trackedOffset(
            translation: translation,
            screenWidth: containerWidth
        ) ?? 0
    }

    func shouldTrigger(translation: CGSize, predictedEndTranslationWidth: CGFloat) -> Bool {
        guard isTrackingBackSwipe else {
            return false
        }
        return InteractiveBackSwipeResolver.shouldTrigger(
            translation: translation,
            predictedEndTranslationWidth: predictedEndTranslationWidth,
            screenWidth: containerWidth
        )
    }

    mutating func stopTracking() {
        isTrackingBackSwipe = false
    }

    mutating func resetDragOffset() {
        dragOffset = 0
    }
}
