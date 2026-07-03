import Foundation
import MegrumCore

enum GoodsSharePostTextBuilder {
    static func text(
        for items: [GoodsItem],
        kind: GoodsSharePostKind = .inventory,
        leadingTextOverride: String? = nil
    ) -> String {
        let tagLine = uniqueHashtagValues(hashtagValues(for: items) + ["グッズ交換"])
            .map { "#\($0)" }
            .joined(separator: " ")

        return [
            leadingTextOverride ?? leadingText(for: kind),
            tagLine
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
    }

    static func text(for snapshot: IndividualListingShareSnapshot) -> String {
        let tagLine = uniqueHashtagValues(snapshot.hashtagValues)
            .map { "#\($0)" }
            .joined(separator: " ")
        let conditionText = snapshot.exchangeConditionLines.joined(separator: " / ")

        return [
            "Megrumで個別募集を追加しました！",
            "求めるものは1枚目、譲るものは2枚目の画像にあります。",
            "交換条件: \(conditionText)",
            "支払い方法: \(snapshot.paymentMethodsText)",
            tagLine
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
    }

    static func paymentMethodsText(methods: [UserPaymentMethod], otherNote: String?) -> String {
        let normalizedMethods = UserPaymentMethod.normalized(methods)
        guard !normalizedMethods.isEmpty else {
            return "未設定"
        }
        let trimmedOtherNote = otherNote?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return normalizedMethods
            .map { method in
                if method == .other, !trimmedOtherNote.isEmpty {
                    return trimmedOtherNote
                }
                return method.displayName
            }
            .joined(separator: ", ")
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

    static func uniqueHashtagValues(_ values: [String]) -> [String] {
        values.reduce(into: []) { result, value in
            guard let tag = hashtagValue(from: value) else {
                return
            }
            guard !result.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) else {
                return
            }
            result.append(tag)
        }
    }

    private static func leadingText(for kind: GoodsSharePostKind) -> String {
        switch kind {
        case .inventory:
            "Megrumで譲るグッズを登録しました！"
        case .wish:
            "Megrumで欲しいものを登録しました！"
        case .individualListing:
            "Megrumで個別募集を追加しました！"
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
