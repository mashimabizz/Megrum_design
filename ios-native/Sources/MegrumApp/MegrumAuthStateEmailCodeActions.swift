import Foundation
import MegrumCore
import MegrumData

/// メール確認コード（OTP）方式の認証アクション（iter1226.418）。
/// 新規登録＝コード検証で即ログイン。パスワード再設定＝コード検証→新パスワード設定→ログイン。
extension MegrumAuthState {
    static let emailCodeLength = 6

    static func normalizedEmailCode(_ code: String) -> String {
        code.filter(\.isNumber)
    }

    static func isValidEmailCode(_ code: String) -> Bool {
        normalizedEmailCode(code).count == emailCodeLength
    }

    /// 新規登録の確認コードを検証し、成功すればそのままログインする。
    @discardableResult
    public func verifySignUpCode(_ code: String) async -> Bool {
        guard let email = pendingSignUpCodeEmail else {
            return false
        }
        guard let session = await verifyEmailCode(code, email: email, purpose: .signUp) else {
            return false
        }
        pendingSignUpCodeEmail = nil
        activateSession(session)
        return true
    }

    /// パスワード再設定の確認コードを検証し、新パスワード入力へ進める。
    @discardableResult
    public func verifyRecoveryCode(_ code: String) async -> Bool {
        guard let email = pendingRecoveryCodeEmail else {
            return false
        }
        guard let session = await verifyEmailCode(code, email: email, purpose: .recovery) else {
            return false
        }
        recoverySession = session
        clearFeedback()
        return true
    }

    /// リカバリ検証済みセッションで新しいパスワードを設定し、そのままログインする。
    @discardableResult
    public func completePasswordReset(newPassword: String) async -> Bool {
        guard let session = recoverySession else {
            errorMessage = "確認コードの検証からやり直してください"
            return false
        }
        guard MegrumAuthInputValidator.isValidSignUpPassword(newPassword) else {
            errorMessage = MegrumAuthInputValidator.shortPasswordMessage
            successMessage = nil
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
                try await repository.updatePassword(session: session, newPassword: newPassword)
            }
            recoverySession = nil
            pendingRecoveryCodeEmail = nil
            successMessage = "パスワードを変更しました"
            activateSession(session)
            return true
        } catch {
            errorMessage = normalizedMessage(from: error, context: .passwordReset)
            return false
        }
    }

    /// 確認コードを再送する。
    public func resendPendingEmailCode(purpose: AuthEmailCodePurpose) async {
        let email: String?
        switch purpose {
        case .signUp:
            email = pendingSignUpCodeEmail
        case .recovery:
            email = pendingRecoveryCodeEmail
        }
        guard let email, !isLoading else {
            return
        }

        isLoading = true
        clearFeedback()
        defer {
            isLoading = false
        }

        let repository = repository
        do {
            try await withAuthTimeout(nanoseconds: authActionTimeoutNanoseconds) {
                try await repository.resendEmailCode(email: email, purpose: purpose)
            }
            successMessage = "確認コードを再送しました"
        } catch {
            errorMessage = normalizedMessage(from: error, context: purpose == .signUp ? .signUp : .passwordReset)
        }
    }

    /// コード入力を離れる時に保留状態を破棄する。
    public func cancelPendingEmailCode(purpose: AuthEmailCodePurpose) {
        switch purpose {
        case .signUp:
            pendingSignUpCodeEmail = nil
        case .recovery:
            pendingRecoveryCodeEmail = nil
            recoverySession = nil
        }
        clearFeedback()
    }

    private func verifyEmailCode(
        _ code: String,
        email: String,
        purpose: AuthEmailCodePurpose
    ) async -> AuthSession? {
        let normalized = Self.normalizedEmailCode(code)
        guard Self.isValidEmailCode(normalized) else {
            errorMessage = "6桁の確認コードを入力してください"
            successMessage = nil
            return nil
        }
        guard !isLoading else {
            return nil
        }

        isLoading = true
        clearFeedback()
        defer {
            isLoading = false
        }

        let repository = repository
        do {
            return try await withAuthTimeout(nanoseconds: authActionTimeoutNanoseconds) {
                try await repository.verifyEmailCode(email: email, code: normalized, purpose: purpose)
            }
        } catch {
            errorMessage = Self.isLikelyInvalidCodeError(error)
                ? "確認コードが正しくないか、期限切れです。再送してもう一度お試しください"
                : normalizedMessage(from: error, context: purpose == .signUp ? .signUp : .passwordReset)
            return nil
        }
    }

    /// GoTrue はコード不一致/期限切れを 401/403 otp_expired 等で返す。
    private static func isLikelyInvalidCodeError(_ error: Error) -> Bool {
        guard case let SupabaseAuthError.unexpectedStatus(status, message) = error else {
            return false
        }
        if status == 401 || status == 403 {
            return true
        }
        let lowered = (message ?? "").lowercased()
        return lowered.contains("otp") || lowered.contains("token") || lowered.contains("expired")
    }
}
