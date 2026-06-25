import Foundation

extension SupabaseActivityWindowClient {
    func boundedLimit(_ limit: Int, upperBound: Int) -> Int {
        max(1, min(limit, upperBound))
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }

    static func makeDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }
}
