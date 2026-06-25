import Foundation
import MegrumCore

public final class SupabaseOshiClient: @unchecked Sendable {
    let client: SupabaseRESTClient

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
            select: characterSelect,
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
}
