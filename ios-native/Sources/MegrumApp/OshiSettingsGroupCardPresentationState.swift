struct OshiSettingsGroupCardPresentationState: Equatable {
    var canConfirmRemoval = false

    mutating func prepareRemoveConfirmation() {
        canConfirmRemoval = false
    }

    mutating func enableRemoveConfirmation() {
        canConfirmRemoval = true
    }

    mutating func hideRemoveConfirmation() {
        canConfirmRemoval = false
    }
}
