import Foundation
import MegrumCore
import MegrumData

struct SupabaseChatPhotoUpload: Equatable, Sendable {
    var path: String
    var contentType: String
}

struct SupabaseChatPhotoStorage: Sendable {
    static let bucket = "chat-photos"
    static let maxUploadBytes = Int(9.5 * 1_024 * 1_024)
    static let signedURLExpirationSeconds = 60 * 60 * 24 * 365

    private let client: SupabaseRESTClient
    private let now: @Sendable () -> Date
    private let makeUUID: @Sendable () -> UUID

    init(
        client: SupabaseRESTClient,
        now: @escaping @Sendable () -> Date = Date.init,
        makeUUID: @escaping @Sendable () -> UUID = UUID.init
    ) {
        self.client = client
        self.now = now
        self.makeUUID = makeUUID
    }

    func uploadPhoto(_ input: TradePhotoMessageCreateInput) async throws -> URL {
        let upload = try Self.makeUpload(input: input, now: now(), uuid: makeUUID())
        try await client.uploadObject(
            bucket: Self.bucket,
            path: upload.path,
            data: input.imageData,
            contentType: upload.contentType,
            upsert: false
        )
        return try await client.createSignedURL(
            bucket: Self.bucket,
            path: upload.path,
            expiresIn: Self.signedURLExpirationSeconds
        )
    }

    static func makeUpload(
        input: TradePhotoMessageCreateInput,
        now: Date,
        uuid: UUID
    ) throws -> SupabaseChatPhotoUpload {
        guard input.messageType == .photo || input.messageType == .outfitPhoto else {
            throw SupabaseMessageClientError.invalidPhotoMessageType
        }
        guard input.imageData.count <= maxUploadBytes else {
            throw SupabaseProposalClientError.imageTooLarge
        }

        let contentType = normalizedContentType(input.imageContentType)
        return SupabaseChatPhotoUpload(
            path: path(
                proposalID: input.proposalID,
                messageType: input.messageType,
                contentType: contentType,
                now: now,
                uuid: uuid
            ),
            contentType: contentType
        )
    }

    static func normalizedContentType(_ value: String) -> String {
        switch value.lowercased() {
        case "image/png":
            "image/png"
        case "image/webp":
            "image/webp"
        default:
            "image/jpeg"
        }
    }

    static func fileExtension(for contentType: String) -> String {
        switch normalizedContentType(contentType) {
        case "image/png":
            "png"
        case "image/webp":
            "webp"
        default:
            "jpg"
        }
    }

    static func path(
        proposalID: UUID,
        messageType: TradeMessageType,
        contentType: String,
        now: Date,
        uuid: UUID
    ) -> String {
        let milliseconds = Int(now.timeIntervalSince1970 * 1_000)
        let prefix = messageType == .outfitPhoto ? "outfit" : "photo"
        return "\(proposalID.uuidString.lowercased())/\(prefix)-\(milliseconds)-\(uuid.uuidString.lowercased()).\(fileExtension(for: contentType))"
    }
}
