import Foundation
import MegrumCore
import MegrumData

enum HomeCandidateListingWantedOptionTextPolicy {
    static func title(
        option: SupabaseHomeListingWishOptionRow,
        matchingItems: [SupabaseHomeGoodsRow],
        previewItems: [HomeIndividualListingWantedPreviewItem] = []
    ) -> String {
        if let previewTitle = previewItems.first?.title {
            return previewTitle
        }
        if !option.wishIds.isEmpty {
            if let exactItem = matchingItems.first(where: { option.wishIds.contains($0.id) }) {
                return exactItem.title
            }
            return matchingItems.first?.title ?? "グッズ指定"
        }
        if let first = matchingItems.first {
            return first.title
        }
        return "条件指定"
    }

    static func subtitle(
        option: SupabaseHomeListingWishOptionRow,
        matchingCount: Int
    ) -> String? {
        if option.wishIds.count > 1 {
            if ListingLogic(rawValue: option.logic ?? "") == .atLeast {
                return ListingLogic.minimumCountTitle(option.minCount ?? 1)
            }
            return "\(option.wishIds.count)点から選択"
        }
        if option.wishGroupId != nil || option.wishGoodsTypeId != nil {
            return "\(matchingCount)件の候補"
        }
        return nil
    }
}
