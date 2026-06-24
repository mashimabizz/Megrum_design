import Foundation
import MegrumCore

enum HomeWishCopyInputBuilder {
    static let successToastMessage = "Wishに登録しました"
    static let failureToastMessage = "Wishに登録できませんでした"

    static func input(
        from goods: HomeMockGoods,
        groups: [OshiGroup] = [],
        goodsTypes: [GoodsType]
    ) -> GoodsEntryInput? {
        guard let groupID = copyableGroupID(for: goods, groups: groups),
              let goodsTypeID = copyableGoodsTypeID(for: goods, goodsTypes: goodsTypes)
        else {
            return nil
        }

        return GoodsEntryInput(
            kind: .wish,
            title: goods.title,
            groupID: groupID,
            memberID: goods.memberID,
            goodsTypeID: goodsTypeID,
            quantity: 1,
            tagNames: tagNames(from: goods),
            photoURLs: goods.imageURL.map { [$0.absoluteString] } ?? []
        )
    }

    static func tagNames(from goods: HomeMockGoods) -> [String] {
        let sourceTags = goods.rawTagNames.isEmpty ? goods.displayTags : goods.rawTagNames
        return MegrumAppStateInputNormalizer.tagNames(sourceTags)
    }

    static func inferredGoodsTypeID(for goods: HomeMockGoods, goodsTypes: [GoodsType]) -> UUID? {
        let comparableHints = ([goods.subtitle] + goods.displayTags + goods.rawTagNames)
            .map(comparable)
            .filter { !$0.isEmpty }

        return goodsTypes.first { goodsType in
            comparableHints.contains(comparable(goodsType.name))
        }?.id
    }

    static func inferredGroupID(for goods: HomeMockGoods, groups: [OshiGroup]) -> UUID? {
        let comparableHints = ([goods.title, goods.subtitle] + goods.displayTags + goods.rawTagNames)
            .map(comparable)
            .filter { !$0.isEmpty }

        return groups.first { group in
            comparableHints.contains(comparable(group.name))
        }?.id ?? groups.first?.id
    }

    private static func copyableGroupID(for goods: HomeMockGoods, groups: [OshiGroup]) -> UUID? {
        if let groupID = goods.groupID, groups.isEmpty || groups.contains(where: { $0.id == groupID }) {
            return groupID
        }
        return inferredGroupID(for: goods, groups: groups)
    }

    private static func copyableGoodsTypeID(for goods: HomeMockGoods, goodsTypes: [GoodsType]) -> UUID? {
        if let goodsTypeID = goods.goodsTypeID, goodsTypes.isEmpty || goodsTypes.contains(where: { $0.id == goodsTypeID }) {
            return goodsTypeID
        }
        return inferredGoodsTypeID(for: goods, goodsTypes: goodsTypes) ?? goodsTypes.first?.id
    }

    private static func comparable(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#＃"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
