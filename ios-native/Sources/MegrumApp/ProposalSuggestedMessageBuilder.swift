import Foundation

/// 打診メッセージの下書きを、シートの判定（未決＝「取引成立までに決める」項目）から自動生成する。
/// すべて確定（全行OK）なら nil を返し、既定は空メッセージのまま。
enum ProposalSuggestedMessageBuilder {
    static func make(from verdict: HomeConditionVerdict) -> String? {
        let items = undecidedItems(from: verdict)
        guard !items.isEmpty else {
            return nil
        }
        let joined = items.joined(separator: "・")
        return "はじめまして、交換をお願いしたいです！\n\(joined)は取引成立までに相談させてください。よろしくお願いします。"
    }

    private static func undecidedItems(from verdict: HomeConditionVerdict) -> [String] {
        var seen = Set<String>()
        var items: [String] = []
        for line in verdict.lines where line.badge != .ok {
            let label: String
            switch line.kind {
            case .local:
                label = "会う日程・場所"
            case .mail:
                label = "送料"
            case .payment:
                label = "お支払い方法"
            }
            if seen.insert(label).inserted {
                items.append(label)
            }
        }
        return items
    }
}
