import SwiftUI

enum EdgeBackSwipeResolver {
    static let leadingEdgeWidth: CGFloat = 32
    static let minimumTranslation: CGFloat = 64
    static let minimumPredictedTranslation: CGFloat = 96
    static let horizontalDominance: CGFloat = 1.25

    static func shouldTrigger(
        startLocation: CGPoint,
        translation: CGSize,
        predictedEndTranslationWidth: CGFloat
    ) -> Bool {
        guard startLocation.x <= leadingEdgeWidth else {
            return false
        }
        let isRightSwipe = translation.width > 0 || predictedEndTranslationWidth > 0
        let isHorizontal = abs(translation.width) > abs(translation.height) * horizontalDominance
        let isLongEnough = translation.width >= minimumTranslation
            || predictedEndTranslationWidth >= minimumPredictedTranslation
        return isRightSwipe && isHorizontal && isLongEnough
    }
}

private struct EdgeBackSwipeModifier: ViewModifier {
    var isEnabled: Bool
    var action: () -> Void

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 12)
                    .onEnded { value in
                        guard isEnabled,
                              EdgeBackSwipeResolver.shouldTrigger(
                                startLocation: value.startLocation,
                                translation: value.translation,
                                predictedEndTranslationWidth: value.predictedEndTranslation.width
                              )
                        else {
                            return
                        }
                        action()
                    }
            )
    }
}

extension View {
    func megrumEdgeBackSwipe(
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        modifier(EdgeBackSwipeModifier(isEnabled: isEnabled, action: action))
    }
}
