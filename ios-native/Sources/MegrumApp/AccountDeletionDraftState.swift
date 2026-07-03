struct AccountDeletionDraftState: Equatable {
    var step: AccountDeletionStep = .warning
    var selectedReasons: Set<AccountDeletionReason> = []
    var note = ""
    var validationMessage: String?
    var showsFinalConfirmation = false

    mutating func toggle(_ reason: AccountDeletionReason) {
        if selectedReasons.contains(reason) {
            selectedReasons.remove(reason)
        } else {
            selectedReasons.insert(reason)
        }
    }

    mutating func setNote(_ value: String) {
        note = String(value.prefix(AccountDeletionDraftValidator.noteMaxLength))
    }

    mutating func clearValidationMessage() {
        validationMessage = nil
    }

    mutating func setOngoingTradeValidationMessage() {
        validationMessage = "現在進行中の取引があるため退会できません"
    }

    mutating func validateReasonsStep() -> Bool {
        if let message = AccountDeletionDraftValidator.validationMessage(
            reasons: Array(selectedReasons),
            note: note
        ) {
            validationMessage = message
            return false
        }
        return true
    }

    mutating func moveToReasonsStep() {
        step = .reasons
    }

    mutating func returnToWarningStep() {
        step = .warning
    }

    mutating func requestFinalConfirmation() {
        showsFinalConfirmation = true
    }

    var submissionInput: AccountDeletionRequestInput {
        AccountDeletionRequestInput(
            reasons: Array(selectedReasons),
            note: note
        ).normalized
    }
}
