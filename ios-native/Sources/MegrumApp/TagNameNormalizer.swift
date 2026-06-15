import Foundation

enum TagNameNormalizer {
    static func uniquePreservingOrder(_ names: [String], limit: Int? = nil) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for name in names {
            guard limit.map({ result.count < $0 }) ?? true else {
                break
            }
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                continue
            }
            let key = trimmed.lowercased()
            guard seen.insert(key).inserted else {
                continue
            }
            result.append(trimmed)
        }
        return result
    }

    static func uniqueSorted(_ names: [String], limit: Int) -> [String] {
        Array(
            uniquePreservingOrder(names)
                .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
                .prefix(limit)
        )
    }
}
