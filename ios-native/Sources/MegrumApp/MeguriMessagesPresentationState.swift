struct MeguriMessagesPresentationState: Equatable {
    var draft = ""
    var isShowingMegrumPlusPrompt = false
    var isShowingMegrumPlus = false
    var didShowInitialMegrumPlusPrompt = false
    var reportTarget: PublicProfileModerationTarget?
    var blockTarget: PublicProfileModerationTarget?

    mutating func clearDraftAfterSend(_ sent: Bool) {
        guard sent else {
            return
        }
        draft = ""
    }

    mutating func showInitialMegrumPlusPrompt() {
        guard !didShowInitialMegrumPlusPrompt else {
            return
        }
        didShowInitialMegrumPlusPrompt = true
        showMegrumPlusPrompt()
    }

    mutating func showMegrumPlusPrompt() {
        isShowingMegrumPlusPrompt = true
    }

    mutating func showMegrumPlus() {
        isShowingMegrumPlus = true
    }

    mutating func updateBlockConfirmationPresentation(_ isPresented: Bool) {
        if !isPresented {
            blockTarget = nil
        }
    }
}
