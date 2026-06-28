import Foundation
import MegrumCore

struct MeguriProfileRow: Decodable, Sendable {
    static let select = "user_id,display_name,avatar_id,last_changed_at,created_at,updated_at"

    var userId: UUID
    var displayName: String
    var avatarId: String?
    var lastChangedAt: Date?
    var createdAt: Date?
    var updatedAt: Date?

    var profile: MeguriProfile {
        MeguriProfile(
            userID: userId,
            displayName: displayName,
            avatarID: SupabaseTextNormalizer.optional(avatarId) ?? "avatar_1",
            lastChangedAt: lastChangedAt,
            createdAt: createdAt ?? .now,
            updatedAt: updatedAt ?? createdAt ?? .now
        )
    }
}

struct MeguriProfileSavePayload: Encodable, Sendable {
    var pDisplayName: String
    var pAvatarId: String

    init(input: MeguriProfileUpdateInput) {
        self.pDisplayName = SupabaseTextNormalizer.trimmed(input.displayName)
        self.pAvatarId = SupabaseTextNormalizer.trimmed(input.avatarID)
    }
}
