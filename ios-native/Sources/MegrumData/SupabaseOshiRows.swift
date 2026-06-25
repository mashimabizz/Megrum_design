import Foundation
import MegrumCore

struct OshiGenreRow: Decodable, Sendable {
    var id: UUID
    var name: String
    var kind: String?
    var displayOrder: Int?

    var genre: OshiGenre {
        OshiGenre(
            id: id,
            name: name,
            kind: kind,
            displayOrder: displayOrder ?? 0
        )
    }
}

struct OshiGroupRow: Decodable, Sendable {
    var id: UUID
    var name: String
    var aliases: [String]?
    var kind: OshiRequestKind?
    var genreId: UUID?
    var genre: NestedGenreRow?
    var displayOrder: Int?

    var group: OshiGroup {
        OshiGroup(
            id: id,
            name: name,
            aliases: aliases ?? [],
            kind: kind ?? .group,
            genreID: genreId ?? genre?.id,
            genreName: genre?.name,
            displayOrder: displayOrder ?? 0
        )
    }
}

struct NestedGenreRow: Decodable, Sendable {
    var id: UUID
    var name: String
    var kind: String?
    var displayOrder: Int?
}

struct OshiCharacterRow: Decodable, Sendable {
    var id: UUID
    var groupId: UUID
    var name: String
    var aliases: [String]?
    var displayOrder: Int?

    var character: OshiCharacter {
        OshiCharacter(
            id: id,
            groupID: groupId,
            name: name,
            aliases: aliases ?? [],
            displayOrder: displayOrder ?? 0
        )
    }
}

struct UserOshiSelectionRow: Decodable, Sendable {
    var id: UUID
    var userId: UUID
    var groupId: UUID?
    var characterId: UUID?
    var oshiRequestId: UUID?
    var characterRequestId: UUID?
    var kind: OshiKind
    var priority: Int
    var group: OshiNameRow?
    var character: OshiNameRow?
    var oshiRequest: OshiRequestNameRow?
    var characterRequest: OshiRequestNameRow?

    var selection: UserOshiSelection {
        UserOshiSelection(
            id: id,
            userID: userId,
            groupID: groupId,
            characterID: characterId,
            kind: kind,
            priority: priority,
            oshiRequestID: oshiRequestId,
            characterRequestID: characterRequestId,
            groupName: group?.name,
            characterName: character?.name,
            oshiRequestName: oshiRequest?.requestedName,
            characterRequestName: characterRequest?.requestedName
        )
    }
}

struct OshiNameRow: Decodable, Sendable {
    var id: UUID
    var name: String?
}

struct OshiRequestNameRow: Decodable, Sendable {
    var id: UUID
    var requestedName: String?
    var status: String?
}

struct CreatedIDRow: Decodable, Sendable {
    var id: UUID
}
