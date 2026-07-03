import CoreGraphics

struct FullScreenRemoteImagePresentationState: Equatable {
    var isVisible = false
    var scale: CGFloat = 1
    var lastScale: CGFloat = 1
    var offset: CGSize = .zero
    var lastOffset: CGSize = .zero
    var dismissDragOffset: CGFloat = 0

    var backgroundOpacity: Double {
        guard isVisible else {
            return 0
        }
        let dragProgress = Double(min(dismissDragOffset, 220) / 320)
        return max(0.22, 0.58 - dragProgress * 0.28)
    }

    var imagePresentationScale: CGFloat {
        isVisible ? 1 : 0.9
    }

    var contentOpacity: Double {
        isVisible ? 1 : 0
    }

    var imageOffset: CGSize {
        CGSize(width: offset.width, height: offset.height + dismissDragOffset)
    }

    var isZoomed: Bool {
        scale > 1
    }

    mutating func show() {
        isVisible = true
    }

    mutating func updateMagnification(_ value: CGFloat) {
        scale = min(max(lastScale * value, 1), 4)
    }

    mutating func endMagnification() {
        lastScale = scale
        if scale <= 1.02 {
            resetZoom()
        }
    }

    mutating func updateDrag(translation: CGSize) {
        if isZoomed {
            offset = CGSize(
                width: lastOffset.width + translation.width,
                height: lastOffset.height + translation.height
            )
        } else if translation.height > 0,
                  abs(translation.height) > abs(translation.width) {
            dismissDragOffset = translation.height
        }
    }

    mutating func finishZoomedDrag() {
        lastOffset = offset
    }

    func shouldDismissAfterDrag(predictedEndTranslation: CGSize) -> Bool {
        dismissDragOffset > 96 || predictedEndTranslation.height > 160
    }

    mutating func resetDismissDragOffset() {
        dismissDragOffset = 0
    }

    mutating func resetZoom() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
        dismissDragOffset = 0
    }

    mutating func prepareDismissal() {
        isVisible = false
        dismissDragOffset = 0
    }
}
