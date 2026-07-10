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

    /// 中央に新しい枠を追加して選択する
    mutating func addCenteredFrame() {
        let frame = TradingCardCropFrame(rect: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4))
        frames.append(frame)
        selectedFrameID = frame.id
        message = nil
    }

    mutating func showEmptyFrameMessage() {
        message = "「枠を追加」で切り取り枠を作ってください。"
    }

    mutating func showFailureMessage(_ message: String) {
        self.message = message
    }
}
