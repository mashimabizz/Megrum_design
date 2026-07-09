import CoreGraphics

/// グルームビューアの下スワイプ（閉じる）の見た目と判定。
/// FB(iter1226.401)：下方向に引くほど「グルーム一覧の場所へ縮んでいく」感じにする。
/// - 引くほど少しずつ縮小（scale が下がる）＋角丸が付く＋下方向に少し追従
/// - 生の引っ張り量が閾値を超えた状態で離したら閉じる（離した後の最終縮小は presentation 側の
///   scale-to-anchor トランジションが担う）
struct GroomViewerDragPresentationState: Equatable {
    static let dismissThreshold: CGFloat = 130

    /// 下方向の追従量の見た目上限。縮小と併せて使うので控えめ。
    private static let maxVisualOffset: CGFloat = 120

    var translation: CGSize = .zero

    var verticalOffset: CGFloat {
        let pull = max(translation.height, 0)
        // ラバーバンド：引くほど重くなり、maxVisualOffset に漸近する。
        return Self.maxVisualOffset * pull / (pull + Self.maxVisualOffset)
    }

    /// 引くほど縮小（1 → 約0.8）。一覧のタイルへ吸い込まれていく前段の縮み。
    var scale: CGFloat {
        let pull = max(translation.height, 0)
        return 1 - 0.34 * (pull / (pull + 120))
    }

    /// 縮小に合わせて角丸を付ける（カード化していく感じ）。
    var cornerRadius: CGFloat {
        let pull = max(translation.height, 0)
        return 30 * (pull / (pull + 120))
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
