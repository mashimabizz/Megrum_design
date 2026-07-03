import CoreGraphics
import Foundation

struct HomeDiscoveryRotaryCardPresentationState: Equatable {
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

    func relativePosition(for index: Int, itemCount: Int, reduceMotion: Bool) -> Double {
        guard itemCount > 0 else {
            return 0
        }
        let forward = (index - selectedIndex + itemCount) % itemCount
        let backward = (selectedIndex - index + itemCount) % itemCount
        let shortest = forward <= backward ? Double(forward) : -Double(backward)
        return shortest - displayedDragProgress(reduceMotion: reduceMotion)
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
