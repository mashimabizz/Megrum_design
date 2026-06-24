import Foundation
import MegrumCore

struct SearchFilterDraft: Equatable, Sendable {
    var selectedGroupID: UUID?
    var selectedMemberID: UUID?
    var selectedGoodsTypeID: UUID?
    var selectedGoodsTagNames: Set<String>
    var selectedPaymentMethods: Set<UserPaymentMethod>
    var selectedExchangeMethod: ExchangeMethod?
    var selectedMeetupDates: [Date]
    var meetupDateDraft: Date
    var selectedMeetupPrefecture: String
    var meetupPlaceMemo: String
    var shippingFee: String
    var shippingWindow: String
    var allowsOutOfConditionProposal: Bool
    var conditionMatches: SearchConditionMatchFilters

    init(
        selectedGroupID: UUID? = nil,
        selectedMemberID: UUID? = nil,
        selectedGoodsTypeID: UUID? = nil,
        selectedGoodsTagNames: Set<String> = [],
        selectedPaymentMethods: Set<UserPaymentMethod> = [],
        selectedExchangeMethod: ExchangeMethod? = nil,
        selectedMeetupDates: [Date] = [],
        meetupDateDraft: Date = Date(),
        selectedMeetupPrefecture: String = "",
        meetupPlaceMemo: String = "",
        shippingFee: String = "",
        shippingWindow: String = "",
        allowsOutOfConditionProposal: Bool = false,
        conditionMatches: SearchConditionMatchFilters = SearchConditionMatchFilters()
    ) {
        self.selectedGroupID = selectedGroupID
        self.selectedMemberID = selectedMemberID
        self.selectedGoodsTypeID = selectedGoodsTypeID
        self.selectedGoodsTagNames = selectedGoodsTagNames
        self.selectedPaymentMethods = selectedPaymentMethods
        self.selectedExchangeMethod = selectedExchangeMethod
        self.selectedMeetupDates = selectedMeetupDates
        self.meetupDateDraft = meetupDateDraft
        self.selectedMeetupPrefecture = selectedMeetupPrefecture
        self.meetupPlaceMemo = meetupPlaceMemo
        self.shippingFee = shippingFee
        self.shippingWindow = shippingWindow
        self.allowsOutOfConditionProposal = allowsOutOfConditionProposal
        self.conditionMatches = conditionMatches
    }

    var activeFilterCount: Int {
        var count = 0
        if selectedGroupID != nil { count += 1 }
        if selectedMemberID != nil { count += 1 }
        if selectedGoodsTypeID != nil { count += 1 }
        count += selectedGoodsTagNames.count
        count += selectedPaymentMethods.count
        if selectedExchangeMethod != nil { count += 1 }
        if !selectedMeetupDates.isEmpty { count += 1 }
        if !selectedMeetupPrefecture.isBlank { count += 1 }
        if !meetupPlaceMemo.isBlank { count += 1 }
        if !shippingFee.isBlank { count += 1 }
        if !shippingWindow.isBlank { count += 1 }
        if allowsOutOfConditionProposal { count += 1 }
        count += conditionMatches.activeCount
        return count
    }

    func reset() -> SearchFilterDraft {
        SearchFilterDraft(meetupDateDraft: meetupDateDraft)
    }

    mutating func applyDefaultExchangeCondition(
        settings: HomeDefaultExchangeSettings,
        viewer: UserProfile?
    ) {
        switch settings.preference {
        case .local:
            selectedExchangeMethod = .hand
        case .mail:
            selectedExchangeMethod = .mail
        case .both:
            selectedExchangeMethod = .both
        }

        if settings.requiresSamePrefecture,
           let prefecture = viewer?.prefecture,
           !prefecture.isBlank {
            selectedMeetupPrefecture = prefecture
        }
    }

    mutating func applyDefaultPaymentCondition(methods: [UserPaymentMethod]) {
        let normalizedMethods = UserPaymentMethod.normalized(methods)
        if !normalizedMethods.isEmpty {
            selectedPaymentMethods = Set(normalizedMethods)
        }
    }
}

struct SearchConditionMatchFilters: Equatable, Sendable {
    var matchesWish = false
    var matchesIndividualListing = false
    var matchesExchangeCondition = false
    var matchesPaymentCondition = false

    var activeCount: Int {
        [
            matchesWish,
            matchesIndividualListing,
            matchesExchangeCondition,
            matchesPaymentCondition
        ].filter { $0 }.count
    }

    var summaryTitles: [String] {
        var titles: [String] = []
        if matchesWish {
            titles.append("グッズ○")
        }
        if matchesIndividualListing {
            titles.append("グッズ◎")
        }
        if matchesExchangeCondition {
            titles.append("交換条件一致")
        }
        if matchesPaymentCondition {
            titles.append("支払条件一致")
        }
        return titles
    }
}

enum SearchResultSort: String, CaseIterable, Identifiable, Sendable {
    case newest
    case title

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .newest:
            "新着順"
        case .title:
            "タイトル順"
        }
    }
}

enum SearchFilterPresentation {
    static let individualListingMatchTitle = "相手の個別募集に合う"

    static func paymentSymbol(for method: UserPaymentMethod) -> String {
        switch method {
        case .bankTransfer:
            "building.columns"
        case .paypay:
            "p.circle"
        case .cashExchange:
            "yensign.circle"
        case .other:
            "ellipsis.circle"
        }
    }

}

enum SearchFilterBadgeLayering {
    static let surfaceZIndex: Double = 0
    static let badgeZIndex: Double = 20
}

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
