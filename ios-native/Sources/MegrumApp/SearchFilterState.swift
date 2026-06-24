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
