import Foundation
import MegrumCore

struct SearchFilterDraft: Equatable, Sendable {
    /// グループ・メンバー・グッズ種別は複数選択（項目内OR・項目間AND）。
    var selectedGroupIDs: Set<UUID>
    var selectedMemberIDs: Set<UUID>
    var selectedGoodsTypeIDs: Set<UUID>
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
    /// 需要マッチ：あなたのグッズを求めている相手（個別募集）だけに絞る。
    var wantsMyGoodsOnly: Bool
    /// 需要マッチ：定価交換OK（定価選択肢のある募集を持つ相手）だけに絞る。
    var wantsCashOK: Bool

    init(
        selectedGroupIDs: Set<UUID> = [],
        selectedMemberIDs: Set<UUID> = [],
        selectedGoodsTypeIDs: Set<UUID> = [],
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
        wantsMyGoodsOnly: Bool = false,
        wantsCashOK: Bool = false
    ) {
        self.selectedGroupIDs = selectedGroupIDs
        self.selectedMemberIDs = selectedMemberIDs
        self.selectedGoodsTypeIDs = selectedGoodsTypeIDs
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
        self.wantsMyGoodsOnly = wantsMyGoodsOnly
        self.wantsCashOK = wantsCashOK
    }

    /// 旧単数アクセサ（互換用）。
    var selectedGroupID: UUID? { selectedGroupIDs.first }
    var selectedMemberID: UUID? { selectedMemberIDs.first }
    var selectedGoodsTypeID: UUID? { selectedGoodsTypeIDs.first }

    var activeFilterCount: Int {
        var count = 0
        count += selectedGroupIDs.count
        count += selectedMemberIDs.count
        count += selectedGoodsTypeIDs.count
        count += selectedGoodsTagNames.count
        count += selectedPaymentMethods.count
        if selectedExchangeMethod != nil { count += 1 }
        if !selectedMeetupDates.isEmpty { count += 1 }
        if !selectedMeetupPrefecture.isBlank { count += 1 }
        if !meetupPlaceMemo.isBlank { count += 1 }
        if !shippingFee.isBlank { count += 1 }
        if !shippingWindow.isBlank { count += 1 }
        if allowsOutOfConditionProposal { count += 1 }
        if wantsMyGoodsOnly { count += 1 }
        if wantsCashOK { count += 1 }
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


enum SearchResultSort: String, CaseIterable, Identifiable, Sendable {
    case demand
    case newest

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .demand:
            "需要順"
        case .newest:
            "新着順"
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
