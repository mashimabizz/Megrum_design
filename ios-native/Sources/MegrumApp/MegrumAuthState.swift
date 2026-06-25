import Foundation
import MegrumCore
import MegrumData

@MainActor
public final class MegrumAuthState: ObservableObject {
    @Published public internal(set) var session: AuthSession?
    @Published public internal(set) var isLoading = false
    @Published public internal(set) var errorMessage: String?
    @Published public internal(set) var successMessage: String?
    @Published public internal(set) var passwordResetMessage: String?

    public let isConfigured: Bool
    let repository: any MegrumAuthRepository
    let sessionStore: any AuthSessionStore
    let authActionTimeoutNanoseconds: UInt64
    let signOutTimeoutNanoseconds: UInt64

    public init(
        repository: any MegrumAuthRepository,
        sessionStore: any AuthSessionStore = InMemoryAuthSessionStore(),
        initialSession: AuthSession? = nil,
        authActionTimeoutNanoseconds: UInt64 = 20_000_000_000,
        signOutTimeoutNanoseconds: UInt64 = 8_000_000_000
    ) {
        self.repository = repository
        self.sessionStore = sessionStore
        self.isConfigured = repository.isConfigured
        self.authActionTimeoutNanoseconds = authActionTimeoutNanoseconds
        self.signOutTimeoutNanoseconds = signOutTimeoutNanoseconds
        if let initialSession {
            self.session = initialSession
        } else {
            do {
                self.session = try sessionStore.load()
            } catch {
                self.session = nil
                try? sessionStore.clear()
            }
        }
    }

    public var isAuthenticated: Bool {
        session != nil
    }

    public var oauthCallbackScheme: String? {
        repository.oauthCallbackScheme
    }

    public func clearFeedback() {
        errorMessage = nil
        successMessage = nil
        passwordResetMessage = nil
    }

    func runAuthAction(_ action: @escaping @Sendable () async throws -> AuthSession) async {
        isLoading = true
        clearFeedback()
        defer {
            isLoading = false
        }

        do {
            let nextSession = try await withAuthTimeout(
                nanoseconds: authActionTimeoutNanoseconds,
                operation: action
            )
            activateSession(nextSession)
        } catch {
            errorMessage = normalizedMessage(from: error)
        }
    }

    func activateSession(_ nextSession: AuthSession) {
        session = nextSession
        do {
            try sessionStore.save(nextSession)
        } catch {
            successMessage = "ログインしました。ただし保存に失敗したため、次回起動時は再ログインが必要な場合があります"
        }
    }
}
