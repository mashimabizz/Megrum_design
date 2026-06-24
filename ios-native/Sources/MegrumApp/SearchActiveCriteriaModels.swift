import Foundation
import MegrumCore

enum SearchConditionMatchKind: String, Hashable, Sendable {
    case wish
    case individualListing
    case exchangeCondition
    case paymentCondition
}

enum SearchActiveCriteriaRemoval: Hashable, Sendable {
    case query
    case group
    case member
    case goodsType
    case goodsTag(String)
    case paymentMethod(UserPaymentMethod)
    case exchangeMethod
    case meetupDates
    case meetupPrefecture
    case meetupPlaceMemo
    case shippingFee
    case shippingWindow
    case allowsOutOfConditionProposal
    case conditionMatch(SearchConditionMatchKind)

    var id: String {
        switch self {
        case .query:
            "query"
        case .group:
            "group"
        case .member:
            "member"
        case .goodsType:
            "goods-type"
        case .goodsTag(let name):
            "tag-\(name.lowercased())"
        case .paymentMethod(let method):
            "payment-\(method.rawValue)"
        case .exchangeMethod:
            "exchange-method"
        case .meetupDates:
            "meetup-dates"
        case .meetupPrefecture:
            "meetup-prefecture"
        case .meetupPlaceMemo:
            "meetup-place-memo"
        case .shippingFee:
            "shipping-fee"
        case .shippingWindow:
            "shipping-window"
        case .allowsOutOfConditionProposal:
            "allows-out-of-condition-proposal"
        case .conditionMatch(let kind):
            "condition-\(kind.rawValue)"
        }
    }
}

struct SearchActiveCriteriaChipItem: Identifiable, Equatable, Sendable {
    var id: String { removal.id }
    var title: String
    var removal: SearchActiveCriteriaRemoval
}

enum SearchActiveCriteriaChipBuilder {
    static func chips(
        query: String,
        selectedGroup: OshiGroup?,
        selectedMember: OshiCharacter?,
        selectedGoodsType: GoodsType?,
        selectedGoodsTagNames: Set<String>,
        selectedPaymentMethods: Set<UserPaymentMethod>,
        selectedExchangeMethod: ExchangeMethod?,
        selectedMeetupDates: [Date],
        selectedMeetupPrefecture: String,
        meetupPlaceMemo: String,
        shippingFee: String,
        shippingWindow: String,
        allowsOutOfConditionProposal: Bool,
        conditionMatches: SearchConditionMatchFilters
    ) -> [SearchActiveCriteriaChipItem] {
        var chips: [SearchActiveCriteriaChipItem] = []

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            chips.append(SearchActiveCriteriaChipItem(title: trimmedQuery, removal: .query))
        }
        if let selectedGroup {
            chips.append(SearchActiveCriteriaChipItem(title: selectedGroup.name, removal: .group))
        }
        if let selectedMember {
            chips.append(SearchActiveCriteriaChipItem(title: selectedMember.name, removal: .member))
        }
        if let selectedGoodsType {
            chips.append(SearchActiveCriteriaChipItem(title: selectedGoodsType.name, removal: .goodsType))
        }
        chips.append(
            contentsOf: selectedGoodsTagNames.sorted().map { tagName in
                SearchActiveCriteriaChipItem(title: tagName, removal: .goodsTag(tagName))
            }
        )
        chips.append(
            contentsOf: selectedPaymentMethods
                .sorted { $0.displayName < $1.displayName }
                .map { method in
                    SearchActiveCriteriaChipItem(title: method.displayName, removal: .paymentMethod(method))
                }
        )
        if let selectedExchangeMethod {
            chips.append(SearchActiveCriteriaChipItem(title: selectedExchangeMethod.displayName, removal: .exchangeMethod))
        }
        if !selectedMeetupDates.isEmpty {
            chips.append(SearchActiveCriteriaChipItem(title: "日付\(selectedMeetupDates.count)件", removal: .meetupDates))
        }
        let trimmedPrefecture = selectedMeetupPrefecture.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPrefecture.isEmpty {
            chips.append(SearchActiveCriteriaChipItem(title: trimmedPrefecture, removal: .meetupPrefecture))
        }
        let trimmedPlaceMemo = meetupPlaceMemo.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPlaceMemo.isEmpty {
            chips.append(SearchActiveCriteriaChipItem(title: trimmedPlaceMemo, removal: .meetupPlaceMemo))
        }
        let trimmedShippingFee = shippingFee.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedShippingFee.isEmpty {
            chips.append(SearchActiveCriteriaChipItem(title: trimmedShippingFee, removal: .shippingFee))
        }
        if !shippingWindow.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            chips.append(SearchActiveCriteriaChipItem(title: shippingWindow, removal: .shippingWindow))
        }
        if allowsOutOfConditionProposal {
            chips.append(SearchActiveCriteriaChipItem(title: "条件外打診可", removal: .allowsOutOfConditionProposal))
        }
        if conditionMatches.matchesWish {
            chips.append(SearchActiveCriteriaChipItem(title: "グッズ○", removal: .conditionMatch(.wish)))
        }
        if conditionMatches.matchesIndividualListing {
            chips.append(SearchActiveCriteriaChipItem(title: "グッズ◎", removal: .conditionMatch(.individualListing)))
        }
        if conditionMatches.matchesExchangeCondition {
            chips.append(SearchActiveCriteriaChipItem(title: "交換条件一致", removal: .conditionMatch(.exchangeCondition)))
        }
        if conditionMatches.matchesPaymentCondition {
            chips.append(SearchActiveCriteriaChipItem(title: "支払条件一致", removal: .conditionMatch(.paymentCondition)))
        }

        return chips
    }
}
