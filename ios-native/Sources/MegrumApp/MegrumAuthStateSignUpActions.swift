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
                successMessage = "確認メールを送信しました。メール内のリンクで認証を完了してからログインしてください"
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
            passwordResetMessage = "再設定メールを送信しました。受信メールを確認してください"
            successMessage = passwordResetMessage
            return true
        } catch {
            errorMessage = normalizedMessage(from: error, context: .passwordReset)
            return false
        }
    }
}
