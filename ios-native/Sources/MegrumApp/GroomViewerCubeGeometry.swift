import CoreGraphics
import Foundation
import SwiftUI

/// グルームビューアで投稿者が切り替わる時の「直方体（キューブ）回転」遷移の
/// 幾何計算（iter1226.435）。Instagramストーリーズのユーザー切替と同じ見え方：
/// 進む時は現在の面が左へ90度倒れながら、次の面が右の側面から起き上がる。
enum GroomViewerCubeGeometry {
    static let rotationDegrees: Double = 90
    static let perspective: CGFloat = 0.7
    static let animationDuration: Double = 0.42
    /// 回転中に奥へ向かう面へ落とす影の最大濃さ。
    static let maxShadeOpacity: Double = 0.45

    struct FaceTransform: Equatable {
        var offsetX: CGFloat
        var degrees: Double
        /// 回転軸のアンカーX（0 = leading辺、1 = trailing辺）
        var anchorX: CGFloat
    }

    /// 出ていく面：進む（direction=+1）なら trailing 辺を軸に +90度 へ倒れつつ左へ抜ける。
    static func outgoing(progress: Double, direction: Int, width: CGFloat) -> FaceTransform {
        let d = direction >= 0 ? 1.0 : -1.0
        return FaceTransform(
            offsetX: -CGFloat(d) * width * CGFloat(progress),
            degrees: d * rotationDegrees * progress,
            anchorX: d > 0 ? 1 : 0
        )
    }

    /// 入ってくる面：進むなら右側面（leading 辺が軸・-90度）から正面へ起き上がる。
    static func incoming(progress: Double, direction: Int, width: CGFloat) -> FaceTransform {
        let d = direction >= 0 ? 1.0 : -1.0
        let remaining = 1 - progress
        return FaceTransform(
            offsetX: CGFloat(d) * width * CGFloat(remaining),
            degrees: -d * rotationDegrees * remaining,
            anchorX: d > 0 ? 0 : 1
        )
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
