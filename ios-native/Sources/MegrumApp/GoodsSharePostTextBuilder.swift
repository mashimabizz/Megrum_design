import Foundation
import MegrumCore

enum GoodsSharePostTextBuilder {
    static func text(for items: [GoodsItem]) -> String {
        let tagLine = uniqueValues(hashtagValues(for: items) + ["グッズ交換"])
            .map { "#\($0)" }
            .joined(separator: " ")

        return [
            "Megrumで譲るグッズを登録しました！",
            tagLine
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
    }

    static func hashtagValues(for items: [GoodsItem]) -> [String] {
        let rawValues: [String?] = items.flatMap { item -> [String?] in
            [
                item.groupName,
                item.memberName
            ]
            + item.tags.map { Optional($0.name) }
            + [
                item.goodsTypeName
            ]
        }

        return rawValues.reduce(into: []) { result, rawValue in
            guard let tag = hashtagValue(from: rawValue) else {
                return
            }
            guard !result.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) else {
                return
            }
            result.append(tag)
        }
    }

    private static func uniqueValues(_ values: [String]) -> [String] {
        values.reduce(into: []) { result, value in
            guard !result.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) else {
                return
            }
            result.append(value)
        }
    }

    private static func hashtagValue(from rawValue: String?) -> String? {
        guard let rawValue else {
            return nil
        }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        let withoutHash = trimmed.replacingOccurrences(of: "#", with: "")
        let compact = withoutHash.components(separatedBy: .whitespacesAndNewlines).joined()
        return compact.isEmpty ? nil : compact
    }
}
