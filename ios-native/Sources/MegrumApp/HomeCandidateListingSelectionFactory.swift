import Foundation
import MegrumCore
import MegrumData

enum HomeCandidateListingSelectionFactory {
    static func firstSelection(
        listings: [SupabaseHomeListingRow],
        optionsByListingID: [UUID: [SupabaseHomeListingWishOptionRow]],
        viewerInventory: [SupabaseHomeGoodsRow],
        listingInventory: [SupabaseHomeGoodsRow] = [],
        listingWantedInventory: [SupabaseHomeGoodsRow] = [],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]] = [:],
        candidate: SupabaseHomeGoodsRow? = nil,
        includesCash: Bool = false
    ) -> HomeIndividualListingSelectionContext? {
        for listing in listings {
            if let candidate, !HomeCandidateListingMatchPolicy.listingIncludesCandidate(listing, candidate: candidate) {
                continue
            }

            let sortedOptions = sortedOptions(
                optionsByListingID[listing.id, default: []]
            )
            let wantedOptions = sortedOptions.compactMap { option in
                HomeCandidateListingMatchPolicy.wantedOption(
                    from: option,
                    viewerInventory: viewerInventory,
                    previewInventory: listingWantedInventory,
                    tagsByInventoryID: tagsByInventoryID,
                    includesCash: includesCash
                )
            }
            guard let firstOption = wantedOptions.first else {
                continue
            }

            return selectionContext(
                listing: listing,
                sortedOptions: sortedOptions,
                firstOption: firstOption,
                wantedOptions: wantedOptions,
                viewerInventory: viewerInventory,
                listingInventory: listingInventory,
                listingWantedInventory: listingWantedInventory,
                tagsByInventoryID: tagsByInventoryID,
                candidate: candidate,
                includesCash: includesCash
            )
        }
        return nil
    }

    private static func selectionContext(
        listing: SupabaseHomeListingRow,
        sortedOptions: [SupabaseHomeListingWishOptionRow],
        firstOption: HomeIndividualListingWantedOption,
        wantedOptions: [HomeIndividualListingWantedOption],
        viewerInventory: [SupabaseHomeGoodsRow],
        listingInventory: [SupabaseHomeGoodsRow],
        listingWantedInventory: [SupabaseHomeGoodsRow],
        tagsByInventoryID: [UUID: [SupabaseHomeInventoryTagRow]],
        candidate: SupabaseHomeGoodsRow?,
        includesCash: Bool
    ) -> HomeIndividualListingSelectionContext {
        let detailWantedOptions = sortedOptions.compactMap { option in
            HomeCandidateListingWantedOptionFactory.detailWantedOption(
                from: option,
                viewerInventory: viewerInventory,
                previewInventory: listingWantedInventory,
                tagsByInventoryID: tagsByInventoryID,
                includesCash: includesCash
            )
        }
        let wantedLogic = firstOption.logic
        let offeredLogic = ListingLogic(rawValue: listing.haveLogic ?? "") ?? .all
        let wantedMinimumCount = firstOption.minimumCount
        let offeredMinimumCount = listing.haveMinCount ?? 1
        let listingNote = IndividualListingNotePresentation.userMemo(from: listing.note)
        let detail = HomeCandidateListingDetailContextFactory.detailContext(
            listing: listing,
            wantedLogic: wantedLogic,
            offeredLogic: offeredLogic,
            wantedMinimumCount: wantedMinimumCount,
            offeredMinimumCount: offeredMinimumCount,
            wantedOptions: detailWantedOptions.isEmpty ? wantedOptions : detailWantedOptions,
            listingInventory: listingInventory,
            candidate: candidate
        )

        return HomeIndividualListingSelectionContext(
            wantedLogic: wantedLogic,
            offeredLogic: offeredLogic,
            wantedMinimumCount: wantedMinimumCount,
            offeredMinimumCount: offeredMinimumCount,
            wantedOptions: wantedOptions,
            listingNote: listingNote,
            detail: detail
        )
    }

    private static func sortedOptions(
        _ options: [SupabaseHomeListingWishOptionRow]
    ) -> [SupabaseHomeListingWishOptionRow] {
        options.sorted { lhs, rhs in
            if lhs.position == rhs.position {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return lhs.position < rhs.position
        }
    }
}
