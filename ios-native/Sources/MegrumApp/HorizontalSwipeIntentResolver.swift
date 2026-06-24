import CoreGraphics

enum HorizontalSwipeIntentResolver {
    static let minimumHorizontalDistance: CGFloat = 8
    static let horizontalDominanceRatio: CGFloat = 1.15

    static func isHorizontalSwipe(
        _ translation: CGSize,
        minimumDistance: CGFloat = minimumHorizontalDistance,
        dominanceRatio: CGFloat = horizontalDominanceRatio
    ) -> Bool {
        let absX = abs(translation.width)
        let absY = abs(translation.height)
        return absX >= minimumDistance && absX > absY * dominanceRatio
    }
}
