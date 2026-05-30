import Foundation
import MegrumCore

public final class SupabaseMeguriMessageClient: @unchecked Sendable {
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

    public func loadMessages() async throws -> [MeguriMessage] {
        let rows: [MeguriMessageRow] = try await client.rpcRows(
            function: "list_meguri_messages_for_viewer",
            payload: EmptyPayload()
        )
        return rows.compactMap(\.message)
    }

    public func sendTextMessage(_ input: MeguriMessageCreateInput) async throws -> MeguriMessage {
        let rows: [MeguriMessageRow] = try await client.insertRows(
            into: "meguri_messages",
            values: [MeguriMessageCreatePayload(input: input)],
            select: MeguriMessageRow.insertSelect
        )
        return rows.first?.message ?? MeguriMessage(
            id: UUID(),
            senderID: input.senderID,
            recipientID: input.recipientID,
            sourceGroomReplyID: input.sourceGroomReplyID,
            body: input.body.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    @discardableResult
    public func markConversationRead(
        viewerID: UUID,
        peerID: UUID,
        readAt: Date = .now
    ) async throws -> [MeguriMessage] {
        let rows: [MeguriMessageRow] = try await client.updateRows(
            in: "meguri_messages",
            values: MeguriMessageReadPayload(readAt: isoTimestamp(readAt)),
            select: MeguriMessageRow.insertSelect,
            queryItems: markConversationReadQueryItems(viewerID: viewerID, peerID: peerID)
        )
        return rows.compactMap(\.message)
    }

    public func makeLoadMessagesRequest() throws -> URLRequest {
        try client.makeRPCRequest(
            function: "list_meguri_messages_for_viewer",
            payload: EmptyPayload()
        )
    }

    public func makeSendTextMessageRequest(_ input: MeguriMessageCreateInput) throws -> URLRequest {
        try client.makeInsertRequest(
            into: "meguri_messages",
            values: [MeguriMessageCreatePayload(input: input)],
            select: MeguriMessageRow.insertSelect
        )
    }

    public func makeMarkConversationReadRequest(
        viewerID: UUID,
        peerID: UUID,
        readAt: Date
    ) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/meguri_messages",
            queryItems: [
                URLQueryItem(name: "select", value: MeguriMessageRow.insertSelect)
            ] + markConversationReadQueryItems(viewerID: viewerID, peerID: peerID),
            method: "PATCH",
            body: encoder.encode(MeguriMessageReadPayload(readAt: isoTimestamp(readAt))),
            prefer: "return=representation"
        )
    }

    private func markConversationReadQueryItems(viewerID: UUID, peerID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "recipient_id", value: "eq.\(viewerID.uuidString.lowercased())"),
            URLQueryItem(name: "sender_id", value: "eq.\(peerID.uuidString.lowercased())"),
            URLQueryItem(name: "read_at", value: "is.null")
        ]
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}

private struct EmptyPayload: Encodable, Sendable {}

private struct MeguriMessageRow: Decodable, Sendable {
    static let rpcSelect = [
        "id",
        "sender_id",
        "recipient_id",
        "source_groom_reply_id",
        "message_type",
        "body",
        "image_url",
        "image_path",
        "read_at",
        "created_at",
        "locked",
        "sender_display_name",
        "sender_handle",
        "recipient_display_name",
        "recipient_handle"
    ].joined(separator: ",")

    static let insertSelect = [
        "id",
        "sender_id",
        "recipient_id",
        "source_groom_reply_id",
        "message_type",
        "body",
        "image_url",
        "image_path",
        "read_at",
        "created_at"
    ].joined(separator: ",")

    var id: UUID
    var senderId: UUID
    var recipientId: UUID
    var sourceGroomReplyId: UUID?
    var messageType: String?
    var body: String?
    var imageUrl: String?
    var imagePath: String?
    var readAt: Date?
    var createdAt: Date?
    var locked: Bool?
    var senderDisplayName: String?
    var senderHandle: String?
    var recipientDisplayName: String?
    var recipientHandle: String?

    var message: MeguriMessage? {
        let type = MeguriMessageType(rawValue: messageType ?? MeguriMessageType.text.rawValue) ?? .text
        return MeguriMessage(
            id: id,
            senderID: senderId,
            recipientID: recipientId,
            sourceGroomReplyID: sourceGroomReplyId,
            messageType: type,
            body: body,
            imageURL: imageUrl.flatMap(URL.init(string:)),
            imagePath: imagePath,
            readAt: readAt,
            createdAt: createdAt ?? .now,
            locked: locked ?? false,
            senderDisplayName: senderDisplayName,
            senderHandle: senderHandle,
            recipientDisplayName: recipientDisplayName,
            recipientHandle: recipientHandle
        )
    }
}

private struct MeguriMessageCreatePayload: Encodable, Sendable {
    var body: String
    var messageType = MeguriMessageType.text.rawValue
    var recipientId: UUID
    var senderId: UUID
    var sourceGroomReplyId: UUID?

    init(input: MeguriMessageCreateInput) {
        self.body = input.body.trimmingCharacters(in: .whitespacesAndNewlines)
        self.recipientId = input.recipientID
        self.senderId = input.senderID
        self.sourceGroomReplyId = input.sourceGroomReplyID
    }
}

private struct MeguriMessageReadPayload: Encodable, Sendable {
    var readAt: String
}

private func isoTimestamp(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
}
