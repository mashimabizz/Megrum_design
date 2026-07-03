import Foundation
import MegrumCore
import MegrumData

struct SupabaseMeguriMessageMediaUpload: Equatable, Sendable {
    var path: String
    var contentType: String
}

enum SupabaseMeguriMessageMediaStorageError: Error, Equatable, Sendable {
    case emptyImage
}

struct SupabaseMeguriMessageMediaStorage: Sendable {
    static let bucket = "meguri-message-media"
    static let maxUploadBytes = SupabaseChatPhotoStorage.maxUploadBytes

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

    func uploadPhoto(_ input: MeguriPhotoMessageCreateInput) async throws -> SupabaseMeguriMessageMediaUpload {
        let upload = try Self.makeUpload(input: input, now: now(), uuid: makeUUID())
        try await client.uploadObject(
            bucket: Self.bucket,
            path: upload.path,
            data: input.imageData,
            contentType: upload.contentType,
            upsert: false
        )
        return upload
    }

    static func makeUpload(
        input: MeguriPhotoMessageCreateInput,
        now: Date,
        uuid: UUID
    ) throws -> SupabaseMeguriMessageMediaUpload {
        guard !input.imageData.isEmpty else {
            throw SupabaseMeguriMessageMediaStorageError.emptyImage
        }
        guard input.imageData.count <= maxUploadBytes else {
            throw SupabaseProposalClientError.imageTooLarge
        }

        let contentType = SupabaseChatPhotoStorage.normalizedContentType(input.imageContentType)
        return SupabaseMeguriMessageMediaUpload(
            path: path(
                senderID: input.senderID,
                contentType: contentType,
                now: now,
                uuid: uuid
            ),
            contentType: contentType
        )
    }

    static func path(
        senderID: UUID,
        contentType: String,
        now: Date,
        uuid: UUID
    ) -> String {
        let milliseconds = Int(now.timeIntervalSince1970 * 1_000)
        let fileExtension = SupabaseChatPhotoStorage.fileExtension(for: contentType)
        return [
            senderID.uuidString.lowercased(),
            "message-\(milliseconds)-\(uuid.uuidString.lowercased()).\(fileExtension)"
        ].joined(separator: "/")
    }
}
