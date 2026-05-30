import Foundation
import MegrumCore

public final class SupabaseMessageClient: @unchecked Sendable {
    private let client: SupabaseRESTClient
    private let encoder: JSONEncoder

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
        self.encoder = Self.makeEncoder()
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
        self.encoder = Self.makeEncoder()
    }

    public func loadMessages(proposalID: UUID, limit: Int = 80) async throws -> [TradeMessage] {
        let rows: [MessageRow] = try await client.fetchRows(
            from: "messages",
            select: MessageRow.select,
            queryItems: [
                URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
                URLQueryItem(name: "order", value: "created_at.asc"),
                URLQueryItem(name: "limit", value: "\(max(1, min(limit, 120)))")
            ]
        )
        return rows.compactMap(\.message)
    }

    public func sendTextMessage(senderID: UUID, input: TradeMessageCreateInput) async throws -> TradeMessage {
        let rows: [MessageRow] = try await client.upsertRows(
            into: "messages",
            values: [MessageCreatePayload(senderID: senderID, input: input)],
            select: MessageRow.select
        )
        return rows.first?.message ?? TradeMessage(
            id: UUID(),
            proposalID: input.proposalID,
            senderID: senderID,
            messageType: .text,
            body: input.body
        )
    }

    public func makeLoadMessagesRequest(proposalID: UUID, limit: Int = 80) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/messages",
            queryItems: [
                URLQueryItem(name: "select", value: MessageRow.select),
                URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
                URLQueryItem(name: "order", value: "created_at.asc"),
                URLQueryItem(name: "limit", value: "\(max(1, min(limit, 120)))")
            ]
        )
    }

    public func makeSendTextMessageRequest(senderID: UUID, input: TradeMessageCreateInput) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/messages",
            queryItems: [
                URLQueryItem(name: "select", value: MessageRow.select)
            ],
            method: "POST",
            body: encoder.encode([MessageCreatePayload(senderID: senderID, input: input)]),
            prefer: "resolution=merge-duplicates,return=representation"
        )
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}

private struct MessageRow: Decodable, Sendable {
    static let select = "id,proposal_id,sender_id,message_type,body,photo_url,created_at"

    var id: UUID
    var proposalId: UUID
    var senderId: UUID
    var messageType: String
    var body: String?
    var photoUrl: URL?
    var createdAt: Date?

    var message: TradeMessage? {
        guard let type = TradeMessageType(rawValue: messageType) else {
            return nil
        }
        return TradeMessage(
            id: id,
            proposalID: proposalId,
            senderID: senderId,
            messageType: type,
            body: body,
            photoURL: photoUrl,
            createdAt: createdAt ?? .now
        )
    }
}

private struct MessageCreatePayload: Encodable, Sendable {
    var proposalId: UUID
    var senderId: UUID
    var messageType: String
    var body: String

    init(senderID: UUID, input: TradeMessageCreateInput) {
        self.proposalId = input.proposalID
        self.senderId = senderID
        self.messageType = TradeMessageType.text.rawValue
        self.body = input.body.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
