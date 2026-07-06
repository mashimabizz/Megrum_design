import Foundation
import MegrumCore

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
    case demandMatch
    case cashMatch

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
        case .demandMatch:
            "demand-match"
        case .cashMatch:
            "cash-match"
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
        selectedGroupNames: [String],
        selectedMemberNames: [String],
        selectedGoodsTypeNames: [String],
        selectedGoodsTagNames: Set<String>,
        selectedPaymentMethods: Set<UserPaymentMethod>,
        selectedExchangeMethod: ExchangeMethod?,
        selectedMeetupDates: [Date],
        selectedMeetupPrefecture: String,
        meetupPlaceMemo: String,
        shippingFee: String,
        shippingWindow: String,
        allowsOutOfConditionProposal: Bool,
        wantsMyGoodsOnly: Bool,
        wantsCashOK: Bool
    ) -> [SearchActiveCriteriaChipItem] {
        var chips: [SearchActiveCriteriaChipItem] = []

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            chips.append(SearchActiveCriteriaChipItem(title: trimmedQuery, removal: .query))
        }
        if !selectedGroupNames.isEmpty {
            chips.append(SearchActiveCriteriaChipItem(title: selectedGroupNames.joined(separator: "・"), removal: .group))
        }
        if !selectedMemberNames.isEmpty {
            chips.append(SearchActiveCriteriaChipItem(title: selectedMemberNames.joined(separator: "・"), removal: .member))
        }
        if !selectedGoodsTypeNames.isEmpty {
            chips.append(SearchActiveCriteriaChipItem(title: selectedGoodsTypeNames.joined(separator: "・"), removal: .goodsType))
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
        if wantsMyGoodsOnly {
            chips.append(SearchActiveCriteriaChipItem(title: "あなたのグッズを求む相手", removal: .demandMatch))
        }
        if wantsCashOK {
            chips.append(SearchActiveCriteriaChipItem(title: "定価交換OK", removal: .cashMatch))
        }

        return chips
    }
}
