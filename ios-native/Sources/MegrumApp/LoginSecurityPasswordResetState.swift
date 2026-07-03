import MegrumCore

struct LoginSecurityPasswordResetState: Equatable {
    var email = ""
    var inputErrorMessage: String?

    var normalizedEmail: String {
        MegrumAuthInputValidator.normalizedEmail(email)
    }

    mutating func clearInputFeedback() {
        inputErrorMessage = nil
    }

    mutating func prefillEmailIfNeeded(_ value: String) {
        guard email.isBlank else {
            return
        }
        email = value
    }

    mutating func validationMessageForSubmission() -> String? {
        inputErrorMessage = MegrumAuthInputValidator.passwordResetValidationMessage(email: normalizedEmail)
        return inputErrorMessage
    }
}
