import SwiftUI

enum TradeDetailSlidePresentationMetrics {
    static let leadingEdgeCaptureWidth: CGFloat = 32
    static let minimumTranslation: CGFloat = 78
    static let minimumPredictedTranslation: CGFloat = 132
    static let horizontalDominance: CGFloat = 1.16
    static let dismissFraction: CGFloat = 0.30
    static let presentationSettledDelayNanoseconds: UInt64 = 420_000_000
    static let animation: Animation = .interactiveSpring(response: 0.32, dampingFraction: 0.88, blendDuration: 0.04)
}

enum TradeDetailSlideBackSwipeResolver {
    static func interactiveOffset(translation: CGSize, screenWidth: CGFloat) -> CGFloat? {
        guard translation.width > 0 else {
            return nil
        }
        let isHorizontal = abs(translation.width) > abs(translation.height) * TradeDetailSlidePresentationMetrics.horizontalDominance
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
        let isLongEnough = offset >= TradeDetailSlidePresentationMetrics.minimumTranslation
            || predictedEndTranslationWidth >= TradeDetailSlidePresentationMetrics.minimumPredictedTranslation
            || offset >= screenWidth * TradeDetailSlidePresentationMetrics.dismissFraction
        return isLongEnough
    }
}
