struct DisputeDetailPresentationState: Equatable {
    var presentedRequestKind: TradeRequestKind?
    var isShowingWithdrawConfirmation = false

    mutating func requestWithdrawConfirmation() {
        isShowingWithdrawConfirmation = true
    }

    mutating func openLateRequest() {
        presentedRequestKind = .late
    }

    mutating func openCancellationRequest() {
        presentedRequestKind = .cancellation
    }
}
