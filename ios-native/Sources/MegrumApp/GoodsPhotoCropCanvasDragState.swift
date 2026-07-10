import CoreGraphics
import Foundation

struct GoodsPhotoCropCanvasDragState: Equatable {
    enum Corner: CaseIterable, Hashable {
        case topLeading
        case topTrailing
        case bottomLeading
        case bottomTrailing
    }

    enum Mode: Equatable {
        case draw
        case move(frameID: UUID, originalRect: CGRect)
        case resize(frameID: UUID, corner: Corner, originalRect: CGRect)
    }

    static let cornerHitRadius: CGFloat = 26
    static let minFrameSide: CGFloat = 28

    var mode: Mode?
    var dragStart: CGPoint?
    var draftRect: CGRect?

    static func cornerPoint(_ corner: Corner, of rect: CGRect) -> CGPoint {
        switch corner {
        case .topLeading:
            CGPoint(x: rect.minX, y: rect.minY)
        case .topTrailing:
            CGPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeading:
            CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomTrailing:
            CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }

    /// ドラッグ開始点からモードを決める。
    /// 選択枠の四隅→リサイズ、枠内→移動（その枠を選択）、それ以外→新規描画。
    /// 戻り値は「選択すべき枠ID」（nil = 選択変更なし）。
    mutating func begin(
        at startLocation: CGPoint,
        frames: [TradingCardCropFrame],
        selectedFrameID: UUID?,
        in displayRect: CGRect
    ) -> UUID? {
        let start = GoodsPhotoCropGeometry.clamped(startLocation, to: displayRect)
        dragStart = start

        if let selectedFrameID,
           let selected = frames.first(where: { $0.id == selectedFrameID }) {
            let screenRect = GoodsPhotoCropGeometry.screenRect(for: selected.rect, in: displayRect)
            for corner in Corner.allCases {
                let point = Self.cornerPoint(corner, of: screenRect)
                if hypot(point.x - startLocation.x, point.y - startLocation.y) <= Self.cornerHitRadius {
                    mode = .resize(frameID: selectedFrameID, corner: corner, originalRect: screenRect)
                    return nil
                }
            }
        }

        if let hit = frames.reversed().first(where: { frame in
            GoodsPhotoCropGeometry.screenRect(for: frame.rect, in: displayRect).contains(start)
        }) {
            let screenRect = GoodsPhotoCropGeometry.screenRect(for: hit.rect, in: displayRect)
            mode = .move(frameID: hit.id, originalRect: screenRect)
            return hit.id
        }

        mode = .draw
        return nil
    }

    /// ドラッグ中の更新。移動・リサイズ中は対象枠の新しい screen rect を返す。
    /// 新規描画中は draftRect を更新して nil を返す。
    mutating func update(location: CGPoint, in displayRect: CGRect) -> (frameID: UUID, rect: CGRect)? {
        guard let dragStart, let mode else {
            return nil
        }
        switch mode {
        case .draw:
            let current = GoodsPhotoCropGeometry.clamped(location, to: displayRect)
            draftRect = GoodsPhotoCropGeometry.rect(from: dragStart, to: current)
            return nil
        case .move(let frameID, let originalRect):
            var moved = originalRect.offsetBy(
                dx: location.x - dragStart.x,
                dy: location.y - dragStart.y
            )
            moved.origin.x = min(max(moved.origin.x, displayRect.minX), displayRect.maxX - moved.width)
            moved.origin.y = min(max(moved.origin.y, displayRect.minY), displayRect.maxY - moved.height)
            return (frameID, moved)
        case .resize(let frameID, let corner, let originalRect):
            let resized = Self.resizedRect(original: originalRect, corner: corner, to: location, in: displayRect)
            return (frameID, resized)
        }
    }

    /// 四隅リサイズ：対角のコーナーを固定して、ドラッグ先までの矩形を作る。
    static func resizedRect(original: CGRect, corner: Corner, to point: CGPoint, in displayRect: CGRect) -> CGRect {
        let anchor: CGPoint = switch corner {
        case .topLeading:
            CGPoint(x: original.maxX, y: original.maxY)
        case .topTrailing:
            CGPoint(x: original.minX, y: original.maxY)
        case .bottomLeading:
            CGPoint(x: original.maxX, y: original.minY)
        case .bottomTrailing:
            CGPoint(x: original.minX, y: original.minY)
        }

        var target = GoodsPhotoCropGeometry.clamped(point, to: displayRect)
        if abs(target.x - anchor.x) < minFrameSide {
            target.x = anchor.x + (target.x >= anchor.x ? minFrameSide : -minFrameSide)
        }
        if abs(target.y - anchor.y) < minFrameSide {
            target.y = anchor.y + (target.y >= anchor.y ? minFrameSide : -minFrameSide)
        }
        target = GoodsPhotoCropGeometry.clamped(target, to: displayRect)
        return GoodsPhotoCropGeometry.rect(from: anchor, to: target)
    }

    /// ドラッグ終了。新規描画モードで十分な大きさなら新しい枠を返す。
    mutating func finish(location: CGPoint, in displayRect: CGRect) -> TradingCardCropFrame? {
        defer {
            reset()
        }
        guard case .draw = mode, let dragStart else {
            return nil
        }
        let current = GoodsPhotoCropGeometry.clamped(location, to: displayRect)
        let screen = GoodsPhotoCropGeometry.rect(from: dragStart, to: current)
        guard screen.width >= Self.minFrameSide, screen.height >= Self.minFrameSide else {
            return nil
        }
        let normalized = GoodsPhotoCropGeometry.normalizedRect(screen, in: displayRect)
        return TradingCardCropFrame(rect: normalized)
    }

    mutating func reset() {
        mode = nil
        dragStart = nil
        draftRect = nil
    }
}
