import Foundation
import MegrumCore

enum IndividualListingListPresentation {
    static func optionTitle(index: Int) -> String {
        "選択肢\(index)"
    }

    static func optionLogicTitle(for option: IndividualListingWishOption) -> String? {
        guard !option.isCashOffer, option.wishes.count > 1 else {
            return nil
        }
        return option.logic == .all ? "全部ほしい" : "どれか1つだけ"
    }

    static func handoffMethodTitle(for method: IndividualListingHandoffDraft) -> String {
        switch method {
        case .both:
            "現地交換・郵送交換のどちらもOK"
        case .local, .mail:
            method.title
        }
    }
}
