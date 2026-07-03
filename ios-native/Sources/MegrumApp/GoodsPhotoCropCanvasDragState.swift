import CoreGraphics
import Foundation

struct GoodsPhotoCropCanvasDragState: Equatable {
    var dragStart: CGPoint?
    var draftRect: CGRect?

    mutating func update(startLocation: CGPoint, location: CGPoint, in displayRect: CGRect) {
        let start = dragStart ?? GoodsPhotoCropGeometry.clamped(startLocation, to: displayRect)
        dragStart = start
        let current = GoodsPhotoCropGeometry.clamped(location, to: displayRect)
        draftRect = GoodsPhotoCropGeometry.rect(from: start, to: current)
    }

    mutating func finish(location: CGPoint, in displayRect: CGRect) -> TradingCardCropFrame? {
        defer {
            reset()
        }
        guard let dragStart else {
            return nil
        }
        let current = GoodsPhotoCropGeometry.clamped(location, to: displayRect)
        let screen = GoodsPhotoCropGeometry.rect(from: dragStart, to: current)
        guard screen.width >= 28, screen.height >= 28 else {
            return nil
        }
        let normalized = GoodsPhotoCropGeometry.normalizedRect(screen, in: displayRect)
        return TradingCardCropFrame(rect: normalized)
    }

    mutating func reset() {
        dragStart = nil
        draftRect = nil
    }
}
