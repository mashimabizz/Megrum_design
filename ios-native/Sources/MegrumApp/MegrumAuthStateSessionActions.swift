import Foundation
import MegrumData

extension MegrumAuthState {
    public func enterPreview() {
        session = PreviewMegrumAuthRepository.previewSession()
        clearFeedback()
    }

    @discardableResult
    public func refreshSessionIfNeeded(now: Date = .now, leeway: TimeInterval = 300) async -> Bool {
        guard let currentSession = session else {
            return false
        }
        guard currentSession.shouldRefresh(now: now, leeway: leeway) else {
            return true
        }
        guard !isLoading else {
            return false
        }

        isLoading = true
        clearFeedback()
        defer {
            isLoading = false
        }

        let repository = repository
        do {
            let refreshedSession = try await withAuthTimeout(nanoseconds: authActionTimeoutNanoseconds) {
                try await repository.refreshSession(currentSession)
            }
            activateSession(refreshedSession, source: sessionSource)
            return true
        } catch {
            // リフレッシュトークン自体が無効（失効・取り消し）の場合は、
            // 期限切れセッションのままエラー画面に固定せず、サインインからやり直してもらう。
            if let status = (error as? SupabaseRESTError)?.statusCode,
               (400...403).contains(status) {
                session = nil
                sessionSource = .none
                try? sessionStore.clear()
                errorMessage = "ログインの有効期限が切れました。もう一度ログインしてください"
                return false
            }
            errorMessage = "ログイン情報を更新できませんでした。接続を確認して再読み込みしてください"
            return false
        }
    }

    @discardableResult
    public func handleOpenURL(_ url: URL) async -> Bool {
        guard !isLoading else {
            return false
        }

        isLoading = true
        clearFeedback()
        defer {
            isLoading = false
        }

        let repository = repository
        do {
            guard let nextSession = try await withAuthTimeout(nanoseconds: authActionTimeoutNanoseconds, operation: {
                try await repository.restoreSession(fromRedirectURL: url)
            }) else {
                return false
            }
            activateSession(nextSession, source: .interactive)
            return true
        } catch {
            errorMessage = normalizedMessage(from: error)
            return false
        }
    }

    public func signOut() async {
        let currentSession = session
        isLoading = true
        clearFeedback()
        session = nil
        sessionSource = .none

        do {
            try sessionStore.clear()
            successMessage = "ログアウトしました"
        } catch {
            errorMessage = "端末からログアウトしましたが、保存情報の削除に失敗しました。アプリを再起動してからもう一度お試しください"
        }
        isLoading = false

        guard let currentSession else {
            return
        }

        let repository = repository
        do {
            try await withAuthTimeout(nanoseconds: signOutTimeoutNanoseconds) {
                try await repository.signOut(session: currentSession)
            }
        } catch {
            // Remote sign-out must not trap the user in the authenticated shell.
        }
    }
}
