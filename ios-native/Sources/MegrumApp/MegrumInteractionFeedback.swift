import MegrumDesign
import SwiftUI

#if os(iOS)
import UIKit
#endif

enum MegrumHaptics {
    static func buttonTap() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: 0.58)
        #endif
    }

    /// ドロワーを閉じるスワイプ確定時の触覚。開く時（buttonTap=0.58）よりほんの少しだけ弱く。
    static func drawerClose() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: 0.42)
        #endif
    }

    static func longPress() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred(intensity: 0.72)
        #endif
    }

    static func selectionChanged() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        #endif
    }

    static func performButtonTap(_ action: () -> Void) {
        buttonTap()
        action()
    }

    static func performSelectionChanged(_ action: () -> Void) {
        selectionChanged()
        action()
    }

    /// 自動入力の成功など、操作なしで良いことが起きた時の通知触覚（iter1226.407）。
    static func success() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        #endif
    }
}

extension View {
    /// タップ波紋（リップル）はユーザー体験上のノイズ・反応ラグの一因だったため
    /// 廃止した。触覚フィードバック（MegrumHaptics）は引き続き使用する。
    func megrumInteractionFeedback(clipsToBounds: Bool = false) -> some View {
        self
    }
}
