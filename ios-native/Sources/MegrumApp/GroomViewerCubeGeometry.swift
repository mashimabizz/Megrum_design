import CoreGraphics
import Foundation
import SwiftUI

/// グルームビューアで投稿者が切り替わる時の「直方体（キューブ）回転」遷移の
/// 幾何計算（iter1226.435 / iter1226.437 で凸＝外側視点へ反転）。
/// ユーザーが立体物の外側にいて直方体を手で回すように、面と面の共有辺が
/// 手前へ張り出しながら回る。
enum GroomViewerCubeGeometry {
    static let rotationDegrees: Double = 90
    static let perspective: CGFloat = 0.7
    static let animationDuration: Double = 0.42
    /// 回転中に奥へ向かう面へ落とす影の最大濃さ。
    static let maxShadeOpacity: Double = 0.45
    /// スワイプで指を離した時、ここまで回っていれば切替を確定する進捗。
    static let commitProgressThreshold: Double = 0.32
    /// 勢い（predictedEnd）ベースの確定しきい値（進捗換算）。
    static let commitPredictedThreshold: Double = 0.5
    /// 指を離した後の残り回転アニメーションの時間。
    static let settleDuration: Double = 0.24

    struct FaceTransform: Equatable {
        var offsetX: CGFloat
        var degrees: Double
        /// 回転軸のアンカーX（0 = leading辺、1 = trailing辺）
        var anchorX: CGFloat
    }

    /// 出ていく面：進む（direction=+1）なら trailing 辺（共有辺）を軸に
    /// 外側視点の回転（-90度）で左へ抜ける。
    static func outgoing(progress: Double, direction: Int, width: CGFloat) -> FaceTransform {
        let d = direction >= 0 ? 1.0 : -1.0
        return FaceTransform(
            offsetX: -CGFloat(d) * width * CGFloat(progress),
            degrees: -d * rotationDegrees * progress,
            anchorX: d > 0 ? 1 : 0
        )
    }

    /// 入ってくる面：進むなら右側面（leading 辺が軸・+90度）から正面へ回り込む。
    static func incoming(progress: Double, direction: Int, width: CGFloat) -> FaceTransform {
        let d = direction >= 0 ? 1.0 : -1.0
        let remaining = 1 - progress
        return FaceTransform(
            offsetX: CGFloat(d) * width * CGFloat(remaining),
            degrees: d * rotationDegrees * remaining,
            anchorX: d > 0 ? 0 : 1
        )
    }

    /// スワイプ量→回転進捗（0〜1）。direction=+1 は左スワイプ（負の translation）で進む。
    static func dragProgress(translationX: CGFloat, direction: Int, width: CGFloat) -> Double {
        guard width > 0 else {
            return 0
        }
        let d: CGFloat = direction >= 0 ? 1 : -1
        return min(max(Double(-d * translationX / width), 0), 1)
    }

    /// 出ていく面の影（進むほど濃く）。
    static func outgoingShade(progress: Double) -> Double {
        maxShadeOpacity * progress
    }

    /// 入ってくる面の影（正面に来るほど薄く）。
    static func incomingShade(progress: Double) -> Double {
        maxShadeOpacity * (1 - progress)
    }
}

/// スワイプでの投稿者切替先の決定（iter1226.437）。
/// Instagramと同じく、横スワイプは「次/前の投稿者」へ飛ぶ：
/// 進む＝次の投稿者ブロックの先頭、戻る＝前の投稿者ブロックの先頭。
enum GroomViewerAuthorNavigation {
    static func authorSwitchTargetIndex(
        authorIDs: [UUID],
        currentIndex: Int,
        direction: Int
    ) -> Int? {
        guard authorIDs.indices.contains(currentIndex) else {
            return nil
        }
        let currentAuthor = authorIDs[currentIndex]
        if direction > 0 {
            var index = currentIndex + 1
            while index < authorIDs.count {
                if authorIDs[index] != currentAuthor {
                    return index
                }
                index += 1
            }
            return nil
        }
        var index = currentIndex - 1
        while index >= 0, authorIDs[index] == currentAuthor {
            index -= 1
        }
        guard index >= 0 else {
            return nil
        }
        let previousAuthor = authorIDs[index]
        while index > 0, authorIDs[index - 1] == previousAuthor {
            index -= 1
        }
        return index
    }
}

/// キューブの1面ぶんの回転・移動・影を適用するモディファイア。
struct GroomViewerCubeFaceModifier: ViewModifier {
    var transform: GroomViewerCubeGeometry.FaceTransform
    var shade: Double

    func body(content: Content) -> some View {
        content
            .overlay {
                Color.black
                    .opacity(shade)
                    .allowsHitTesting(false)
            }
            .rotation3DEffect(
                .degrees(transform.degrees),
                axis: (x: 0, y: 1, z: 0),
                anchor: UnitPoint(x: transform.anchorX, y: 0.5),
                perspective: GroomViewerCubeGeometry.perspective
            )
            .offset(x: transform.offsetX)
    }
}
