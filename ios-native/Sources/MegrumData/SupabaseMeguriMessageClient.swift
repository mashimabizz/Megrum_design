import Foundation
import MegrumCore

public final class SupabaseMeguriMessageClient: @unchecked Sendable {
    private static let mediaBucket = "meguri-message-media"
    private static let signedURLExpirationSeconds = 60 * 60 * 24 * 365

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
        return await messages(from: rows)
    }

    public func sendTextMessage(_ input: MeguriMessageCreateInput) async throws -> MeguriMessage {
        let rows: [MeguriMessageRow] = try await client.insertRows(
            into: "meguri_messages",
            values: [MeguriMessageCreatePayload(input: input)],
            select: MeguriMessageRow.insertSelect
        )
        let message = rows.first?.message(signedURLsByPath: [:]) ?? MeguriMessage(
            id: UUID(),
            senderID: input.senderID,
            recipientID: input.recipientID,
            sourceGroomReplyID: input.sourceGroomReplyID,
            sourceGroomPostID: input.sourceGroomPostID,
            sourceGroomOwnerID: input.sourceGroomOwnerID,
            sourceGroomImageURL: input.sourceGroomImageURL,
            body: SupabaseTextNormalizer.trimmed(input.body)
        )
        return message
    }

    public func sendImageMessage(
        senderID: UUID,
        recipientID: UUID,
        sourceGroomReplyID: UUID? = nil,
        sourceGroomPostID: UUID? = nil,
        sourceGroomOwnerID: UUID? = nil,
        sourceGroomImageURL: URL? = nil,
        imagePath: String,
        body: String? = nil
    ) async throws -> MeguriMessage {
        let rows: [MeguriMessageRow] = try await client.insertRows(
            into: "meguri_messages",
            values: [
                MeguriMessageCreatePayload(
                    senderID: senderID,
                    recipientID: recipientID,
                    sourceGroomReplyID: sourceGroomReplyID,
                    sourceGroomPostID: sourceGroomPostID,
                    sourceGroomOwnerID: sourceGroomOwnerID,
                    sourceGroomImageURL: sourceGroomImageURL,
                    imagePath: imagePath,
                    body: body
                )
            ],
            select: MeguriMessageRow.insertSelect
        )
        var message = rows.first?.message(signedURLsByPath: [:]) ?? MeguriMessage(
            id: UUID(),
            senderID: senderID,
            recipientID: recipientID,
            sourceGroomReplyID: sourceGroomReplyID,
            sourceGroomPostID: sourceGroomPostID,
            sourceGroomOwnerID: sourceGroomOwnerID,
            sourceGroomImageURL: sourceGroomImageURL,
            messageType: .image,
            body: SupabaseTextNormalizer.optional(body),
            imagePath: imagePath
        )
        message.imageURL = try? await signedURL(for: imagePath)
        return message
    }

    @discardableResult
    public func markConversationRead(
        viewerID: UUID,
        peerID: UUID,
        sourceGroomPostID: UUID? = nil,
        includesAllSources: Bool = false,
        readAt: Date = .now
    ) async throws -> [MeguriMessage] {
        let rows: [MeguriMessageRow] = try await client.updateRows(
            in: "meguri_messages",
            values: MeguriMessageReadPayload(readAt: SupabaseDateEncoding.isoTimestamp(readAt)),
            select: MeguriMessageRow.insertSelect,
            queryItems: markConversationReadQueryItems(
                viewerID: viewerID,
                peerID: peerID,
                sourceGroomPostID: sourceGroomPostID,
                includesAllSources: includesAllSources
            )
        )
        return await messages(from: rows)
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

    public func makeSendImageMessageRequest(
        senderID: UUID,
        recipientID: UUID,
        sourceGroomReplyID: UUID? = nil,
        sourceGroomPostID: UUID? = nil,
        sourceGroomOwnerID: UUID? = nil,
        sourceGroomImageURL: URL? = nil,
        imagePath: String,
        body: String? = nil
    ) throws -> URLRequest {
        try client.makeInsertRequest(
            into: "meguri_messages",
            values: [
                MeguriMessageCreatePayload(
                    senderID: senderID,
                    recipientID: recipientID,
                    sourceGroomReplyID: sourceGroomReplyID,
                    sourceGroomPostID: sourceGroomPostID,
                    sourceGroomOwnerID: sourceGroomOwnerID,
                    sourceGroomImageURL: sourceGroomImageURL,
                    imagePath: imagePath,
                    body: body
                )
            ],
            select: MeguriMessageRow.insertSelect
        )
    }

    public func makeMarkConversationReadRequest(
        viewerID: UUID,
        peerID: UUID,
        sourceGroomPostID: UUID? = nil,
        includesAllSources: Bool = false,
        readAt: Date
    ) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/meguri_messages",
            queryItems: [
                URLQueryItem(name: "select", value: MeguriMessageRow.insertSelect)
            ] + markConversationReadQueryItems(
                viewerID: viewerID,
                peerID: peerID,
                sourceGroomPostID: sourceGroomPostID,
                includesAllSources: includesAllSources
            ),
            method: "PATCH",
            body: encoder.encode(MeguriMessageReadPayload(readAt: SupabaseDateEncoding.isoTimestamp(readAt))),
            prefer: "return=representation"
        )
    }

    private func markConversationReadQueryItems(
        viewerID: UUID,
        peerID: UUID,
        sourceGroomPostID: UUID?,
        includesAllSources: Bool
    ) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: "recipient_id", value: "eq.\(viewerID.uuidString.lowercased())"),
            URLQueryItem(name: "sender_id", value: "eq.\(peerID.uuidString.lowercased())"),
            URLQueryItem(name: "read_at", value: "is.null")
        ]
        if !includesAllSources {
            if let sourceGroomPostID {
                queryItems.append(
                    URLQueryItem(
                        name: "source_groom_post_id",
                        value: "eq.\(sourceGroomPostID.uuidString.lowercased())"
                    )
                )
            } else {
                queryItems.append(URLQueryItem(name: "source_groom_post_id", value: "is.null"))
            }
        }
        return queryItems
    }

    private func messages(from rows: [MeguriMessageRow]) async -> [MeguriMessage] {
        let signedURLsByPath = await signedURLs(for: rows)
        return rows.compactMap { row in
            row.message(signedURLsByPath: signedURLsByPath)
        }
    }

    private func signedURLs(for rows: [MeguriMessageRow]) async -> [String: URL] {
        var signedURLsByPath: [String: URL] = [:]
        let paths = Set(rows.compactMap(\.imagePath))
        for path in paths {
            signedURLsByPath[path] = try? await signedURL(for: path)
        }
        return signedURLsByPath
    }

    private func signedURL(for path: String) async throws -> URL {
        try await client.createSignedURL(
            bucket: Self.mediaBucket,
            path: path,
            expiresIn: Self.signedURLExpirationSeconds
        )
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
        "source_groom_post_id",
        "source_groom_owner_id",
        "source_groom_image_url",
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
        "source_groom_post_id",
        "source_groom_owner_id",
        "source_groom_image_url",
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
    var sourceGroomPostId: UUID?
    var sourceGroomOwnerId: UUID?
    var sourceGroomImageUrl: String?
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

    func message(signedURLsByPath: [String: URL]) -> MeguriMessage? {
        let type = MeguriMessageType(rawValue: messageType ?? MeguriMessageType.text.rawValue) ?? .text
        return MeguriMessage(
            id: id,
            senderID: senderId,
            recipientID: recipientId,
            sourceGroomReplyID: sourceGroomReplyId,
            sourceGroomPostID: sourceGroomPostId,
            sourceGroomOwnerID: sourceGroomOwnerId,
            sourceGroomImageURL: sourceGroomImageUrl.flatMap(URL.init(string:)),
            messageType: type,
            body: body,
            imageURL: imagePath.flatMap { signedURLsByPath[$0] } ?? imageUrl.flatMap(URL.init(string:)),
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
    var body: String?
    var imagePath: String?
    var messageType: String
    var recipientId: UUID
    var senderId: UUID
    var sourceGroomReplyId: UUID?
    var sourceGroomPostId: UUID?
    var sourceGroomOwnerId: UUID?
    var sourceGroomImageUrl: String?

    init(input: MeguriMessageCreateInput) {
        self.body = SupabaseTextNormalizer.trimmed(input.body)
        self.imagePath = nil
        self.messageType = MeguriMessageType.text.rawValue
        self.recipientId = input.recipientID
        self.senderId = input.senderID
        self.sourceGroomReplyId = input.sourceGroomReplyID
        self.sourceGroomPostId = input.sourceGroomPostID
        self.sourceGroomOwnerId = input.sourceGroomOwnerID
        self.sourceGroomImageUrl = input.sourceGroomImageURL?.absoluteString
    }

    init(
        senderID: UUID,
        recipientID: UUID,
        sourceGroomReplyID: UUID?,
        sourceGroomPostID: UUID?,
        sourceGroomOwnerID: UUID?,
        sourceGroomImageURL: URL?,
        imagePath: String,
        body: String?
    ) {
        self.body = SupabaseTextNormalizer.optional(body)
        self.imagePath = SupabaseTextNormalizer.trimmed(imagePath)
        self.messageType = MeguriMessageType.image.rawValue
        self.recipientId = recipientID
        self.senderId = senderID
        self.sourceGroomReplyId = sourceGroomReplyID
        self.sourceGroomPostId = sourceGroomPostID
        self.sourceGroomOwnerId = sourceGroomOwnerID
        self.sourceGroomImageUrl = sourceGroomImageURL?.absoluteString
    }
}

private struct MeguriMessageReadPayload: Encodable, Sendable {
    var readAt: String
}
