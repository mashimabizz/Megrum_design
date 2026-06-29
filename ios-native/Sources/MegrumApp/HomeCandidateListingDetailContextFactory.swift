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
            offeredItems: HomeCandidateListingOfferedItemsBuilder.offeredItems(
                listing: listing,
                listingInventory: listingInventory,
                candidate: candidate
            ),
            offeredCashAmount: IndividualListingHaveCashSummary.extract(from: listing.note).summary?.amount
        )
    }
}
