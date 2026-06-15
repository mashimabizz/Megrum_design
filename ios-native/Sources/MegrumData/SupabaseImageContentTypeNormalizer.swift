enum SupabaseImageContentTypeNormalizer {
    static func lenient(_ value: String) -> String {
        switch value.lowercased() {
        case "image/png":
            "image/png"
        case "image/webp":
            "image/webp"
        default:
            "image/jpeg"
        }
    }

    static func lenientFileExtension(for contentType: String) -> String {
        switch lenient(contentType) {
        case "image/png":
            "png"
        case "image/webp":
            "webp"
        default:
            "jpg"
        }
    }
}
