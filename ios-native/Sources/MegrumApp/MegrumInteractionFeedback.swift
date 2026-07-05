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
}

extension View {
    /// タップ波紋（リップル）はユーザー体験上のノイズ・反応ラグの一因だったため
    /// 廃止した。触覚フィードバック（MegrumHaptics）は引き続き使用する。
    func megrumInteractionFeedback(clipsToBounds: Bool = false) -> some View {
        self
    }
}
