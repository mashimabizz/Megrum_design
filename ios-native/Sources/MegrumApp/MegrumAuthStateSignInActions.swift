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
