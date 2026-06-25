import Foundation
import MegrumCore

struct UserOshiSelectionPayload: Encodable, Sendable {
    var id: UUID
    var userId: UUID
    var groupId: UUID?
    var characterId: UUID?
    var oshiRequestId: UUID?
    var characterRequestId: UUID?
    var kind: OshiKind
    var priority: Int

    init(selection: UserOshiSelection) {
        self.id = selection.id
        self.userId = selection.userID
        self.groupId = selection.groupID
        self.characterId = selection.characterID
        self.oshiRequestId = selection.oshiRequestID
        self.characterRequestId = selection.characterRequestID
        self.kind = selection.kind
        self.priority = selection.priority
    }
}

struct OshiRequestPayload: Encodable, Sendable {
    var userId: UUID
    var requestedName: String
    var requestedGenreId: UUID?
    var requestedKind: OshiRequestKind
    var note: String?

    init(userID: UUID, input: OshiRequestCreateInput) {
        self.userId = userID
        self.requestedName = input.requestedName
        self.requestedGenreId = input.requestedGenreID
        self.requestedKind = input.requestedKind
        self.note = SupabaseTextNormalizer.optional(input.note)
    }
}

struct CharacterRequestPayload: Encodable, Sendable {
    var userId: UUID
    var groupId: UUID?
    var oshiRequestId: UUID?
    var requestedName: String
    var note: String?

    init(userID: UUID, input: CharacterRequestCreateInput) {
        self.userId = userID
        self.groupId = input.groupID
        self.oshiRequestId = input.oshiRequestID
        self.requestedName = input.requestedName
        self.note = SupabaseTextNormalizer.optional(input.note)
    }
}
