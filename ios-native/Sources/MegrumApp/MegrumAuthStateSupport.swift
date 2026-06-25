import Foundation
import MegrumData

enum MegrumAuthStateError: Error {
    case timedOut
}

extension MegrumAuthState {
    func withAuthTimeout<T: Sendable>(
        nanoseconds: UInt64,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: nanoseconds)
                throw MegrumAuthStateError.timedOut
            }

            guard let result = try await group.next() else {
                throw MegrumAuthStateError.timedOut
            }
            group.cancelAll()
            return result
        }
    }

    func isLikelyEmailConfirmationRequiredAfterSignUp(_ error: Error) -> Bool {
        if case SupabaseAuthError.emailConfirmationRequired = error {
            return true
        }
        if case let DecodingError.keyNotFound(key, _) = error, key.stringValue == "access_token" {
            return true
        }
        if case let DecodingError.keyNotFound(key, _) = error, key.stringValue == "accessToken" {
            return true
        }
        if case let SupabaseAuthError.unexpectedStatus(_, message) = error,
           let message,
           message.localizedCaseInsensitiveContains("confirm") {
            return true
        }
        return false
    }

    func normalizedMessage(from error: Error) -> String {
        if case let SupabaseAuthError.unexpectedStatus(_, message) = error, let message {
            if message.contains("Invalid login credentials") {
                return "メールアドレスまたはパスワードが正しくありません"
            }
            if message.contains("Email not confirmed") {
                return "メール認証が完了していません。受信メールを確認してください"
            }
            if message.localizedCaseInsensitiveContains("already registered") {
                return "このメールアドレスはすでに登録されています"
            }
            if message.localizedCaseInsensitiveContains("invalid email")
                || message.localizedCaseInsensitiveContains("validate email") {
                return "有効なメールアドレスを入力してください"
            }
            if message.localizedCaseInsensitiveContains("password")
                && message.localizedCaseInsensitiveContains("at least") {
                return "パスワードは8文字以上で入力してください"
            }
            if message.localizedCaseInsensitiveContains("rate limit")
                || message.localizedCaseInsensitiveContains("security purposes") {
                return "送信間隔が短すぎます。しばらく待ってから再度お試しください"
            }
            return message
        }
        if case MegrumRepositoryError.unsupportedMutation = error {
            return "このログイン方法はまだ利用できません"
        }
        if case MegrumAuthStateError.timedOut = error {
            return "通信に時間がかかっています。接続を確認してもう一度お試しください"
        }
        return "認証に失敗しました。時間をおいてもう一度お試しください"
    }
}
