import CoreGraphics

enum GroomArchiveStoryMoveOutcome: Equatable {
    case moved
    case unchanged
    case dismiss
}

enum GroomArchiveStoryDragOutcome: Equatable {
    case none
    case showInsights
    case dismiss
}

struct GroomArchiveStoryPresentationState: Equatable {
    var currentIndex: Int
    var dragOffset: CGSize = .zero
    var showsInsights = false

    init(initialIndex: Int = 0) {
        currentIndex = max(0, initialIndex)
    }

    var imageYOffset: CGFloat {
        dragOffset.height * 0.20
    }

    var imageScale: CGFloat {
        max(0.92, 1 - abs(dragOffset.height) / 900)
    }

    mutating func move(by delta: Int, itemCount: Int) -> GroomArchiveStoryMoveOutcome {
        let nextIndex = currentIndex + delta
        guard 0..<itemCount ~= nextIndex else {
            return delta > 0 ? .dismiss : .unchanged
        }
        currentIndex = nextIndex
        return .moved
    }

    mutating func updateDrag(_ translation: CGSize) {
        dragOffset = translation
    }

    func dragOutcome(for translation: CGSize) -> GroomArchiveStoryDragOutcome {
        if translation.height < -76 {
            return .showInsights
        }
        if translation.height > 110 {
            return .dismiss
        }
        return .none
    }

    mutating func resetDrag() {
        dragOffset = .zero
    }

    mutating func showInsights() {
        showsInsights = true
    }

    mutating func dismissInsights() {
        showsInsights = false
    }
}
