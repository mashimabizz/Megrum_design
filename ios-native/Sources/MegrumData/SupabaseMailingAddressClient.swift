import Foundation
import MegrumCore

public final class SupabaseMailingAddressClient: @unchecked Sendable {
    private let client: SupabaseRESTClient

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
    }

    public func loadAddress(userID: UUID) async throws -> MailingAddress? {
        let rows: [MailingAddressRow] = try await client.fetchRows(
            from: "user_mailing_addresses",
            select: Self.selectFields,
            queryItems: addressQueryItems(userID: userID)
        )
        return rows.first?.address
    }

    public func upsertAddress(_ address: MailingAddress) async throws -> MailingAddress {
        let rows: [MailingAddressRow] = try await client.upsertRows(
            into: "user_mailing_addresses",
            values: [MailingAddressPayload(address: address)],
            select: Self.selectFields,
            onConflict: "user_id"
        )
        return rows.first?.address ?? address
    }

    public func makeLoadAddressRequest(userID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/user_mailing_addresses",
            queryItems: [URLQueryItem(name: "select", value: Self.selectFields)] + addressQueryItems(userID: userID)
        )
    }

    public func makeUpsertAddressRequest(_ address: MailingAddress) throws -> URLRequest {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try client.makeMutationRequest(
            path: "/rest/v1/user_mailing_addresses",
            queryItems: [
                URLQueryItem(name: "select", value: Self.selectFields),
                URLQueryItem(name: "on_conflict", value: "user_id")
            ],
            method: "POST",
            body: encoder.encode([MailingAddressPayload(address: address)]),
            prefer: "resolution=merge-duplicates,return=representation"
        )
    }

    private static let selectFields = "user_id,recipient_name,postal_code,prefecture,city,line1,line2,phone_number,created_at,updated_at"

    private func addressQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.uuidString.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }
}

private struct MailingAddressPayload: Encodable, Sendable {
    var userId: UUID
    var recipientName: String
    var postalCode: String
    var prefecture: String
    var city: String
    var line1: String
    var line2: String?
    var phoneNumber: String?

    init(address: MailingAddress) {
        self.userId = address.userID
        self.recipientName = address.recipientName
        self.postalCode = address.postalCode
        self.prefecture = address.prefecture
        self.city = address.city
        self.line1 = address.line1
        self.line2 = address.line2
        self.phoneNumber = address.phoneNumber
    }
}

private struct MailingAddressRow: Decodable, Sendable {
    var userId: UUID
    var recipientName: String
    var postalCode: String
    var prefecture: String
    var city: String
    var line1: String
    var line2: String?
    var phoneNumber: String?
    var createdAt: Date?
    var updatedAt: Date?

    var address: MailingAddress {
        MailingAddress(
            userID: userId,
            recipientName: recipientName,
            postalCode: postalCode,
            prefecture: prefecture,
            city: city,
            line1: line1,
            line2: line2,
            phoneNumber: phoneNumber,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
