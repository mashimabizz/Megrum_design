import SwiftUI

enum ProposalStepSwipeNavigator {
    static let minimumHorizontalDistance: CGFloat = 56
    static let horizontalPriorityRatio: CGFloat = 1.35

    static func destination(
        from currentStep: ProposalCreateStep,
        translationWidth: CGFloat,
        translationHeight: CGFloat,
        visibleSteps: [ProposalCreateStep]
    ) -> ProposalCreateStep? {
        let absX = abs(translationWidth)
        let absY = abs(translationHeight)
        guard absX >= minimumHorizontalDistance, absX >= absY * horizontalPriorityRatio else {
            return nil
        }
        guard let currentIndex = visibleSteps.firstIndex(of: currentStep) else {
            return nil
        }
        let destinationIndex = translationWidth < 0 ? currentIndex + 1 : currentIndex - 1
        guard visibleSteps.indices.contains(destinationIndex) else {
            return nil
        }
        return visibleSteps[destinationIndex]
    }
}
