import Foundation
import MegrumCore
import MegrumData

enum ProfilePhotoUploadError: Error, Equatable, Sendable {
    case imageTooLarge
    case unsupportedImageContentType
}

struct SupabaseProfilePhotoUpload: Equatable, Sendable {
    var path: String
    var contentType: String
}

struct SupabaseProfilePhotoStorage: Sendable {
    static let bucket = "profile-photos"
    static let maxUploadBytes = 10 * 1_024 * 1_024

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

    func uploadIfNeeded(_ upload: GoodsPhotoUpload?, userID: UUID) async throws -> URL? {
        guard let upload else {
            return nil
        }
        let preparedUpload = try Self.makeUpload(
            upload,
            userID: userID,
            now: now(),
            uuid: makeUUID()
        )
        try await client.uploadObject(
            bucket: Self.bucket,
            path: preparedUpload.path,
            data: upload.data,
            contentType: preparedUpload.contentType,
            upsert: false
        )
        return try client.publicStorageObjectURL(bucket: Self.bucket, path: preparedUpload.path)
    }

    static func makeUpload(
        _ upload: GoodsPhotoUpload,
        userID: UUID,
        now: Date,
        uuid: UUID
    ) throws -> SupabaseProfilePhotoUpload {
        guard upload.data.count <= maxUploadBytes else {
            throw ProfilePhotoUploadError.imageTooLarge
        }

        let contentType = try normalizedContentType(upload.contentType)
        return SupabaseProfilePhotoUpload(
            path: path(userID: userID, contentType: contentType, now: now, uuid: uuid),
            contentType: contentType
        )
    }

    static func normalizedContentType(_ value: String) throws -> String {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "image/jpeg", "image/jpg":
            "image/jpeg"
        case "image/png":
            "image/png"
        case "image/webp":
            "image/webp"
        case "image/gif":
            "image/gif"
        default:
            throw ProfilePhotoUploadError.unsupportedImageContentType
        }
    }

    static func path(
        userID: UUID,
        contentType: String,
        now: Date,
        uuid: UUID
    ) -> String {
        let milliseconds = Int(now.timeIntervalSince1970 * 1_000)
        return [
            userID.uuidString.lowercased(),
            "\(milliseconds)_\(uuid.uuidString.lowercased()).\(fileExtension(for: contentType))"
        ].joined(separator: "/")
    }

    static func fileExtension(for contentType: String) -> String {
        switch contentType {
        case "image/png":
            "png"
        case "image/webp":
            "webp"
        case "image/gif":
            "gif"
        default:
            "jpg"
        }
    }
}
