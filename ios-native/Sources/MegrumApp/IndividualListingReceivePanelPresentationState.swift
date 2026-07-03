struct IndividualListingReceivePanelPresentationState: Equatable {
    var isShowingOptionBreakdown = false

    mutating func showOptionBreakdown() {
        isShowingOptionBreakdown = true
    }

    mutating func dismissOptionBreakdown() {
        isShowingOptionBreakdown = false
    }
}
