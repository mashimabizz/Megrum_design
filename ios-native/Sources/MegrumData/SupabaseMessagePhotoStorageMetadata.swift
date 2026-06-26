import Foundation
import MegrumCore

enum SupabaseMessagePhotoStorageMetadata {
    static let defaultBucket = "chat-photos"
    static let storageBucketKey = "storage_bucket"
    static let storagePathKey = "storage_path"
    private static let signedObjectPrefixes = ["/storage/v1/object/sign/", "/object/sign/"]
    private static let publicObjectPrefixes = ["/storage/v1/object/public/", "/object/public/"]
    private static let authenticatedObjectPrefixes = ["/storage/v1/object/authenticated/", "/object/authenticated/"]
    private static let directObjectPrefixes = ["/storage/v1/object/", "/object/"]

    static func make(storagePath: String?, storageBucket: String?) -> [String: String]? {
        guard let storagePath = SupabaseTextNormalizer.optional(storagePath) else {
            return nil
        }
        return [
            storageBucketKey: SupabaseTextNormalizer.optional(storageBucket) ?? defaultBucket,
            storagePathKey: storagePath
        ]
    }

    static func bucket(from message: TradeMessage) -> String {
        SupabaseTextNormalizer.optional(message.meta[storageBucketKey]) ?? defaultBucket
    }

    static func storagePath(from message: TradeMessage) -> String? {
        if let storagePath = SupabaseTextNormalizer.optional(message.meta[storagePathKey]) {
            return storagePath
        }
        guard let photoURL = message.photoURL else {
            return nil
        }
        return storagePath(from: photoURL, bucket: bucket(from: message))
    }

    static func storagePath(from url: URL, bucket: String) -> String? {
        let path = url.path
        for prefix in signedObjectPrefixes + publicObjectPrefixes + authenticatedObjectPrefixes + directObjectPrefixes {
            let bucketPrefix = "\(prefix)\(bucket)/"
            if path.hasPrefix(bucketPrefix) {
                let storagePath = String(path.dropFirst(bucketPrefix.count))
                return SupabaseTextNormalizer.optional(storagePath.removingPercentEncoding ?? storagePath)
            }
        }

        if url.scheme == nil {
            return SupabaseTextNormalizer.optional(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        }

        return nil
    }
}
