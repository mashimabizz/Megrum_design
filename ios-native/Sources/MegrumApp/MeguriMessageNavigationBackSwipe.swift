import CoreGraphics

enum MeguriMessageNavigationBackSwipeResolver {
    static func shouldTrigger(
        translation: CGSize,
        predictedEndTranslationWidth: CGFloat,
        screenWidth: CGFloat = InteractiveBackSwipeResolver.defaultScreenWidth
    ) -> Bool {
        InteractiveBackSwipeResolver.shouldTrigger(
            translation: translation,
            predictedEndTranslationWidth: predictedEndTranslationWidth,
            screenWidth: screenWidth
        )
    }
}
