import SwiftUI

extension AuthScreen {
    func setRoute(_ nextRoute: AuthFlowRoute) {
        route = nextRoute
        if nextRoute == .passwordReset {
            passwordResetEmail = MegrumAuthInputValidator.normalizedEmail(email)
            hasSubmittedPasswordReset = false
            passwordResetInputErrorMessage = nil
        }
        clearFeedback()
        focusedField = nil
    }

    func submitFromButton() {
        Task { await submit() }
    }

    func sendPasswordResetFromButton() {
        Task { await sendPasswordReset() }
    }

    func handlePasswordResetEmailChanged() {
        hasSubmittedPasswordReset = false
        passwordResetInputErrorMessage = nil
        authState.clearFeedback()
    }

    func sendPasswordReset() async {
        hasSubmittedPasswordReset = true
        let normalizedEmail = MegrumAuthInputValidator.normalizedEmail(passwordResetEmail)
        identityProviderError = nil
        inputErrorMessage = nil
        passwordResetInputErrorMessage = nil
        if let validationMessage = MegrumAuthInputValidator.passwordResetValidationMessage(email: normalizedEmail) {
            authState.clearFeedback()
            passwordResetInputErrorMessage = validationMessage
            return
        }

        email = normalizedEmail
        let sent = await authState.sendPasswordReset(email: normalizedEmail)
        if sent {
            focusedField = nil
        }
    }

    func submit() async {
        focusedField = nil
        identityProviderError = nil
        email = MegrumAuthInputValidator.normalizedEmail(email)
        if mode == .signUp {
            handle = MegrumAuthInputValidator.normalizedHandle(handle) ?? ""
        }
        inputErrorMessage = validationMessage
        guard inputErrorMessage == nil else {
            authState.clearFeedback()
            return
        }

        switch mode {
        case .signIn:
            await authState.signIn(email: email, password: password)
        case .signUp:
            await authState.signUp(email: email, password: password, handle: handle)
        }
    }

    func clearFeedback() {
        inputErrorMessage = nil
        identityProviderError = nil
        authState.clearFeedback()
    }
}
