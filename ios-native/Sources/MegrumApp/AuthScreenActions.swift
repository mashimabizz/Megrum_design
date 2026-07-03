import SwiftUI

extension AuthScreen {
    func setRoute(_ nextRoute: AuthFlowRoute) {
        route = nextRoute
        if nextRoute == .passwordReset {
            inputState.preparePasswordResetRoute()
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
        inputState.passwordResetEmailChanged()
        authState.clearFeedback()
    }

    func sendPasswordReset() async {
        guard let normalizedEmail = inputState.validatedPasswordResetEmail() else {
            authState.clearFeedback()
            return
        }

        let sent = await authState.sendPasswordReset(email: normalizedEmail)
        if sent {
            focusedField = nil
        }
    }

    func submit() async {
        focusedField = nil
        guard let input = inputState.validatedEmailSubmissionInput(mode: mode) else {
            authState.clearFeedback()
            return
        }

        switch mode {
        case .signIn:
            await authState.signIn(email: input.email, password: input.password)
        case .signUp:
            await authState.signUp(email: input.email, password: input.password, handle: input.handle)
        }
    }

    func clearFeedback() {
        inputState.clearFeedback()
        authState.clearFeedback()
    }
}
