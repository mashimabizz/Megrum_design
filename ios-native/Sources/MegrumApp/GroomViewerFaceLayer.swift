import Foundation
import MegrumCore

/// グルームビューアで同時に描画する「面」の役割（iter1226.469）。
enum GroomViewerFaceRole: Equatable {
    /// 通常表示（回転していない現在の面）。
    case current
    /// 回転で出ていく面（source＝回転開始時の現在面）。
    case outgoing
    /// 回転で入ってくる面（target＝切替先）。完了後は current へ昇格する。
    case incoming
}

/// viewerSurface 内の単一 `ForEach` で描く面レイヤー（iter1226.469）。
///
/// `id` を `groom.id` に固定することで、回転中の incoming（target）面と、
/// 回転完了後の current 面が **同じ View identity** になり、画像の `@State`・
/// `UITextField` などを保持したまま昇格できる。以前は current 面（通常枝）と
/// target 面（条件付き枝）が別 View で、完了時に target を破棄して current を
/// 作り直していたため、最終フレームで画像・進捗・入力欄がまとめて差し替わり
/// 「一瞬止まる」ように見えていた。
struct GroomViewerFaceLayer: Identifiable, Equatable {
    /// `groom.id`（遷移中 target と完了後 current で一致させ、View を保持する）。
    var id: UUID
    var groomIndex: Int
    var role: GroomViewerFaceRole
    var zIndex: Double
    /// タップ等の操作を許可するか。回転中は source/target とも false（直列化）。
    var isInteractionEnabled: Bool
}

/// 表示すべき面レイヤーを決める純粋ロジック（テスト対象）。
/// - 通常時：`[current]`
/// - 回転中：`[outgoing(source), incoming(target)]`
/// - 完了後：`[current(=target)]`（transition=nil・currentIndex=targetIndex）
enum GroomViewerFacePlanner {
    static func layers(
        grooms: [GroomPost],
        currentIndex: Int,
        transition: GroomViewerCubeTransition?
    ) -> [GroomViewerFaceLayer] {
        if let transition,
           grooms.indices.contains(transition.sourceIndex),
           grooms.indices.contains(transition.targetIndex) {
            return [
                GroomViewerFaceLayer(
                    id: grooms[transition.sourceIndex].id,
                    groomIndex: transition.sourceIndex,
                    role: .outgoing,
                    zIndex: 0,
                    isInteractionEnabled: false
                ),
                GroomViewerFaceLayer(
                    id: grooms[transition.targetIndex].id,
                    groomIndex: transition.targetIndex,
                    role: .incoming,
                    zIndex: 1,
                    isInteractionEnabled: false
                )
            ]
        }
        guard grooms.indices.contains(currentIndex) else {
            return []
        }
        return [
            GroomViewerFaceLayer(
                id: grooms[currentIndex].id,
                groomIndex: currentIndex,
                role: .current,
                zIndex: 0,
                isInteractionEnabled: true
            )
        ]
    }
}
