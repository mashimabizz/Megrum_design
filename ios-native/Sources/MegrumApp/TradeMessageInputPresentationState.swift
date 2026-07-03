struct TradeMessageInputPresentationState: Equatable {
    var isComposerFocused = false

    mutating func setComposerFocused(_ focused: Bool) {
        isComposerFocused = focused
    }

    func shouldShowQuickActions(context: TradeMessageInputContext) -> Bool {
        context.shouldShowQuickActions(isComposerFocused: isComposerFocused)
    }
}
