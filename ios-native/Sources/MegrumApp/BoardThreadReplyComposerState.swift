import Foundation

struct BoardThreadReplyComposerState: Equatable {
    var draftReply = ""

    var trimmedReply: String {
        draftReply.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func replyBodyForSubmission(isSending: Bool) -> String? {
        guard !trimmedReply.isEmpty, !isSending else {
            return nil
        }
        return trimmedReply
    }

    mutating func clearDraftAfterSend(succeeded: Bool) {
        if succeeded {
            draftReply = ""
        }
    }
}
