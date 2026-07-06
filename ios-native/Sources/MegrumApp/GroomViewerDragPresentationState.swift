import CoreGraphics

/// グルームビューアの下スワイプ（閉じる）の見た目と判定。
/// - 動くのは下方向のみ（縮小・角丸などの演出はなし）
/// - 引っ張れるのは画面のおよそ1/10まで（ラバーバンドで漸近）
/// - 生の引っ張り量が閾値を超えた状態で離したら閉じる
struct GroomViewerDragPresentationState: Equatable {
    static let dismissThreshold: CGFloat = 130

    /// 画面高さ（約840pt級）の1/10相当の見た目上限。
    private static let maxVisualOffset: CGFloat = 84

    var translation: CGSize = .zero

    var verticalOffset: CGFloat {
        let pull = max(translation.height, 0)
        // ラバーバンド：引くほど重くなり、maxVisualOffset に漸近する。
        return Self.maxVisualOffset * pull / (pull + Self.maxVisualOffset)
    }

    /// 縮小演出は廃止（常に等倍）。
    var scale: CGFloat {
        1
    }

    /// 角丸演出も廃止。
    var cornerRadius: CGFloat {
        0
    }

    mutating func update(with translation: CGSize) {
        guard translation.height > 0 else {
            self.translation = .zero
            return
        }
        // 横方向は無視して下方向のみ反映する。
        self.translation = CGSize(width: 0, height: translation.height)
    }

    mutating func reset() {
        translation = .zero
    }

    func shouldDismiss(for translation: CGSize) -> Bool {
        translation.height > Self.dismissThreshold
    }
}
