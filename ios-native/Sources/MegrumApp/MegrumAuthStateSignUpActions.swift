import Foundation
import MegrumCore

extension MegrumAuthState {
    public func signUp(email: String, password: String, handle: String?) async {
        guard !isLoading else {
            return
        }
        let trimmedEmail = MegrumAuthInputValidator.normalizedEmail(email)
        guard MegrumAuthInputValidator.isValidEmail(trimmedEmail) else {
            errorMessage = "有効なメールアドレスを入力してください"
            successMessage = nil
            passwordResetMessage = nil
            return
        }
        guard MegrumAuthInputValidator.isValidSignUpPassword(password) else {
            errorMessage = "パスワードは8文字以上で入力してください"
            successMessage = nil
            passwordResetMessage = nil
            return
        }
        guard MegrumAuthInputValidator.isValidHandle(handle) else {
            errorMessage = "ユーザーIDは3〜24文字の英数字と_で入力してください"
            successMessage = nil
            passwordResetMessage = nil
            return
        }
        let trimmedHandle = MegrumAuthInputValidator.normalizedHandle(handle)

        isLoading = true
        clearFeedback()
        defer {
            isLoading = false
        }

        let repository = repository
        do {
            let nextSession = try await withAuthTimeout(nanoseconds: authActionTimeoutNanoseconds) {
                try await repository.signUp(
                    AuthSignUpInput(
                        email: trimmedEmail,
                        password: password,
                        handle: trimmedHandle
                    )
                )
            }
            activateSession(nextSession)
        } catch {
            if isLikelyEmailConfirmationRequiredAfterSignUp(error) {
                // リンクではなく確認コード方式（iter1226.418）：コード入力画面へ誘導する。
                pendingSignUpCodeEmail = trimmedEmail
                successMessage = "確認コードをメールに送信しました。届いた6桁のコードを入力してください"
                return
            }
            errorMessage = normalizedMessage(from: error, context: .signUp)
        }
    }

    @discardableResult
    public func sendPasswordReset(email: String) async -> Bool {
        guard !isLoading else {
            return false
        }
        let trimmedEmail = MegrumAuthInputValidator.normalizedEmail(email)
        guard MegrumAuthInputValidator.isValidEmail(trimmedEmail) else {
            errorMessage = "有効なメールアドレスを入力してください"
            successMessage = nil
            passwordResetMessage = nil
            return false
        }

        isLoading = true
        clearFeedback()
        defer {
            isLoading = false
        }

        let repository = repository
        do {
            try await withAuthTimeout(nanoseconds: authActionTimeoutNanoseconds) {
                try await repository.sendPasswordReset(email: trimmedEmail)
            }
            // リンクではなく確認コード方式（iter1226.418）：コード入力画面へ誘導する。
            pendingRecoveryCodeEmail = trimmedEmail
            passwordResetMessage = "確認コードをメールに送信しました。届いた6桁のコードを入力してください"
            successMessage = passwordResetMessage
            return true
        } catch {
            errorMessage = normalizedMessage(from: error, context: .passwordReset)
            return false
        }
    }
}
