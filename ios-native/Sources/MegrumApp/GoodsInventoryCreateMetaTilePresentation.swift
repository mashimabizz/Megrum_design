import Foundation

enum GoodsInventoryCreateMetaTilePresentation {
    static func missingSetupCount(
        for meta: GoodsCreateMetaDraft,
        allowsMemberSelection _: Bool,
        memberName _: String?
    ) -> Int {
        meta.tagNames.isEmpty ? 1 : 0
    }

    static func tagLine(for tagNames: [String]) -> String? {
        guard !tagNames.isEmpty else {
            return nil
        }
        let visibleTags = tagNames.prefix(2).map { "# \($0)" }.joined(separator: " ")
        return tagNames.count > 2 ? "\(visibleTags) ..." : visibleTags
    }
}
