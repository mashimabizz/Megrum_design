import Foundation
import MegrumCore
import MegrumData

enum HomeMutualMatchListingInputResolver {
    static func activeListings(
        _ listings: [SupabaseHomeListingRow]
    ) -> [SupabaseHomeListingRow] {
        listings.filter { listing in
            guard let status = listing.status?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                  !status.isEmpty
            else {
                return true
            }
            return status == IndividualListingStatus.active.rawValue
        }
    }

    static func offeredRows(
        for listing: SupabaseHomeListingRow,
        inventory: [SupabaseHomeGoodsRow]
    ) -> [SupabaseHomeGoodsRow] {
        if !listing.haveIds.isEmpty {
            return inventory.filter { listing.haveIds.contains($0.id) }
        }
        guard listing.haveGroupId != nil || listing.haveGoodsTypeId != nil else {
            return []
        }
        return inventory.filter { row in
            HomeCandidateGoodsMatchPolicy.fieldMatches(listing.haveGroupId, row.groupId)
                && HomeCandidateGoodsMatchPolicy.fieldMatches(listing.haveGoodsTypeId, row.goodsTypeId)
        }
    }

    static func goodsRowsByID(_ rows: [SupabaseHomeGoodsRow]) -> [UUID: SupabaseHomeGoodsRow] {
        rows.reduce(into: [UUID: SupabaseHomeGoodsRow]()) { result, row in
            result[row.id] = result[row.id] ?? row
        }
    }
}
