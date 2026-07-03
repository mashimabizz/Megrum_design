import Foundation

struct TradeDetailRoutePresentationState {
    var isShowingEvidenceList = false
    var isShowingEvaluationPage = false
    var isShowingDisputePage = false
    var isShowingRejectConfirmation = false
    var isShowingCounterProposalPage = false
    var isShowingSchedulePage = false
    var unavailableChatAction: TradeUnavailableChatAction?
    var assistanceRequestKind: TradeAssistanceRequestKind?
    var selectedRemoteImage: RemoteImageSelection?
    var disputeDetailRoute: TradeDisputeDetailRoute?
    var partnerProfileRoute: TradePartnerProfileRoute?

    mutating func showEvidenceList() {
        isShowingEvidenceList = true
    }

    mutating func selectRemoteImage(_ selection: RemoteImageSelection) {
        selectedRemoteImage = selection
    }

    mutating func clearSelectedRemoteImage() {
        selectedRemoteImage = nil
    }
}
