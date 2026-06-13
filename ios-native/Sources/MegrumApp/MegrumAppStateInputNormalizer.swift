import Foundation

enum MegrumAppStateInputNormalizer {
    static func prefecture(_ value: String?) -> String? {
        let normalized = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return normalized.isEmpty ? nil : normalized
    }

    static func tagNames(_ tagNames: [String]) -> [String] {
        tagNames.reduce(into: []) { result, raw in
            guard result.count < 5 else {
                return
            }
            let normalized = raw
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "#＃"))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty else {
                return
            }
            let clipped = String(normalized.prefix(50))
            if !result.contains(where: { $0.caseInsensitiveCompare(clipped) == .orderedSame }) {
                result.append(clipped)
            }
        }
    }

    static func profileHandle(_ handle: String) -> String? {
        var normalized = handle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        while normalized.first == "@" {
            normalized.removeFirst()
        }
        return normalized.isEmpty ? nil : normalized
    }

    static func postalCode(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(7))
    }
}
