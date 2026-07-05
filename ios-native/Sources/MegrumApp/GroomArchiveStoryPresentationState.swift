import CoreGraphics

enum GroomArchiveStoryMoveOutcome: Equatable {
    case moved
    case unchanged
    case dismiss
}

struct GroomArchiveStoryPresentationState: Equatable {
    var currentIndex: Int
    var dragOffset: CGSize = .zero

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

    func shouldDismiss(for translation: CGSize) -> Bool {
        translation.height > 110
    }

    mutating func resetDrag() {
        dragOffset = .zero
    }
}
