import Foundation
import MegrumCore

public final class SupabaseOshiClient: @unchecked Sendable {
    private let client: SupabaseRESTClient

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
    }

    public func loadGroups(searchText: String? = nil, limit: Int = 30) async throws -> [OshiGroup] {
        let rows: [OshiGroupRow] = try await client.fetchRows(
            from: "groups_master",
            select: "id,name,aliases,display_order",
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

    public func makeGroupsRequest(searchText: String? = nil, limit: Int = 30) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/groups_master",
            queryItems: [URLQueryItem(name: "select", value: "id,name,aliases,display_order")] + groupQueryItems(searchText: searchText, limit: limit)
        )
    }

    public func makeCharactersRequest(groupID: UUID, limit: Int = 80) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/characters_master",
            queryItems: [URLQueryItem(name: "select", value: "id,group_id,name,aliases,display_order")] + characterQueryItems(groupID: groupID, limit: limit)
        )
    }

    private func groupQueryItems(searchText: String?, limit: Int) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: "order", value: "display_order.asc,name.asc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        let trimmedSearchText = searchText?.trimmingCharacters(in: .whitespacesAndNewlines)
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
}

private struct OshiGroupRow: Decodable, Sendable {
    var id: UUID
    var name: String
    var aliases: [String]?
    var displayOrder: Int?

    var group: OshiGroup {
        OshiGroup(
            id: id,
            name: name,
            aliases: aliases ?? [],
            displayOrder: displayOrder ?? 0
        )
    }
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
