struct HomeMutualMatchSelectedPreviewPresentationState: Equatable {
    var isShowingConditionHelp = false

    mutating func showConditionHelp() {
        isShowingConditionHelp = true
    }

    mutating func dismissConditionHelp() {
        isShowingConditionHelp = false
    }
}
