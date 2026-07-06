import Foundation

enum GoodsInventoryCreateMetaTilePresentation {
    static func missingSetupCount(
        for meta: GoodsCreateMetaDraft,
        allowsMemberSelection: Bool,
        memberName: String?
    ) -> Int {
        var count = meta.tagNames.isEmpty ? 1 : 0
        // メンバー選択が可能な文脈でメンバー未設定なら、未設定項目としてカウントする。
        if allowsMemberSelection, memberName?.isEmpty != false {
            count += 1
        }
        return count
    }

    static func tagLine(for tagNames: [String]) -> String? {
        guard !tagNames.isEmpty else {
            return nil
        }
        let visibleTags = tagNames.prefix(2).map { "# \($0)" }.joined(separator: " ")
        return tagNames.count > 2 ? "\(visibleTags) ..." : visibleTags
    }
}
