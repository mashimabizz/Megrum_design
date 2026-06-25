import Foundation
import MegrumCore

struct IndividualListingSelectionFilter: Equatable {
    var searchText = ""
    var groupID: UUID?
    var goodsTypeID: UUID?
    var tagNames: Set<String> = []

    var isActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || groupID != nil
            || goodsTypeID != nil
            || !tagNames.isEmpty
    }

    mutating func reconcile(availableGroupIDs: Set<UUID>, availableGoodsTypeIDs: Set<UUID>, availableTagNames: Set<String>) {
        if let groupID, !availableGroupIDs.contains(groupID) {
            self.groupID = nil
        }
        if let goodsTypeID, !availableGoodsTypeIDs.contains(goodsTypeID) {
            self.goodsTypeID = nil
        }
        tagNames.formIntersection(availableTagNames)
    }

    func matches(_ item: GoodsItem) -> Bool {
        matches(
            title: item.title,
            groupID: item.groupID,
            goodsTypeID: item.goodsTypeID,
            tags: item.tags
        )
    }

    func matches(_ item: WishItem) -> Bool {
        matches(
            title: item.title,
            groupID: item.groupID,
            goodsTypeID: item.goodsTypeID,
            tags: item.tags
        )
    }

    private func matches(title: String, groupID itemGroupID: UUID?, goodsTypeID itemGoodsTypeID: UUID?, tags: [GoodsTag]) -> Bool {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSearch.isEmpty {
            let matchesTitle = title.localizedCaseInsensitiveContains(trimmedSearch)
            let matchesTag = tags.contains { $0.name.localizedCaseInsensitiveContains(trimmedSearch) }
            guard matchesTitle || matchesTag else {
                return false
            }
        }
        if let groupID, itemGroupID != groupID {
            return false
        }
        if let goodsTypeID, itemGoodsTypeID != goodsTypeID {
            return false
        }
        if !tagNames.isEmpty {
            let itemTagNames = Set(tags.map(\.name))
            if !tagNames.isSubset(of: itemTagNames) {
                return false
            }
        }
        return true
    }
}

enum IndividualListingSelectionFilterChoices {
    static func groups(items: [GoodsItem], allGroups: [OshiGroup]) -> [OshiGroup] {
        GoodsCollectionFilterChoices.groups(items: items, allGroups: allGroups)
    }

    static func goodsTypes(items: [GoodsItem], allGoodsTypes: [GoodsType]) -> [GoodsType] {
        GoodsCollectionFilterChoices.goodsTypes(items: items, allGoodsTypes: allGoodsTypes)
    }

    static func tagNames(items: [GoodsItem], filter: IndividualListingSelectionFilter, limit: Int = 20) -> [String] {
        GoodsCollectionFilterChoices.tagNames(
            items: items,
            selectedGroupID: filter.groupID,
            selectedGoodsTypeID: filter.goodsTypeID,
            limit: limit
        )
    }

    static func groups(wishes: [WishItem], allGroups: [OshiGroup]) -> [OshiGroup] {
        let usedGroupIDs = Set(wishes.compactMap(\.groupID))
        return allGroups.filter { usedGroupIDs.contains($0.id) }
    }

    static func goodsTypes(wishes: [WishItem], allGoodsTypes: [GoodsType]) -> [GoodsType] {
        let usedGoodsTypeIDs = Set(wishes.compactMap(\.goodsTypeID))
        return allGoodsTypes.filter { usedGoodsTypeIDs.contains($0.id) }
    }

    static func tagNames(wishes: [WishItem], filter: IndividualListingSelectionFilter, limit: Int = 20) -> [String] {
        let names = wishes
            .filter { wish in
                (filter.groupID == nil || wish.groupID == filter.groupID)
                    && (filter.goodsTypeID == nil || wish.goodsTypeID == filter.goodsTypeID)
            }
            .flatMap { $0.tags.map(\.name) }
        return TagNameNormalizer.uniqueSorted(names, limit: limit)
    }
}
