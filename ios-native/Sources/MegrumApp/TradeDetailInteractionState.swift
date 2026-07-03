import Foundation

struct TradeDetailInteractionState: Equatable {
    var draftMessage = ""
    var isWaitingToShareLocation = false
    var didSubmitEvaluation = false
    var toastMessage: String?
    var isMessageComposerFocused = false

    mutating func clearDraftAfterSend(succeeded: Bool) {
        if succeeded {
            draftMessage = ""
        }
    }

    mutating func startWaitingForLocation() {
        isWaitingToShareLocation = true
    }

    mutating func consumeLocationCoordinate(_ coordinate: MegrumLocationCoordinate?) -> MegrumLocationCoordinate? {
        guard isWaitingToShareLocation, let coordinate else {
            return nil
        }
        isWaitingToShareLocation = false
        return coordinate
    }

    mutating func consumeLocationError(_ errorMessage: String?) -> Bool {
        guard isWaitingToShareLocation, errorMessage != nil else {
            return false
        }
        isWaitingToShareLocation = false
        return true
    }

    mutating func markEvaluationSubmitted() {
        didSubmitEvaluation = true
    }

    mutating func showToast(_ message: String) {
        toastMessage = message
    }

    mutating func clearToast(ifMatching message: String) {
        if toastMessage == message {
            toastMessage = nil
        }
    }
}
