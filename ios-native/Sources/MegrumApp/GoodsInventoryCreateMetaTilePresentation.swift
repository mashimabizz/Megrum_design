import Foundation

enum GoodsInventoryCreateMetaTilePresentation {
    static func missingSetupCount(
        for meta: GoodsCreateMetaDraft,
        allowsMemberSelection: Bool,
        memberName: String?
    ) -> Int {
        var count = meta.tagNames.isEmpty ? 1 : 0
        if allowsMemberSelection, memberName == nil {
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
