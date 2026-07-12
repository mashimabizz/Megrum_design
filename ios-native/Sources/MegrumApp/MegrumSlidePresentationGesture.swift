import SwiftUI

enum MegrumSlidePresentationMetrics {
    static let leadingEdgeCaptureWidth: CGFloat = 24
    static let minimumTranslation: CGFloat = 78
    static let minimumPredictedTranslation: CGFloat = 132
    static let horizontalDominance: CGFloat = 1.16
    static let dismissFraction: CGFloat = 0.30
    static let animation: Animation = .interactiveSpring(
        response: 0.32,
        dampingFraction: 0.88,
        blendDuration: 0.04
    )
    static var trailingTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .trailing)
        )
    }

    /// iter1226.422：左から出すスライド（ホーム経由グルーム作成）。
    static var leadingTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .leading),
            removal: .move(edge: .leading)
        )
    }

    static func transition(for edge: MegrumSlidePresentationEdge) -> AnyTransition {
        switch edge {
        case .trailing:
            trailingTransition
        case .leading:
            leadingTransition
        }
    }
}

/// スライド表示の出現方向。既存の右から（trailing）に加え、左から（leading）を選べる。
enum MegrumSlidePresentationEdge: Equatable {
    case trailing
    case leading
}

enum MegrumSlideBackSwipeInteractionScope: Equatable {
    case leadingEdge
    case fullScreen
    /// iter1226.476：戻るスワイプ無効（明示的な「閉じる」ボタンのみで閉じる）。
    /// プロフィールなど、横スワイプで誤って閉じたくない画面に使う。
    case none
}

enum MegrumSlideBackSwipeResolver {
    static func interactiveOffset(translation: CGSize, screenWidth: CGFloat) -> CGFloat? {
        guard translation.width > 0 else {
            return nil
        }
        let isHorizontal = abs(translation.width) > abs(translation.height) * MegrumSlidePresentationMetrics.horizontalDominance
        guard isHorizontal else {
            return nil
        }
        return min(translation.width, screenWidth)
    }

    static func shouldDismiss(
        translation: CGSize,
        predictedEndTranslationWidth: CGFloat,
        screenWidth: CGFloat
    ) -> Bool {
        guard let offset = interactiveOffset(translation: translation, screenWidth: screenWidth) else {
            return false
        }
        return offset >= MegrumSlidePresentationMetrics.minimumTranslation
            || predictedEndTranslationWidth >= MegrumSlidePresentationMetrics.minimumPredictedTranslation
            || offset >= screenWidth * MegrumSlidePresentationMetrics.dismissFraction
    }
}
