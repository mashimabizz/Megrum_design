struct AuthScreenEmailSubmissionInput: Equatable {
    var email: String
    var password: String
    var handle: String
}

struct AuthScreenInputState: Equatable {
    var email = ""
    var password = ""
    var handle = ""
    var passwordResetEmail = ""
    var hasSubmittedPasswordReset = false
    var passwordResetInputErrorMessage: String?
    var identityProviderError: String?
    var inputErrorMessage: String?

    mutating func preparePasswordResetRoute() {
        passwordResetEmail = MegrumAuthInputValidator.normalizedEmail(email)
        hasSubmittedPasswordReset = false
        passwordResetInputErrorMessage = nil
    }

    mutating func passwordResetEmailChanged() {
        hasSubmittedPasswordReset = false
        passwordResetInputErrorMessage = nil
    }

    mutating func validatedPasswordResetEmail() -> String? {
        hasSubmittedPasswordReset = true
        let normalizedEmail = MegrumAuthInputValidator.normalizedEmail(passwordResetEmail)
        identityProviderError = nil
        inputErrorMessage = nil
        passwordResetInputErrorMessage = nil
        if let validationMessage = MegrumAuthInputValidator.passwordResetValidationMessage(email: normalizedEmail) {
            passwordResetInputErrorMessage = validationMessage
            return nil
        }

        email = normalizedEmail
        return normalizedEmail
    }

    mutating func validatedEmailSubmissionInput(mode: AuthScreenMode) -> AuthScreenEmailSubmissionInput? {
        identityProviderError = nil
        email = MegrumAuthInputValidator.normalizedEmail(email)
        if mode == .signUp {
            handle = MegrumAuthInputValidator.normalizedHandle(handle) ?? ""
        }
        inputErrorMessage = validationMessage(mode: mode)
        guard inputErrorMessage == nil else {
            return nil
        }

        return AuthScreenEmailSubmissionInput(email: email, password: password, handle: handle)
    }

    mutating func clearFeedback() {
        inputErrorMessage = nil
        identityProviderError = nil
    }

    func validationMessage(mode: AuthScreenMode) -> String? {
        switch mode {
        case .signIn:
            MegrumAuthInputValidator.signInValidationMessage(email: email, password: password)
        case .signUp:
            MegrumAuthInputValidator.signUpValidationMessage(email: email, password: password, handle: handle)
        }
    }
}
