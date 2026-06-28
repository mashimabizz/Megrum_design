import Foundation
import MegrumCore

enum IndividualListingListPresentation {
    static let collapsedOptionSummaryThreshold = 3

    static func optionTitle(index: Int) -> String {
        "選択肢\(index)"
    }

    static func conditionStripTitle(index: Int, totalCount: Int) -> String {
        "個別募集 \(index + 1) / \(max(1, totalCount))"
    }

    static func usesCollapsedOptionSummary(optionCount: Int) -> Bool {
        optionCount >= collapsedOptionSummaryThreshold
    }

    static func optionLogicTitle(for option: IndividualListingWishOption) -> String? {
        guard !option.isCashOffer, option.wishes.count > 1 else {
            return nil
        }
        switch option.logic {
        case .all:
            return "全部ほしい"
        case .one:
            return "どれか1つだけ"
        case .atLeast:
            return ListingLogic.minimumCountTitle(option.minimumCount)
        }
    }

    static func haveLogicTitle(for listing: IndividualListing) -> String {
        switch listing.haveLogic {
        case .all:
            return "譲るもの全部"
        case .one:
            return "どれか譲る"
        case .atLeast:
            return "\(ListingLogic.minimumCountTitle(listing.haveMinimumCount))譲る"
        }
    }

    static func handoffMethodTitle(for method: IndividualListingHandoffDraft) -> String {
        switch method {
        case .both:
            "現地交換・郵送OK"
        case .local, .mail:
            method.title
        }
    }
}
