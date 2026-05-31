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
        try await sendMessage(
            senderID: senderID,
            proposalID: input.proposalID,
            messageType: .text,
            body: input.body
        )
    }

    public func sendPhotoMessage(
        senderID: UUID,
        proposalID: UUID,
        photoURL: URL,
        body: String? = nil,
        messageType: TradeMessageType = .photo
    ) async throws -> TradeMessage {
        try await sendMessage(
            senderID: senderID,
            proposalID: proposalID,
            messageType: messageType,
            body: body,
            photoURL: photoURL
        )
    }

    public func sendLocationMessage(senderID: UUID, proposalID: UUID, body: String) async throws -> TradeMessage {
        try await sendMessage(senderID: senderID, proposalID: proposalID, messageType: .location, body: body)
    }

    public func sendSystemMessage(senderID: UUID, proposalID: UUID, body: String) async throws -> TradeMessage {
        try await sendMessage(senderID: senderID, proposalID: proposalID, messageType: .system, body: body)
    }

    public func sendArrivalStatusMessage(senderID: UUID, proposalID: UUID, body: String) async throws -> TradeMessage {
        try await sendMessage(senderID: senderID, proposalID: proposalID, messageType: .arrivalStatus, body: body)
    }

    public func sendMessage(
        senderID: UUID,
        proposalID: UUID,
        messageType: TradeMessageType,
        body: String? = nil,
        photoURL: URL? = nil
    ) async throws -> TradeMessage {
        let payload = MessageCreatePayload(
            proposalID: proposalID,
            senderID: senderID,
            messageType: messageType,
            body: body,
            photoURL: photoURL
        )
        let rows: [MessageRow] = try await client.upsertRows(
            into: "messages",
            values: [payload],
            select: MessageRow.select
        )
        return rows.first?.message ?? TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: senderID,
            messageType: messageType,
            body: payload.body,
            photoURL: photoURL
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
        try makeSendMessageRequest(
            senderID: senderID,
            proposalID: input.proposalID,
            messageType: .text,
            body: input.body
        )
    }

    public func makeSendPhotoMessageRequest(
        senderID: UUID,
        proposalID: UUID,
        photoURL: URL,
        body: String? = nil,
        messageType: TradeMessageType = .photo
    ) throws -> URLRequest {
        try makeSendMessageRequest(
            senderID: senderID,
            proposalID: proposalID,
            messageType: messageType,
            body: body,
            photoURL: photoURL
        )
    }

    public func makeSendLocationMessageRequest(senderID: UUID, proposalID: UUID, body: String) throws -> URLRequest {
        try makeSendMessageRequest(senderID: senderID, proposalID: proposalID, messageType: .location, body: body)
    }

    public func makeSendSystemMessageRequest(senderID: UUID, proposalID: UUID, body: String) throws -> URLRequest {
        try makeSendMessageRequest(senderID: senderID, proposalID: proposalID, messageType: .system, body: body)
    }

    public func makeSendArrivalStatusMessageRequest(senderID: UUID, proposalID: UUID, body: String) throws -> URLRequest {
        try makeSendMessageRequest(senderID: senderID, proposalID: proposalID, messageType: .arrivalStatus, body: body)
    }

    public func makeSendMessageRequest(
        senderID: UUID,
        proposalID: UUID,
        messageType: TradeMessageType,
        body: String? = nil,
        photoURL: URL? = nil
    ) throws -> URLRequest {
        let payload = MessageCreatePayload(
            proposalID: proposalID,
            senderID: senderID,
            messageType: messageType,
            body: body,
            photoURL: photoURL
        )
        return try client.makeMutationRequest(
            path: "/rest/v1/messages",
            queryItems: [
                URLQueryItem(name: "select", value: MessageRow.select)
            ],
            method: "POST",
            body: encoder.encode([payload]),
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
    var body: String?
    var photoUrl: String?

    init(senderID: UUID, input: TradeMessageCreateInput) {
        self.init(
            proposalID: input.proposalID,
            senderID: senderID,
            messageType: .text,
            body: input.body
        )
    }

    init(
        proposalID: UUID,
        senderID: UUID,
        messageType: TradeMessageType,
        body: String? = nil,
        photoURL: URL? = nil
    ) {
        self.proposalId = proposalID
        self.senderId = senderID
        self.messageType = messageType.rawValue
        self.body = body?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.photoUrl = photoURL?.absoluteString
    }
}
