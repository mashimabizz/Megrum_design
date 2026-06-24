import Foundation
import MegrumCore

public final class SupabaseOshiClient: @unchecked Sendable {
    private let client: SupabaseRESTClient

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
    }

    public func loadGenres(limit: Int = 100) async throws -> [OshiGenre] {
        let rows: [OshiGenreRow] = try await client.fetchRows(
            from: "genres_master",
            select: "id,name,kind,display_order",
            queryItems: [
                URLQueryItem(name: "order", value: "display_order.asc,name.asc"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        )
        return rows.map(\.genre)
    }

    public func loadGroups(searchText: String? = nil, limit: Int = 100) async throws -> [OshiGroup] {
        let rows: [OshiGroupRow] = try await client.fetchRows(
            from: "groups_master",
            select: groupSelect,
            queryItems: groupQueryItems(searchText: searchText, limit: limit)
        )
        return rows.map(\.group)
    }

    public func loadCharacters(groupID: UUID, limit: Int = 80) async throws -> [OshiCharacter] {
        let rows: [OshiCharacterRow] = try await client.fetchRows(
            from: "characters_master",
            select: "id,group_id,name,aliases,display_order",
            queryItems: characterQueryItems(groupID: groupID, limit: limit)
        )
        return rows.map(\.character)
    }

    public func loadUserSelections(userID: UUID) async throws -> [UserOshiSelection] {
        let rows: [UserOshiSelectionRow] = try await client.fetchRows(
            from: "user_oshi",
            select: userSelectionSelect,
            queryItems: userSelectionFilterItems(userID: userID) + [
                URLQueryItem(name: "order", value: "priority.asc")
            ]
        )
        return rows.map(\.selection)
    }

    public func createOshiRequest(userID: UUID, input: OshiRequestCreateInput) async throws -> UUID {
        let rows: [CreatedIDRow] = try await client.insertRows(
            into: "oshi_requests",
            values: [
                OshiRequestPayload(
                    userID: userID,
                    input: input
                )
            ],
            select: "id"
        )
        return rows[0].id
    }

    public func createCharacterRequest(userID: UUID, input: CharacterRequestCreateInput) async throws -> UUID {
        let rows: [CreatedIDRow] = try await client.insertRows(
            into: "character_requests",
            values: [
                CharacterRequestPayload(
                    userID: userID,
                    input: input
                )
            ],
            select: "id"
        )
        return rows[0].id
    }

    public func replaceUserSelections(userID: UUID, selections: [UserOshiSelection]) async throws -> [UserOshiSelection] {
        try await client.deleteRows(
            from: "user_oshi",
            queryItems: userSelectionFilterItems(userID: userID)
        )
        guard !selections.isEmpty else {
            return []
        }

        let rows: [UserOshiSelectionRow] = try await client.upsertRows(
            into: "user_oshi",
            values: selections.map(UserOshiSelectionPayload.init(selection:)),
            select: userSelectionSelect
        )
        return rows.map(\.selection)
    }

    public func makeGroupsRequest(searchText: String? = nil, limit: Int = 30) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/groups_master",
            queryItems: [URLQueryItem(name: "select", value: groupSelect)] + groupQueryItems(searchText: searchText, limit: limit)
        )
    }

    public func makeCharactersRequest(groupID: UUID, limit: Int = 80) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/characters_master",
            queryItems: [URLQueryItem(name: "select", value: "id,group_id,name,aliases,display_order")] + characterQueryItems(groupID: groupID, limit: limit)
        )
    }

    public func makeLoadUserSelectionsRequest(userID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/user_oshi",
            queryItems: [URLQueryItem(name: "select", value: userSelectionSelect)] + userSelectionFilterItems(userID: userID) + [
                URLQueryItem(name: "order", value: "priority.asc")
            ]
        )
    }

    public func makeDeleteUserSelectionsRequest(userID: UUID) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/user_oshi",
            queryItems: userSelectionFilterItems(userID: userID),
            method: "DELETE",
            body: nil,
            prefer: "return=minimal"
        )
    }

    public func makeCreateOshiRequest(userID: UUID, input: OshiRequestCreateInput) throws -> URLRequest {
        try client.makeInsertRequest(
            into: "oshi_requests",
            values: [
                OshiRequestPayload(
                    userID: userID,
                    input: input
                )
            ],
            select: "id"
        )
    }

    public func makeCreateCharacterRequest(userID: UUID, input: CharacterRequestCreateInput) throws -> URLRequest {
        try client.makeInsertRequest(
            into: "character_requests",
            values: [
                CharacterRequestPayload(
                    userID: userID,
                    input: input
                )
            ],
            select: "id"
        )
    }

    public func makeUpsertUserSelectionsRequest(_ selections: [UserOshiSelection]) throws -> URLRequest {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try client.makeMutationRequest(
            path: "/rest/v1/user_oshi",
            queryItems: [URLQueryItem(name: "select", value: userSelectionSelect)],
            method: "POST",
            body: encoder.encode(selections.map(UserOshiSelectionPayload.init(selection:))),
            prefer: "resolution=merge-duplicates,return=representation"
        )
    }

    private func groupQueryItems(searchText: String?, limit: Int) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: "order", value: "display_order.asc,name.asc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        let trimmedSearchText = SupabaseTextNormalizer.optional(searchText)
        if let trimmedSearchText, !trimmedSearchText.isEmpty {
            queryItems.append(URLQueryItem(name: "name", value: "ilike.*\(trimmedSearchText)*"))
        }
        return queryItems
    }

    private func characterQueryItems(groupID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "group_id", value: "eq.\(groupID.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "display_order.asc,name.asc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
    }

    private var groupSelect: String {
        "id,name,aliases,kind,genre_id,display_order,genre:genres_master(id,name,kind,display_order)"
    }

    private var userSelectionSelect: String {
        "id,user_id,group_id,character_id,oshi_request_id,character_request_id,kind,priority,group:groups_master(id,name),character:characters_master(id,name),oshi_request:oshi_requests(id,requested_name,status),character_request:character_requests(id,requested_name,status)"
    }

    private func userSelectionFilterItems(userID: UUID) -> [URLQueryItem] {
        [URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())")]
    }
}

private struct OshiGenreRow: Decodable, Sendable {
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

private struct OshiGroupRow: Decodable, Sendable {
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

private struct NestedGenreRow: Decodable, Sendable {
    var id: UUID
    var name: String
    var kind: String?
    var displayOrder: Int?
}

private struct OshiCharacterRow: Decodable, Sendable {
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

private struct UserOshiSelectionPayload: Encodable, Sendable {
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

private struct UserOshiSelectionRow: Decodable, Sendable {
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

private struct OshiNameRow: Decodable, Sendable {
    var id: UUID
    var name: String?
}

private struct OshiRequestNameRow: Decodable, Sendable {
    var id: UUID
    var requestedName: String?
    var status: String?
}

private struct CreatedIDRow: Decodable, Sendable {
    var id: UUID
}

private struct OshiRequestPayload: Encodable, Sendable {
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

private struct CharacterRequestPayload: Encodable, Sendable {
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
