import Foundation
import MegrumCore
import MegrumData

enum HomeCandidateListingDetailContextFactory {
    static func detailContext(
        listing: SupabaseHomeListingRow,
        wantedLogic: ListingLogic,
        offeredLogic: ListingLogic,
        wantedMinimumCount: Int,
        offeredMinimumCount: Int,
        wantedOptions: [HomeIndividualListingWantedOption],
        listingInventory: [SupabaseHomeGoodsRow],
        candidate: SupabaseHomeGoodsRow?
    ) -> HomeIndividualListingDetailContext {
        HomeIndividualListingDetailContext(
            listingID: listing.id,
            wantedLogic: wantedLogic,
            offeredLogic: offeredLogic,
            wantedMinimumCount: wantedMinimumCount,
            offeredMinimumCount: offeredMinimumCount,
            wantedOptions: wantedOptions,
            offeredItems: offeredItems(
                listing: listing,
                listingInventory: listingInventory,
                candidate: candidate
            ),
            offeredCashAmount: IndividualListingHaveCashSummary.extract(from: listing.note).summary?.amount
        )
    }

    private static func offeredItems(
        listing: SupabaseHomeListingRow,
        listingInventory: [SupabaseHomeGoodsRow],
        candidate: SupabaseHomeGoodsRow?
    ) -> [HomeIndividualListingOfferedItem] {
        let quantityByID = listingHaveQuantityByID(listing)
        let inventoryForListing = listingInventory.filter { $0.userId == listing.userId }
        let inventoryByID = Dictionary(uniqueKeysWithValues: inventoryForListing.map { ($0.id, $0) })
        var rows = listing.haveIds.compactMap { inventoryByID[$0] }
        if rows.isEmpty, listing.haveIds.isEmpty {
            rows = inventoryForListing.filter { HomeCandidateListingMatchPolicy.listingIncludesCandidate(listing, candidate: $0) }
        }
        if rows.isEmpty,
           let candidate,
           HomeCandidateListingMatchPolicy.listingIncludesCandidate(listing, candidate: candidate) {
            rows = [candidate]
        }

        return rows.enumerated().map { _, row in
            HomeIndividualListingOfferedItem(
                id: row.id,
                title: row.title,
                imageURL: row.photoUrls.compactMap(URL.init(string:)).first,
                quantity: quantityByID[row.id] ?? 1
            )
        }
    }

    private static func listingHaveQuantityByID(_ listing: SupabaseHomeListingRow) -> [UUID: Int] {
        var quantityByID: [UUID: Int] = [:]
        for (index, id) in listing.haveIds.enumerated() {
            let quantity = listing.haveQtys.indices.contains(index) ? listing.haveQtys[index] : 1
            quantityByID[id] = max(1, quantity)
        }
        return quantityByID
    }
}
