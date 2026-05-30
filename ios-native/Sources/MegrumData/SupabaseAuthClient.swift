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

    public func makeSignOutRequest(accessToken: String) throws -> URLRequest {
        try makeAuthRequest(
            path: "/auth/v1/logout",
            method: "POST",
            body: Data(),
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
