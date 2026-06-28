import Foundation
import MegrumCore

public enum SupabaseMeguriProfileClientError: Error, Equatable, Sendable {
    case duplicatedDisplayName
    case changeLocked
    case malformedResponse
}

public final class SupabaseMeguriProfileClient: @unchecked Sendable {
    private let client: SupabaseRESTClient

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
    }

    public func loadProfile(userID: UUID) async throws -> MeguriProfile? {
        let rows: [MeguriProfileRow] = try await client.fetchRows(
            from: "meguri_profiles",
            select: MeguriProfileRow.select,
            queryItems: [
                URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        return rows.first?.profile
    }

    public func loadProfiles(userIDs: Set<UUID>) async throws -> [MeguriProfile] {
        guard !userIDs.isEmpty else {
            return []
        }
        let joinedIDs = userIDs.map { $0.uuidString.lowercased() }.sorted().joined(separator: ",")
        let rows: [MeguriProfileRow] = try await client.fetchRows(
            from: "meguri_profiles",
            select: MeguriProfileRow.select,
            queryItems: [
                URLQueryItem(name: "user_id", value: "in.(\(joinedIDs))")
            ]
        )
        return rows.map(\.profile)
    }

    public func saveProfile(_ input: MeguriProfileUpdateInput) async throws -> MeguriProfile {
        do {
            let rows: [MeguriProfileRow] = try await client.rpcRows(
                function: "set_meguri_profile_for_viewer",
                payload: MeguriProfileSavePayload(input: input)
            )
            guard let profile = rows.first?.profile else {
                throw SupabaseMeguriProfileClientError.malformedResponse
            }
            return profile
        } catch let error as SupabaseRESTError where error == .unexpectedStatus(409) {
            throw SupabaseMeguriProfileClientError.duplicatedDisplayName
        } catch let error as SupabaseRESTError where error == .unexpectedStatus(400) {
            throw SupabaseMeguriProfileClientError.changeLocked
        }
    }

    public func makeLoadProfilesRequest(userIDs: Set<UUID>) throws -> URLRequest {
        let joinedIDs = userIDs.map { $0.uuidString.lowercased() }.sorted().joined(separator: ",")
        return try client.makeRequest(
            path: "/rest/v1/meguri_profiles",
            queryItems: [
                URLQueryItem(name: "select", value: MeguriProfileRow.select),
                URLQueryItem(name: "user_id", value: "in.(\(joinedIDs))")
            ]
        )
    }

    public func makeSaveProfileRequest(_ input: MeguriProfileUpdateInput) throws -> URLRequest {
        try client.makeRPCRequest(
            function: "set_meguri_profile_for_viewer",
            payload: MeguriProfileSavePayload(input: input)
        )
    }
}
