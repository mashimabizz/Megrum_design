import CoreGraphics

enum MatchRelationSwipeDirection {
    case previous
    case next

    var step: Int {
        switch self {
        case .previous:
            -1
        case .next:
            1
        }
    }
}

enum MatchRelationSwipeResolver {
    static let minimumHorizontalDistance: CGFloat = 8
    static let horizontalPriorityRatio: CGFloat = 1.08
    static let edgeResistanceRatio: CGFloat = 0.22

    static func direction(for translation: CGSize) -> MatchRelationSwipeDirection? {
        guard isHorizontalSwipe(translation) else {
            return nil
        }
        return translation.width < 0 ? .next : .previous
    }

    static func presentationOffset(
        translation: CGSize,
        screenWidth: CGFloat,
        hasAdjacentTarget: Bool
    ) -> CGFloat? {
        guard direction(for: translation) != nil else {
            return nil
        }
        let rawOffset = hasAdjacentTarget ? translation.width : translation.width * edgeResistanceRatio
        return max(-screenWidth, min(screenWidth, rawOffset))
    }

    static func shouldSwitchTarget(
        translation: CGSize,
        predictedEndTranslationWidth: CGFloat,
        screenWidth: CGFloat,
        hasAdjacentTarget: Bool
    ) -> Bool {
        guard hasAdjacentTarget, direction(for: translation) != nil else {
            return false
        }
        let absX = abs(translation.width)
        let fastEnough = abs(predictedEndTranslationWidth) >= absX + 32 && absX >= 42
        return absX >= threshold(screenWidth: screenWidth) || fastEnough
    }

    static func threshold(screenWidth: CGFloat) -> CGFloat {
        min(118, max(72, screenWidth * 0.24))
    }

    private static func isHorizontalSwipe(_ translation: CGSize) -> Bool {
        let absX = abs(translation.width)
        let absY = abs(translation.height)
        return absX > minimumHorizontalDistance && absX > absY * horizontalPriorityRatio
    }
}
