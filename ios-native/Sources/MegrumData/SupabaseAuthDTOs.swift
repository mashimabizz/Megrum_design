import Foundation
import MegrumCore

struct PasswordPayload: Encodable {
    var email: String
    var password: String
}

struct RefreshTokenPayload: Encodable {
    var refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct PasswordResetPayload: Encodable {
    var email: String
}

struct SignUpPayload: Encodable {
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

struct IDTokenPayload: Encodable {
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

struct SignUpMetadata: Encodable {
    var handle: String?
    var displayName: String?

    enum CodingKeys: String, CodingKey {
        case handle
        case displayName = "display_name"
    }
}

struct AuthResponse: Decodable {
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
            expiresAt: expiresAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
                ?? expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) },
            tokenType: tokenType ?? "bearer",
            user: user.authUser
        )
    }
}

struct UserResponse: Decodable {
    var id: UUID
    var email: String?
    var createdAt: Date?

    var authUser: AuthUser {
        AuthUser(id: id, email: email, createdAt: createdAt)
    }
}

struct AuthErrorResponse: Decodable {
    var msg: String?
    var messageText: String?
    var errorDescription: String?
    var error: String?

    var message: String? {
        [msg, messageText, errorDescription, error]
            .compactMap(SupabaseTextNormalizer.optional)
            .first
    }

    enum CodingKeys: String, CodingKey {
        case msg
        case messageText = "message"
        case errorDescription
        case error
    }
}
