import Foundation
import MegrumCore

enum IndividualListingListPresentation {
    /// 1つの選択肢内で画像をまとめ表示に切り替えるグッズ数のしきい値。
    static let collapsedGoodsSummaryThreshold = 3

    static func optionTitle(index: Int) -> String {
        "選択肢\(index)"
    }

    static func conditionStripTitle(index: Int, totalCount: Int) -> String {
        "個別募集 \(index + 1) / \(max(1, totalCount))"
    }

    /// 選択肢は最大5件まで常に個別表示する（一覧側ではまとめない）。
    static func usesCollapsedOptionSummary(optionCount: Int) -> Bool {
        false
    }

    /// 1つの選択肢に3枚以上のグッズ画像がある場合はまとめ表示にし、
    /// タップでその選択肢のグッズ一覧を開く。
    static func usesCollapsedGoodsSummary(goodsCount: Int) -> Bool {
        goodsCount >= collapsedGoodsSummaryThreshold
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
