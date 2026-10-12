import Foundation

struct GoodsPhotoCropSheetPresentationState: Equatable {
    var frames: [TradingCardCropFrame]
    var selectedFrameID: UUID?
    var message: String?

    init(initialFrames: [TradingCardCropFrame] = []) {
        frames = initialFrames
        selectedFrameID = initialFrames.first?.id
    }

    var canApply: Bool {
        !frames.isEmpty
    }

    mutating func deleteFrame(_ frameID: UUID) {
        frames.removeAll { $0.id == frameID }
        if selectedFrameID == frameID {
            selectedFrameID = frames.first?.id
        }
    }

    mutating func clearFrames() {
        frames = []
        selectedFrameID = nil
    }

    /// 初期枠へ戻す（リセット）
    mutating func reset(to initialFrames: [TradingCardCropFrame]) {
        frames = initialFrames
        selectedFrameID = initialFrames.first?.id
        message = nil
    }

    mutating func showFailureMessage(_ message: String) {
        self.message = message
    }
}
