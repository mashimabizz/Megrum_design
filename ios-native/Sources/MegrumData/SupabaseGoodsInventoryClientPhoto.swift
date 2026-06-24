import Foundation
import MegrumCore

extension SupabaseGoodsInventoryClient {
    func validateCreateInput(_ input: GoodsEntryInput) throws {
        guard !SupabaseTextNormalizer.trimmed(input.title).isEmpty else {
            throw SupabaseGoodsInventoryClientError.emptyTitle
        }
    }

    func normalizedPhotoURLs(_ photoURLs: [String]) -> [String] {
        SupabaseTextNormalizer.nonEmptyValues(photoURLs)
    }

    func normalizedImageContentType(_ contentType: String) throws -> String {
        switch SupabaseTextNormalizer.trimmed(contentType).lowercased() {
        case "image/jpeg", "image/jpg":
            "image/jpeg"
        case "image/png":
            "image/png"
        case "image/webp":
            "image/webp"
        case "image/gif":
            "image/gif"
        default:
            throw SupabaseGoodsInventoryClientError.unsupportedImageContentType
        }
    }

    func goodsPhotoPath(userID: UUID, contentType: String) -> String {
        let milliseconds = Int(Date().timeIntervalSince1970 * 1_000)
        return [
            userID.uuidString.lowercased(),
            "\(milliseconds)_\(UUID().uuidString.lowercased()).\(fileExtension(for: contentType))"
        ].joined(separator: "/")
    }

    func fileExtension(for contentType: String) -> String {
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

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}
