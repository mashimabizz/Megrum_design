import Foundation

public struct AuthUser: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var email: String?
    public var createdAt: Date?

    public init(id: UUID, email: String? = nil, createdAt: Date? = nil) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
    }
}

public struct AuthSession: Codable, Hashable, Sendable {
    public var accessToken: String
    public var refreshToken: String?
    public var expiresIn: Int?
    public var expiresAt: Date?
    public var tokenType: String
    public var user: AuthUser

    private enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case expiresIn
        case expiresAt
        case tokenType
        case user
    }

    public init(
        accessToken: String,
        refreshToken: String? = nil,
        expiresIn: Int? = nil,
        expiresAt: Date? = nil,
        tokenType: String = "bearer",
        user: AuthUser
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.expiresAt = expiresAt
        self.tokenType = tokenType
        self.user = user
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        expiresIn = try container.decodeIfPresent(Int.self, forKey: .expiresIn)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        tokenType = try container.decodeIfPresent(String.self, forKey: .tokenType) ?? "bearer"
        user = try container.decode(AuthUser.self, forKey: .user)
    }

    public var authorizationHeaderValue: String {
        "Bearer \(accessToken)"
    }

    public func shouldRefresh(now: Date = .now, leeway: TimeInterval = 300) -> Bool {
        guard refreshToken?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return false
        }
        guard let expiresAt else {
            return true
        }
        return expiresAt.timeIntervalSince(now) <= leeway
    }
}
