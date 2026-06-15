import Foundation

enum SupabaseTextNormalizer {
    static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func optional(_ text: String?) -> String? {
        guard let text else {
            return nil
        }
        let normalized = trimmed(text)
        return normalized.isEmpty ? nil : normalized
    }

    static func nonEmptyValues(_ values: [String]) -> [String] {
        values
            .map(trimmed)
            .filter { !$0.isEmpty }
    }
}
