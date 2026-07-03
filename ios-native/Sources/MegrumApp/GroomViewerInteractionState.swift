import Foundation

struct GroomViewerInteractionState: Equatable {
    var replyDraft = ""
    var isShowingReportConfirmation = false
    var isShowingBlockConfirmation = false

    var trimmedReply: String {
        replyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func replyBodyForSubmission(isSending: Bool) -> String? {
        guard !trimmedReply.isEmpty, !isSending else {
            return nil
        }
        return trimmedReply
    }

    mutating func clearReplyAfterSend(succeeded: Bool) {
        if succeeded {
            replyDraft = ""
        }
    }

    mutating func showReportConfirmation() {
        isShowingReportConfirmation = true
    }

    mutating func showBlockConfirmation() {
        isShowingBlockConfirmation = true
    }
}
