import Foundation
import MegrumCore

public enum SupabaseAuthError: Error, Equatable, Sendable {
    case invalidURL
    case unexpectedStatus(Int, String?)
}

public struct SupabaseAuthProfileMetadata: Equatable, Sendable {
    public var handle: String?
    public var displayName: String?

    public init(handle: String? = nil, displayName: String? = nil) {
        self.handle = handle
        self.displayName = displayName
    }
}

public enum SupabaseIDTokenProvider: String, Equatable, Sendable {
    case apple
    case google
    case facebook
}

public enum SupabaseOAuthProvider: String, Equatable, Sendable {
    case google
}

public final class SupabaseAuthClient: @unchecked Sendable {
    let configuration: SupabaseConfiguration
    let session: URLSession
    let decoder: JSONDecoder
    let encoder: JSONEncoder

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.encoder = JSONEncoder()
    }

    public func signIn(email: String, password: String) async throws -> AuthSession {
        let request = try makePasswordSignInRequest(email: email, password: password)
        return try await performAuthRequest(request)
    }

    public func refreshSession(refreshToken: String) async throws -> AuthSession {
        let request = try makeRefreshSessionRequest(refreshToken: refreshToken)
        return try await performAuthRequest(request)
    }

    public func signUp(
        email: String,
        password: String,
        metadata: SupabaseAuthProfileMetadata = SupabaseAuthProfileMetadata(),
        emailRedirectTo: URL? = nil
    ) async throws -> AuthSession {
        let request = try makeSignUpRequest(
            email: email,
            password: password,
            metadata: metadata,
            emailRedirectTo: emailRedirectTo
        )
        return try await performAuthRequest(request)
    }

    public func signInWithIDToken(
        provider: SupabaseIDTokenProvider,
        idToken: String,
        accessToken: String? = nil,
        nonce: String? = nil
    ) async throws -> AuthSession {
        let request = try makeIDTokenSignInRequest(
            provider: provider,
            idToken: idToken,
            accessToken: accessToken,
            nonce: nonce
        )
        return try await performAuthRequest(request)
    }

    public func sendPasswordReset(email: String, emailRedirectTo: URL? = nil) async throws {
        let request = try makePasswordResetRequest(email: email, emailRedirectTo: emailRedirectTo)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseAuthError.unexpectedStatus(-1, nil)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = try? decoder.decode(AuthErrorResponse.self, from: data).message
            throw SupabaseAuthError.unexpectedStatus(httpResponse.statusCode, message)
        }
    }

    public func signOut(accessToken: String) async throws {
        let request = try makeSignOutRequest(accessToken: accessToken)
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseAuthError.unexpectedStatus(-1, nil)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SupabaseAuthError.unexpectedStatus(httpResponse.statusCode, nil)
        }
    }

    public func session(fromRedirectURL url: URL) async throws -> AuthSession? {
        guard let payload = SupabaseAuthRedirectParser.parse(url) else {
            return nil
        }
        let user = try await loadUser(accessToken: payload.accessToken)
        return AuthSession(
            accessToken: payload.accessToken,
            refreshToken: payload.refreshToken,
            expiresIn: payload.expiresIn,
            expiresAt: payload.expiresAt ?? payload.expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) },
            tokenType: payload.tokenType,
            user: user
        )
    }

    public func loadUser(accessToken: String) async throws -> AuthUser {
        let request = try makeUserRequest(accessToken: accessToken)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseAuthError.unexpectedStatus(-1, nil)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = try? decoder.decode(AuthErrorResponse.self, from: data).message
            throw SupabaseAuthError.unexpectedStatus(httpResponse.statusCode, message)
        }
        return try decoder.decode(UserResponse.self, from: data).authUser
    }
}
