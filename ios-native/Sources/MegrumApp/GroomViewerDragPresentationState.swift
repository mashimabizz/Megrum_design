import CoreGraphics

/// グルームビューアの下スワイプ（閉じる）の見た目と判定。
/// FB(iter1226.424)：縮小はやめて「そのまま下へスライド」だけにする。
/// - 追従は下方向のみ・画面高の1/10程度（約84pt）へラバーバンドで漸近
/// - 生の引っ張り量が閾値を超えた状態で離したら閉じる（閉じる瞬間の縮小遷移は
///   presentation 側の scale-to-anchor トランジションが担う）
struct GroomViewerDragPresentationState: Equatable {
    static let dismissThreshold: CGFloat = 130

    /// 下方向の追従量の見た目上限（画面高852ptの約1/10）。
    private static let maxVisualOffset: CGFloat = 84

    var translation: CGSize = .zero

    var verticalOffset: CGFloat {
        let pull = max(translation.height, 0)
        // ラバーバンド：引くほど重くなり、maxVisualOffset に漸近する。
        return Self.maxVisualOffset * pull / (pull + Self.maxVisualOffset)
    }

    /// iter1226.424：ドラッグ中は縮小しない（閉じる時の縮小は遷移側）。
    var scale: CGFloat {
        1
    }

    /// iter1226.424：ドラッグ中は角丸も付けない（純粋な下スライド）。
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
