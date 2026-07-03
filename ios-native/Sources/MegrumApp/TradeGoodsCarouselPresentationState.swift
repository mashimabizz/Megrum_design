import CoreGraphics
import Foundation

struct TradeGoodsCarouselPresentationState: Equatable {
    var selectedIndex: Int = 0
    var dragProgress: Double = 0

    func countText(itemCount: Int) -> String {
        guard itemCount > 0 else {
            return "0/0"
        }
        return "\(selectedIndex + 1)/\(itemCount)"
    }

    func displayedDragProgress(reduceMotion: Bool) -> Double {
        reduceMotion ? 0 : dragProgress
    }

    func tableRotation(itemCount: Int, reduceMotion: Bool) -> Double {
        let step = 360.0 / Double(max(itemCount, 3))
        return (Double(selectedIndex) + displayedDragProgress(reduceMotion: reduceMotion)) * step
    }

    mutating func clampSelection(itemCount: Int) {
        selectedIndex = min(selectedIndex, max(0, itemCount - 1))
        dragProgress = 0
    }

    mutating func updateDragProgress(_ progress: Double) {
        dragProgress = progress
    }

    mutating func resetDragProgress() {
        dragProgress = 0
    }

    mutating func settle(indexDelta: Int, itemCount: Int) {
        if itemCount > 0, indexDelta != 0 {
            selectedIndex = wrappedIndex(selectedIndex + indexDelta, itemCount: itemCount)
        }
        dragProgress = 0
    }

    func wrappedIndex(_ index: Int, itemCount: Int) -> Int {
        guard itemCount > 0 else {
            return 0
        }
        return (index % itemCount + itemCount) % itemCount
    }

    static func dragProgress(translation: CGSize, width: CGFloat) -> Double? {
        guard HorizontalSwipeIntentResolver.isHorizontalSwipe(translation) else {
            return nil
        }
        let denominator = max(width * 0.58, 72)
        return max(-1.15, min(1.15, -Double(translation.width / denominator)))
    }

    static func resolvedIndexDelta(
        translation: CGSize,
        projectedTranslationWidth: CGFloat,
        width: CGFloat
    ) -> Int? {
        guard HorizontalSwipeIntentResolver.isHorizontalSwipe(translation) else {
            return nil
        }
        let denominator = max(width * 0.58, 72)
        let projectedProgress = -Double(projectedTranslationWidth / denominator)
        let actualProgress = -Double(translation.width / denominator)
        let resolvedProgress = abs(projectedProgress) > abs(actualProgress) ? projectedProgress : actualProgress
        if resolvedProgress > 0.34 {
            return 1
        }
        if resolvedProgress < -0.34 {
            return -1
        }
        return 0
    }
}
