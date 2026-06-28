import Foundation

public enum GoodsPhotoURLResolver {
    public static let goodsPhotoBucket = "goods-photos"

    public static func displayURL(from values: [String]?, projectURL: URL? = nil) -> URL? {
        values?.compactMap { displayURL(from: $0, projectURL: projectURL) }.first
    }

    public static func displayURL(from value: String, projectURL: URL? = nil) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if let absoluteURL = URL(string: trimmed),
           absoluteURL.scheme?.isEmpty == false,
           absoluteURL.host?.isEmpty == false {
            return normalizedPublicStorageURL(from: absoluteURL) ?? absoluteURL
        }

        guard let projectURL,
              let storagePath = normalizedRelativeStoragePath(trimmed)
        else {
            return nil
        }
        return publicStorageURL(projectURL: projectURL, storagePath: storagePath)
    }

    public static func storagePath(from url: URL) -> String? {
        storagePath(fromPath: url.path)
    }

    private static func normalizedPublicStorageURL(from url: URL) -> URL? {
        guard let storagePath = storagePath(from: url) else {
            return nil
        }
        return publicStorageURL(projectURL: url, storagePath: storagePath)
    }

    private static func publicStorageURL(projectURL: URL, storagePath: String) -> URL? {
        var components = URLComponents()
        components.scheme = projectURL.scheme
        components.host = projectURL.host
        components.port = projectURL.port
        components.percentEncodedPath = "/storage/v1/object/public/\(goodsPhotoBucket)/\(percentEncodedPath(storagePath))"
        return components.url
    }

    private static func storagePath(fromPath path: String) -> String? {
        let prefixes = [
            "/storage/v1/object/public/\(goodsPhotoBucket)/",
            "/storage/v1/object/sign/\(goodsPhotoBucket)/",
            "/storage/v1/object/authenticated/\(goodsPhotoBucket)/",
            "/storage/v1/object/\(goodsPhotoBucket)/",
            "/object/public/\(goodsPhotoBucket)/",
            "/object/sign/\(goodsPhotoBucket)/",
            "/object/authenticated/\(goodsPhotoBucket)/",
            "/object/\(goodsPhotoBucket)/"
        ]
        for prefix in prefixes where path.hasPrefix(prefix) {
            let rawPath = String(path.dropFirst(prefix.count))
            let storagePath = (rawPath.removingPercentEncoding ?? rawPath)
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return storagePath.isEmpty ? nil : storagePath
        }
        return nil
    }

    private static func normalizedRelativeStoragePath(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmed.isEmpty else {
            return nil
        }
        let bucketPrefix = "\(goodsPhotoBucket)/"
        if trimmed.hasPrefix(bucketPrefix) {
            return String(trimmed.dropFirst(bucketPrefix.count))
        }
        guard !trimmed.hasPrefix("http://"),
              !trimmed.hasPrefix("https://"),
              !trimmed.hasPrefix("storage/v1/"),
              !trimmed.hasPrefix("object/")
        else {
            return nil
        }
        return trimmed
    }

    private static func percentEncodedPath(_ path: String) -> String {
        path.split(separator: "/", omittingEmptySubsequences: true)
            .map { segment in
                String(segment).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String(segment)
            }
            .joined(separator: "/")
    }
}
