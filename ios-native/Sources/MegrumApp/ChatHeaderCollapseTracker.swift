import Foundation

/// チャットルーム用のヘッダー収納トラッカー。
/// - 下方向スクロールで収納し、スクロールを止めても収納したまま維持する
///   （端でのバウンス程度の上方向の動きでは戻さない）。
/// - 明確に上方向へスクロールした時（累積で一定量）だけ展開に戻す。
struct ChatHeaderCollapseTracker {
    private var lastContentTop: CGFloat?
    private var upwardRun: CGFloat = 0

    /// この量以上の下方向移動で収納する。
    static let collapseDelta: CGFloat = -6
    /// 収納後、累積でこの量以上の上方向スクロールがあれば展開に戻す。
    /// 端のバウンス（数十pt）では戻らない値にする。
    static let expandRunThreshold: CGFloat = 150
    /// 1サンプルでこれを超える移動はレイアウトイベント（キーボード・
    /// コンテンツ差し込み等）とみなし、収納状態を変えない。
    static let layoutJumpThreshold: CGFloat = 260

    mutating func updatedCollapsedState(contentTop: CGFloat, isCollapsed: Bool) -> Bool {
        guard let lastContentTop else {
            self.lastContentTop = contentTop
            return isCollapsed
        }
        let delta = contentTop - lastContentTop
        self.lastContentTop = contentTop

        if abs(delta) > Self.layoutJumpThreshold {
            upwardRun = 0
            return isCollapsed
        }
        if delta < 0 {
            upwardRun = 0
            if delta <= Self.collapseDelta {
                return true
            }
            return isCollapsed
        }
        if delta > 0, isCollapsed {
            upwardRun += delta
            if upwardRun >= Self.expandRunThreshold {
                upwardRun = 0
                return false
            }
        }
        return isCollapsed
    }
}
