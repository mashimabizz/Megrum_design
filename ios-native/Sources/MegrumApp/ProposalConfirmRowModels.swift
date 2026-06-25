import Foundation

struct ProposalConfirmRowItem: Identifiable {
    var title: String
    var value: String

    var id: String { "\(title):\(value)" }
}

struct ProposalConfirmLocalRows {
    var summaryText: String

    var rows: [ProposalConfirmRowItem] {
        [
            ProposalConfirmRowItem(title: "都道府県", value: prefecture),
            ProposalConfirmRowItem(title: "メモ", value: memo),
            ProposalConfirmRowItem(title: "日程", value: schedule)
        ]
    }

    private var parts: [String] {
        normalizedParts(from: summaryText)
    }

    private var prefecture: String {
        parts.first ?? "未設定"
    }

    private var memo: String {
        guard parts.count >= 3 else {
            return ""
        }
        return parts[1]
    }

    private var schedule: String {
        if parts.count >= 3 {
            return parts[2]
        }
        if parts.count == 2 {
            return parts[1]
        }
        return "未設定"
    }
}

struct ProposalConfirmShippingRows {
    var summaryText: String

    var rows: [ProposalConfirmRowItem] {
        [
            ProposalConfirmRowItem(title: "送料", value: fee),
            ProposalConfirmRowItem(title: "発送目安", value: days)
        ]
    }

    private var parts: [String] {
        normalizedParts(from: summaryText)
    }

    private var fee: String {
        cleanedValue(parts.first, prefixes: ["送料"])
    }

    private var days: String {
        cleanedValue(parts.dropFirst().first, prefixes: ["発送", "発送目安"])
    }
}

private func normalizedParts(from text: String) -> [String] {
    text
        .components(separatedBy: " / ")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty && $0 != "未設定" && $0 != "対象外" }
}

private func cleanedValue(_ value: String?, prefixes: [String]) -> String {
    guard var value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
          !value.isEmpty
    else {
        return "未設定"
    }
    for prefix in prefixes {
        if value.hasPrefix(prefix) {
            value = String(value.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    return value.isEmpty ? "未設定" : value
}
