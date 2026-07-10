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
            // 確認コード方式（iter1226.418）：送信できたらコード入力へ。
            if authState.pendingRecoveryCodeEmail != nil {
                route = .recoveryCode
            }
        }
    }

    // MARK: - 確認コード（iter1226.418）

    func verifySignUpCodeFromButton(_ code: String) {
        Task {
            await authState.verifySignUpCode(code)
            // 成功時は session が入り、ルート側で認証後画面へ切り替わる。
        }
    }

    func verifyRecoveryCodeFromButton(_ code: String) {
        Task {
            if await authState.verifyRecoveryCode(code) {
                inputState.password = ""
                route = .newPassword
            }
        }
    }

    func completeNewPasswordFromButton() {
        Task {
            _ = await authState.completePasswordReset(newPassword: inputState.password)
        }
    }

    func resendEmailCodeFromButton(purpose: AuthEmailCodePurpose) {
        Task {
            await authState.resendPendingEmailCode(purpose: purpose)
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

        // 確認コード方式（iter1226.418）：コード入力待ちになったら入力画面へ。
        // ログインでメール未確認を検出した場合もここに入る。
        if authState.pendingSignUpCodeEmail != nil {
            route = .signUpCode
        }
    }

    func clearFeedback() {
        inputState.clearFeedback()
        authState.clearFeedback()
    }
}
