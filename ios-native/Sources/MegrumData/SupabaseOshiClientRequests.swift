import Foundation
import MegrumCore

extension SupabaseOshiClient {
    public func makeGroupsRequest(searchText: String? = nil, limit: Int = 30) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/groups_master",
            queryItems: [URLQueryItem(name: "select", value: groupSelect)] + groupQueryItems(searchText: searchText, limit: limit)
        )
    }

    public func makeCharactersRequest(groupID: UUID, limit: Int = 80) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/characters_master",
            queryItems: [URLQueryItem(name: "select", value: characterSelect)] + characterQueryItems(groupID: groupID, limit: limit)
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

    func groupQueryItems(searchText: String?, limit: Int) -> [URLQueryItem] {
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

    func characterQueryItems(groupID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "group_id", value: "eq.\(groupID.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "display_order.asc,name.asc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
    }

    var groupSelect: String {
        "id,name,aliases,kind,genre_id,display_order,genre:genres_master(id,name,kind,display_order)"
    }

    var characterSelect: String {
        "id,group_id,name,aliases,display_order"
    }

    var userSelectionSelect: String {
        "id,user_id,group_id,character_id,oshi_request_id,character_request_id,kind,priority,group:groups_master(id,name),character:characters_master(id,name),oshi_request:oshi_requests(id,requested_name,status),character_request:character_requests(id,requested_name,status)"
    }

    func userSelectionFilterItems(userID: UUID) -> [URLQueryItem] {
        [URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())")]
    }
}
