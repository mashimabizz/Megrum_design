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

public final class SupabaseAuthClient: @unchecked Sendable {
    private let configuration: SupabaseConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

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
            expiresAt: payload.expiresAt,
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

    public func makePasswordSignInRequest(email: String, password: String) throws -> URLRequest {
        let payload = PasswordPayload(email: email, password: password)
        return try makeAuthRequest(
            path: "/auth/v1/token",
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            method: "POST",
            body: encoder.encode(payload),
            bearerToken: configuration.publishableKey
        )
    }

    public func makeSignUpRequest(
        email: String,
        password: String,
        metadata: SupabaseAuthProfileMetadata = SupabaseAuthProfileMetadata(),
        emailRedirectTo: URL? = nil
    ) throws -> URLRequest {
        let payload = SignUpPayload(
            email: email,
            password: password,
            data: SignUpMetadata(
                handle: metadata.handle,
                displayName: metadata.displayName ?? metadata.handle
            ),
            emailRedirectTo: emailRedirectTo?.absoluteString
        )
        return try makeAuthRequest(
            path: "/auth/v1/signup",
            method: "POST",
            body: encoder.encode(payload),
            bearerToken: configuration.publishableKey
        )
    }

    public func makeIDTokenSignInRequest(
        provider: SupabaseIDTokenProvider,
        idToken: String,
        accessToken: String? = nil,
        nonce: String? = nil
    ) throws -> URLRequest {
        let payload = IDTokenPayload(
            provider: provider.rawValue,
            idToken: idToken,
            accessToken: accessToken,
            nonce: nonce
        )
        return try makeAuthRequest(
            path: "/auth/v1/token",
            queryItems: [URLQueryItem(name: "grant_type", value: "id_token")],
            method: "POST",
            body: encoder.encode(payload),
            bearerToken: configuration.publishableKey
        )
    }

    public func makePasswordResetRequest(email: String, emailRedirectTo: URL? = nil) throws -> URLRequest {
        let payload = PasswordResetPayload(email: email)
        let queryItems = emailRedirectTo.map {
            [URLQueryItem(name: "redirect_to", value: $0.absoluteString)]
        } ?? []
        return try makeAuthRequest(
            path: "/auth/v1/recover",
            queryItems: queryItems,
            method: "POST",
            body: encoder.encode(payload),
            bearerToken: configuration.publishableKey
        )
    }

    public func makeSignOutRequest(accessToken: String) throws -> URLRequest {
        try makeAuthRequest(
            path: "/auth/v1/logout",
            method: "POST",
            body: Data(),
            bearerToken: accessToken
        )
    }

    public func makeUserRequest(accessToken: String) throws -> URLRequest {
        try makeAuthRequest(
            path: "/auth/v1/user",
            method: "GET",
            body: nil,
            bearerToken: accessToken
        )
    }

    private func performAuthRequest(_ request: URLRequest) async throws -> AuthSession {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseAuthError.unexpectedStatus(-1, nil)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = try? decoder.decode(AuthErrorResponse.self, from: data).message
            throw SupabaseAuthError.unexpectedStatus(httpResponse.statusCode, message)
        }
        return try decoder.decode(AuthResponse.self, from: data).session
    }

    private func makeAuthRequest(
        path: String,
        queryItems: [URLQueryItem] = [],
        method: String,
        body: Data?,
        bearerToken: String
    ) throws -> URLRequest {
        guard var components = URLComponents(url: configuration.projectURL, resolvingAgainstBaseURL: false) else {
            throw SupabaseAuthError.invalidURL
        }
        components.path = path.hasPrefix("/") ? path : "/\(path)"
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw SupabaseAuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
}

private struct PasswordPayload: Encodable {
    var email: String
    var password: String
}

private struct PasswordResetPayload: Encodable {
    var email: String
}

private struct SignUpPayload: Encodable {
    var email: String
    var password: String
    var data: SignUpMetadata
    var emailRedirectTo: String?

    enum CodingKeys: String, CodingKey {
        case email
        case password
        case data
        case emailRedirectTo = "email_redirect_to"
    }
}

private struct IDTokenPayload: Encodable {
    var provider: String
    var idToken: String
    var accessToken: String?
    var nonce: String?

    enum CodingKeys: String, CodingKey {
        case provider
        case idToken = "id_token"
        case accessToken = "access_token"
        case nonce
    }
}

private struct SignUpMetadata: Encodable {
    var handle: String?
    var displayName: String?

    enum CodingKeys: String, CodingKey {
        case handle
        case displayName = "display_name"
    }
}

private struct AuthResponse: Decodable {
    var accessToken: String
    var refreshToken: String?
    var expiresIn: Int?
    var expiresAt: Int?
    var tokenType: String?
    var user: UserResponse

    var session: AuthSession {
        AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn,
            expiresAt: expiresAt.map { Date(timeIntervalSince1970: TimeInterval($0)) },
            tokenType: tokenType ?? "bearer",
            user: user.authUser
        )
    }
}

private struct UserResponse: Decodable {
    var id: UUID
    var email: String?
    var createdAt: Date?

    var authUser: AuthUser {
        AuthUser(id: id, email: email, createdAt: createdAt)
    }
}

private struct AuthErrorResponse: Decodable {
    var msg: String?
    var message: String? {
        msg
    }
}
