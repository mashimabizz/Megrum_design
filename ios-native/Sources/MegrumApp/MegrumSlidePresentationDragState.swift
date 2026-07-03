import CoreGraphics

struct MegrumSlidePresentationDragState: Equatable {
    var dragOffset: CGFloat = 0
    var isTrackingDismissDrag = false

    mutating func beginTrackingIfNeeded(translation: CGSize, screenWidth: CGFloat) -> Bool {
        guard isTrackingDismissDrag
                || MegrumSlideBackSwipeResolver.interactiveOffset(
                    translation: translation,
                    screenWidth: screenWidth
                ) != nil
        else {
            return false
        }
        isTrackingDismissDrag = true
        return true
    }

    func clampedDragOffset(translation: CGSize, screenWidth: CGFloat) -> CGFloat {
        max(0, min(translation.width, screenWidth))
    }

    func shouldDismiss(
        translation: CGSize,
        predictedEndTranslationWidth: CGFloat,
        screenWidth: CGFloat
    ) -> Bool {
        guard isTrackingDismissDrag else {
            return false
        }
        return MegrumSlideBackSwipeResolver.shouldDismiss(
            translation: translation,
            predictedEndTranslationWidth: predictedEndTranslationWidth,
            screenWidth: screenWidth
        )
    }

    mutating func stopTracking() {
        isTrackingDismissDrag = false
    }

    mutating func resetDragOffset() {
        dragOffset = 0
    }
}
