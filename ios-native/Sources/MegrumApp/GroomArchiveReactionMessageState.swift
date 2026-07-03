import Foundation
import MegrumCore

struct GroomArchiveReactionMessageTarget: Identifiable, Equatable {
    var id: UUID {
        userID
    }

    var userID: UUID
    var displayName: String
    var sourceGroom: GroomPost
    var sourceGroomReplyID: UUID?
    var suggestedBody: String
}

struct GroomArchiveReactionMessageDraftState: Equatable {
    var target: GroomArchiveReactionMessageTarget?
    var draft = ""
    var isShowingMegrumPlusPrompt = false
    var isShowingMegrumPlus = false

    var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    mutating func compose(to target: GroomArchiveReactionMessageTarget) {
        self.target = target
        self.draft = target.suggestedBody
    }

    mutating func clearAfterSend(_ sent: Bool) {
        guard sent else {
            return
        }
        target = nil
        draft = ""
    }

    mutating func dismiss() {
        target = nil
        draft = ""
    }

    mutating func showMegrumPlusPrompt() {
        isShowingMegrumPlusPrompt = true
    }

    mutating func showMegrumPlus() {
        isShowingMegrumPlus = true
    }
}
