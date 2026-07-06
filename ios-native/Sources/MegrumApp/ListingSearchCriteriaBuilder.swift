import Foundation
import MegrumCore

/// 個別募集の「求めるもの」条件を検索フィルタへ変換した結果。
struct ListingSearchCriteria: Equatable {
    var groupIDs: Set<UUID> = []
    var memberIDs: Set<UUID> = []
    var goodsTypeIDs: Set<UUID> = []
    var tagNames: Set<String> = []
    var wantsCashOK = false

    var isEmpty: Bool {
        groupIDs.isEmpty && memberIDs.isEmpty && goodsTypeIDs.isEmpty && tagNames.isEmpty && !wantsCashOK
    }
}

/// 「個別募集から探す」：自分の募集の選択肢を検索条件（項目内OR）へ変換する。
/// - wish型選択肢：参照する ほしいもの の グループ/メンバー/種別/シリーズ を合算
/// - 条件指定型：wishGroupID / wishGoodsTypeID / メンバー指定 / シリーズ名を合算
///   （「これらのメンバー以外」の除外指定は検索側で表現できないため加えない）
/// - 定価交換型：定価交換OK（wantsCashOK）を立てる
enum ListingSearchCriteriaBuilder {
    static func criteria(for listing: IndividualListing, wishes: [WishItem]) -> ListingSearchCriteria {
        var criteria = ListingSearchCriteria()
        for option in listing.options {
            merge(option: option, wishes: wishes, into: &criteria)
        }
        return criteria
    }

    /// 1つの選択肢だけを検索条件へ変換する。
    static func criteria(for option: IndividualListingWishOption, wishes: [WishItem]) -> ListingSearchCriteria {
        var criteria = ListingSearchCriteria()
        merge(option: option, wishes: wishes, into: &criteria)
        return criteria
    }

    private static func merge(
        option: IndividualListingWishOption,
        wishes: [WishItem],
        into criteria: inout ListingSearchCriteria
    ) {
        let wishByID = Dictionary(wishes.map { ($0.id, $0) }) { first, _ in first }

        for option in [option] {
            if option.isCashOffer || option.cashAmount != nil {
                criteria.wantsCashOK = true
                continue
            }

            if option.wishes.isEmpty {
                // 条件指定型
                if let groupID = option.wishGroupID {
                    criteria.groupIDs.insert(groupID)
                }
                if let goodsTypeID = option.wishGoodsTypeID {
                    criteria.goodsTypeIDs.insert(goodsTypeID)
                }
                if !option.excludesWishMembers {
                    criteria.memberIDs.formUnion(option.wishMemberIDs)
                }
                criteria.tagNames.formUnion(
                    option.wishSeriesNames.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                )
                continue
            }

            for wishQuantity in option.wishes {
                guard let wish = wishByID[wishQuantity.itemID] else {
                    continue
                }
                if let groupID = wish.groupID {
                    criteria.groupIDs.insert(groupID)
                }
                if let memberID = wish.memberID {
                    criteria.memberIDs.insert(memberID)
                }
                if let goodsTypeID = wish.goodsTypeID {
                    criteria.goodsTypeIDs.insert(goodsTypeID)
                }
                criteria.tagNames.formUnion(wish.tags.map(\.name))
            }
            // wish が手元に無い（読み込み前など）場合のフォールバック
            if let groupID = option.wishGroupID {
                criteria.groupIDs.insert(groupID)
            }
            if let goodsTypeID = option.wishGoodsTypeID {
                criteria.goodsTypeIDs.insert(goodsTypeID)
            }
        }
    }

    /// 検索画面のチップに出す募集タイトル：「譲るグッズ名（ほかn点）」。
    static func title(for listing: IndividualListing, inventory: [GoodsItem]) -> String {
        let goodsByID = Dictionary(inventory.map { ($0.id, $0) }) { first, _ in first }
        let firstTitle = listing.haves.first.flatMap { goodsByID[$0.itemID]?.title }
        let base: String
        if let firstTitle, !firstTitle.isEmpty {
            base = firstTitle
        } else if listing.haves.isEmpty {
            base = "定価でおゆずり"
        } else {
            base = "個別募集"
        }
        let extraCount = max(0, listing.haves.count - 1)
        return extraCount > 0 ? "\(base) ほか\(extraCount)点" : base
    }
}
