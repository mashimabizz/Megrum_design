import Foundation
import MegrumCore

enum SearchResultFilterPolicy {
    static func filteredResults(
        _ results: [SearchResultItem],
        selectedMemberID: UUID?,
        selectedGoodsTypeID: UUID?,
        selectedGoodsTagNames: Set<String>,
        selectedPaymentMethods: Set<UserPaymentMethod>,
        selectedExchangeMethod: ExchangeMethod?,
        selectedMeetupPrefecture: String,
        conditionMatches: SearchConditionMatchFilters,
        wishes: [WishItem],
        listings: [IndividualListing],
        viewerInventory: [GoodsItem] = [],
        viewer: UserProfile?
    ) -> [SearchResultItem] {
        results.filter { result in
            let item = result.item
            if let selectedMemberID, item.memberID != selectedMemberID {
                return false
            }
            if let selectedGoodsTypeID, item.goodsTypeID != selectedGoodsTypeID {
                return false
            }
            if !selectedGoodsTagNames.isEmpty {
                let itemTagNames = Set(item.tags.map(\.name))
                if !selectedGoodsTagNames.isSubset(of: itemTagNames) {
                    return false
                }
            }
            if !selectedPaymentMethods.isEmpty, !paymentMethodsMatch(item.ownerPaymentMethods, selected: selectedPaymentMethods) {
                return false
            }
            if !exchangeConditionMatches(
                item: item,
                selectedExchangeMethod: selectedExchangeMethod,
                selectedMeetupPrefecture: selectedMeetupPrefecture
            ) {
                return false
            }
            if conditionMatches.matchesWish, !itemMatchesWish(item, wishes: wishes) {
                return false
            }
            if conditionMatches.matchesIndividualListing,
               !itemMatchesPartnerIndividualListings(
                   item,
                   listings: listings,
                   viewerInventory: viewerInventory,
                   includesCash: true
               ) {
                return false
            }
            if conditionMatches.matchesExchangeCondition, !itemMatchesViewerExchangeCondition(item, viewer: viewer, selectedExchangeMethod: selectedExchangeMethod) {
                return false
            }
            if conditionMatches.matchesPaymentCondition, !itemMatchesViewerPaymentCondition(item, viewer: viewer) {
                return false
            }
            return true
        }
    }

    static func sortedResults(_ results: [SearchResultItem], sort: SearchResultSort) -> [SearchResultItem] {
        switch sort {
        case .newest:
            results
        case .title:
            results.sorted { lhs, rhs in
                lhs.item.title.localizedStandardCompare(rhs.item.title) == .orderedAscending
            }
        }
    }

    static func itemMatchesWish(_ item: GoodsItem, wishes: [WishItem]) -> Bool {
        wishes.contains { wish in
            let groupMatches = wish.groupID == nil || item.groupID == wish.groupID
            let memberMatches = wish.memberID == nil || item.memberID == wish.memberID
            let typeMatches = wish.goodsTypeID == nil || item.goodsTypeID == wish.goodsTypeID
            let wishTagNames = Set(wish.tags.map(\.name))
            let tagMatches = wishTagNames.isEmpty || !wishTagNames.isDisjoint(with: Set(item.tags.map(\.name)))
            return groupMatches && memberMatches && typeMatches && tagMatches
        }
    }

    static func itemMatchesPartnerIndividualListings(
        _ item: GoodsItem,
        listings: [IndividualListing],
        viewerInventory: [GoodsItem],
        includesCash: Bool = true
    ) -> Bool {
        let availableViewerInventory = viewerInventory.filter { $0.marketAvailableQuantity > 0 }
        return listings.contains { listing in
            guard listing.status == .active,
                  listing.ownerID == item.ownerID,
                  listingIncludesItem(listing, item: item)
            else {
                return false
            }
            return listing.options.contains { option in
                if includesCash && option.isCashOffer {
                    return true
                }
                return availableViewerInventory.contains { viewerItem in
                    optionWantsViewerGoods(option, viewerItem: viewerItem)
                }
            }
        }
    }

    private static func listingIncludesItem(_ listing: IndividualListing, item: GoodsItem) -> Bool {
        if listing.haves.contains(where: { $0.itemID == item.id }) {
            return true
        }
        if fieldMatches(listing.haveGroupID, item.groupID),
           fieldMatches(listing.haveGoodsTypeID, item.goodsTypeID) {
            return true
        }
        return listing.haves.isEmpty && listing.haveGroupID == nil && listing.haveGoodsTypeID == nil
    }

    private static func optionWantsViewerGoods(
        _ option: IndividualListingWishOption,
        viewerItem: GoodsItem
    ) -> Bool {
        guard !option.isCashOffer else {
            return false
        }
        if option.wishes.contains(where: { $0.itemID == viewerItem.id }) {
            return true
        }
        guard option.wishGroupID != nil || option.wishGoodsTypeID != nil else {
            return false
        }
        return fieldMatches(option.wishGroupID, viewerItem.groupID)
            && fieldMatches(option.wishGoodsTypeID, viewerItem.goodsTypeID)
    }

    private static func paymentMethodsMatch(_ ownerMethods: [UserPaymentMethod], selected: Set<UserPaymentMethod>) -> Bool {
        !Set(ownerMethods).isDisjoint(with: selected)
    }

    private static func exchangeConditionMatches(
        item: GoodsItem,
        selectedExchangeMethod: ExchangeMethod?,
        selectedMeetupPrefecture: String
    ) -> Bool {
        if let selectedExchangeMethod, !exchangeMethodMatches(item.exchangeMethod, selected: selectedExchangeMethod) {
            return false
        }
        if !selectedMeetupPrefecture.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           item.ownerPrefecture != selectedMeetupPrefecture {
            return false
        }
        return true
    }

    private static func itemMatchesViewerExchangeCondition(
        _ item: GoodsItem,
        viewer: UserProfile?,
        selectedExchangeMethod: ExchangeMethod?
    ) -> Bool {
        if let selectedExchangeMethod {
            return exchangeMethodMatches(item.exchangeMethod, selected: selectedExchangeMethod)
        }
        guard let prefecture = viewer?.prefecture, !prefecture.isEmpty else {
            return true
        }
        return item.ownerPrefecture == prefecture || item.exchangeMethod == .mail || item.exchangeMethod == .both
    }

    private static func itemMatchesViewerPaymentCondition(_ item: GoodsItem, viewer: UserProfile?) -> Bool {
        guard let viewerMethods = viewer?.paymentMethods, !viewerMethods.isEmpty else {
            return true
        }
        return !Set(viewerMethods).isDisjoint(with: Set(item.ownerPaymentMethods))
    }

    private static func exchangeMethodMatches(_ itemMethod: ExchangeMethod?, selected: ExchangeMethod) -> Bool {
        switch selected {
        case .hand:
            itemMethod == .hand || itemMethod == .both
        case .mail:
            itemMethod == .mail || itemMethod == .both
        case .both:
            itemMethod == .both
        }
    }

    private static func fieldMatches(_ expected: UUID?, _ actual: UUID?) -> Bool {
        guard let expected else {
            return true
        }
        return expected == actual
    }
}
