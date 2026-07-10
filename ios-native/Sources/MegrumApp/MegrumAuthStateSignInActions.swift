import Foundation
import MegrumCore
import MegrumData

extension MegrumAuthState {
    public func signIn(email: String, password: String) async {
        guard !isLoading else {
            return
        }
        let trimmedEmail = MegrumAuthInputValidator.normalizedEmail(email)
        if let validationMessage = MegrumAuthInputValidator.signInValidationMessage(
            email: trimmedEmail,
            password: password
        ) {
            errorMessage = validationMessage
            successMessage = nil
            passwordResetMessage = nil
            return
        }

        let repository = repository
        await runAuthAction {
            try await repository.signIn(email: trimmedEmail, password: password)
        }

        // メール未確認のままログインした場合は確認コード入力へ誘導（コードも再送）。iter1226.418。
        if session == nil, Self.isEmailNotConfirmedError(message: errorMessage) {
            pendingSignUpCodeEmail = trimmedEmail
            try? await repository.resendEmailCode(email: trimmedEmail, purpose: .signUp)
            errorMessage = nil
            successMessage = "メール認証が未完了です。確認コードを再送したので入力してください"
        }
    }

    /// GoTrue の「Email not confirmed」を検出する（normalizedMessage 通過後の文字列でも拾う）。
    private static func isEmailNotConfirmedError(message: String?) -> Bool {
        let lowered = (message ?? "").lowercased()
        return lowered.contains("not confirmed")
            || lowered.contains("email_not_confirmed")
            || lowered.contains("メール認証が完了していません")
    }

    public func signInWithApple(idToken: String, nonce: String, fullName: String?) async {
        guard !isLoading else {
            return
        }
        let trimmedIDToken = idToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNonce = nonce.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedIDToken.isEmpty, !trimmedNonce.isEmpty else {
            errorMessage = "Appleログイン情報を取得できませんでした。もう一度お試しください"
            successMessage = nil
            passwordResetMessage = nil
            return
        }

        let repository = repository
        await runAuthAction {
            try await repository.signInWithApple(
                idToken: trimmedIDToken,
                nonce: trimmedNonce,
                fullName: fullName.nilIfBlank
            )
        }
    }

    public func googleOAuthAuthorizeURL() throws -> URL {
        guard isConfigured else {
            throw MegrumRepositoryError.unsupportedMutation
        }
        return try repository.googleOAuthAuthorizeURL()
    }
}
