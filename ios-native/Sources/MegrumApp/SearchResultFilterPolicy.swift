import Foundation
import MegrumCore

enum SearchResultFilterPolicy {
    static func filteredResults(
        _ results: [SearchResultItem],
        selectedMemberIDs: Set<UUID>,
        selectedGoodsTypeIDs: Set<UUID>,
        selectedGoodsTagNames: Set<String>,
        selectedPaymentMethods: Set<UserPaymentMethod>,
        selectedExchangeMethod: ExchangeMethod?,
        selectedMeetupPrefecture: String,
        wantsMyGoodsOnly: Bool,
        wantsCashOK: Bool,
        listings: [IndividualListing],
        viewerInventory: [GoodsItem] = []
    ) -> [SearchResultItem] {
        results.filter { result in
            let item = result.item
            if !selectedMemberIDs.isEmpty {
                guard let memberID = item.memberID, selectedMemberIDs.contains(memberID) else {
                    return false
                }
            }
            if !selectedGoodsTypeIDs.isEmpty {
                guard let goodsTypeID = item.goodsTypeID, selectedGoodsTypeIDs.contains(goodsTypeID) else {
                    return false
                }
            }
            if !selectedGoodsTagNames.isEmpty {
                // シリーズは複数選択OR
                let itemTagNames = Set(item.tags.map(\.name))
                if selectedGoodsTagNames.isDisjoint(with: itemTagNames) {
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
            if wantsMyGoodsOnly,
               !itemMatchesPartnerIndividualListings(
                   item,
                   listings: listings,
                   viewerInventory: viewerInventory,
                   includesCash: false
               ) {
                return false
            }
            if wantsCashOK, !ownerHasCashListing(item, listings: listings) {
                return false
            }
            return true
        }
    }

    /// 相手（結果の持ち主）が定価交換の選択肢を持っているか。
    static func ownerHasCashListing(_ item: GoodsItem, listings: [IndividualListing]) -> Bool {
        listings.contains { listing in
            listing.status == .active
                && listing.ownerID == item.ownerID
                && listing.options.contains(where: \.isCashOffer)
        }
    }

    static func sortedResults(_ results: [SearchResultItem], sort: SearchResultSort) -> [SearchResultItem] {
        // 需要順・新着順とも、まずプレミアム優先の安定ソート。
        // 需要順の並べ替え自体は SearchResultDemandListBuilder がセクション単位で行う。
        switch sort {
        case .demand, .newest:
            stableMegrumPlusPrioritySort(results)
        }
    }

    private static func stableMegrumPlusPrioritySort(_ results: [SearchResultItem]) -> [SearchResultItem] {
        results.enumerated()
            .sorted { lhs, rhs in
                let lhsRank = megrumPlusRank(lhs.element)
                let rhsRank = megrumPlusRank(rhs.element)
                if lhsRank != rhsRank {
                    return lhsRank > rhsRank
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    private static func megrumPlusRank(_ result: SearchResultItem) -> Int {
        result.item.ownerHasMegrumPlus == true ? 1 : 0
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
        guard fieldMatches(option.wishGroupID, viewerItem.groupID),
              fieldMatches(option.wishGoodsTypeID, viewerItem.goodsTypeID)
        else {
            return false
        }
        // メンバー指定/除外・シリーズ・数量もホーム側（iter1226.338）と同じ基準で判定する。
        if !option.wishMemberIDs.isEmpty {
            let matchesMember = viewerItem.memberID.map(option.wishMemberIDs.contains) ?? false
            if option.excludesWishMembers {
                if matchesMember {
                    return false
                }
            } else if !matchesMember {
                return false
            }
        }
        if !option.wishSeriesNames.isEmpty {
            let wantedSeries = Set(option.wishSeriesNames.compactMap(HomeCandidateTagMatcher.normalizedName))
            let itemTags = Set(viewerItem.tags.compactMap { HomeCandidateTagMatcher.normalizedName($0.name) })
            if !wantedSeries.isEmpty, wantedSeries.isDisjoint(with: itemTags) {
                return false
            }
        }
        if option.wishQuantity > 1, viewerItem.marketAvailableQuantity < option.wishQuantity {
            return false
        }
        return true
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
