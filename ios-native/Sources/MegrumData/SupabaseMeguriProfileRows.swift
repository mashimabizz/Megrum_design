import Foundation
import MegrumCore

struct MeguriProfileRow: Decodable, Sendable {
    static let select = "user_id,display_name,avatar_id,avatar_url,uses_public_profile,last_changed_at,created_at,updated_at"

    var userId: UUID
    var displayName: String
    var avatarId: String?
    var avatarUrl: URL?
    var usesPublicProfile: Bool?
    var lastChangedAt: Date?
    var createdAt: Date?
    var updatedAt: Date?

    var profile: MeguriProfile {
        MeguriProfile(
            userID: userId,
            displayName: displayName,
            avatarID: SupabaseTextNormalizer.optional(avatarId) ?? "avatar_1",
            avatarURL: avatarUrl,
            usesPublicProfile: usesPublicProfile ?? false,
            lastChangedAt: lastChangedAt,
            createdAt: createdAt ?? .now,
            updatedAt: updatedAt ?? createdAt ?? .now
        )
    }
}

struct MeguriProfileSavePayload: Encodable, Sendable {
    var pDisplayName: String
    var pAvatarId: String
    var pAvatarUrl: String?
    var shouldEncodeAvatarUrl: Bool
    var pUsesPublicProfile: Bool

    init(input: MeguriProfileUpdateInput) {
        self.pDisplayName = SupabaseTextNormalizer.trimmed(input.displayName)
        self.pAvatarId = SupabaseTextNormalizer.trimmed(input.avatarID)
        self.pAvatarUrl = input.clearsAvatarURL
            ? nil
            : SupabaseTextNormalizer.optional(input.avatarURL?.absoluteString)
        self.shouldEncodeAvatarUrl = input.avatarUpload != nil
            || input.clearsAvatarURL
            || input.avatarURL != nil
        self.pUsesPublicProfile = input.usesPublicProfile
    }

    enum CodingKeys: String, CodingKey {
        case pDisplayName
        case pAvatarId
        case pAvatarUrl
        case pUsesPublicProfile
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pDisplayName, forKey: .pDisplayName)
        try container.encode(pAvatarId, forKey: .pAvatarId)
        if shouldEncodeAvatarUrl {
            if let pAvatarUrl {
                try container.encode(pAvatarUrl, forKey: .pAvatarUrl)
            } else {
                try container.encodeNil(forKey: .pAvatarUrl)
            }
        }
        try container.encode(pUsesPublicProfile, forKey: .pUsesPublicProfile)
    }
}

struct MeguriProfileUpsertPayload: Encodable, Sendable {
    var userID: UUID
    var displayName: String
    var avatarID: String
    var avatarURL: String?
    var shouldEncodeAvatarURL: Bool
    var usesPublicProfile: Bool

    init(userID: UUID, input: MeguriProfileUpdateInput) {
        self.userID = userID
        self.displayName = SupabaseTextNormalizer.trimmed(input.displayName)
        self.avatarID = SupabaseTextNormalizer.trimmed(input.avatarID)
        self.avatarURL = input.clearsAvatarURL
            ? nil
            : SupabaseTextNormalizer.optional(input.avatarURL?.absoluteString)
        self.shouldEncodeAvatarURL = input.avatarUpload != nil
            || input.clearsAvatarURL
            || input.avatarURL != nil
        self.usesPublicProfile = input.usesPublicProfile
    }

    enum CodingKeys: String, CodingKey {
        case userID
        case displayName
        case avatarID
        case avatarURL
        case usesPublicProfile
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(avatarID, forKey: .avatarID)
        if shouldEncodeAvatarURL {
            if let avatarURL {
                try container.encode(avatarURL, forKey: .avatarURL)
            } else {
                try container.encodeNil(forKey: .avatarURL)
            }
        }
        try container.encode(usesPublicProfile, forKey: .usesPublicProfile)
    }
}
