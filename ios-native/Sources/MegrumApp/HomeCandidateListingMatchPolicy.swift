import Foundation
import MegrumCore
import MegrumData

enum HomeCandidateListingMatchPolicy {
    static func listingWantsViewerGoods(
        listing: SupabaseHomeListingRow,
        options: [SupabaseHomeListingWishOptionRow],
        viewerInventory: [SupabaseHomeGoodsRow]
    ) -> Bool {
        listingHasSelectableWantedOption(
            listing: listing,
            options: options,
            viewerInventory: viewerInventory,
            includesCash: false
        )
    }

    static func listingHasSelectableWantedOption(
        listing _: SupabaseHomeListingRow,
        options: [SupabaseHomeListingWishOptionRow],
        viewerInventory: [SupabaseHomeGoodsRow],
        includesCash: Bool
    ) -> Bool {
        options.contains { option in
            if includesCash && option.isCashOffer == true {
                return true
            }
            return viewerInventory.contains { viewerItem in
                optionWantsViewerGoods(option, viewerItem: viewerItem)
            }
        }
    }

    static func listingIncludesCandidate(
        _ listing: SupabaseHomeListingRow,
        candidate: SupabaseHomeGoodsRow
    ) -> Bool {
        if !listing.haveIds.isEmpty {
            return listing.haveIds.contains(candidate.id)
        }
        if HomeCandidateGoodsMatchPolicy.fieldMatches(listing.haveGroupId, candidate.groupId),
           HomeCandidateGoodsMatchPolicy.fieldMatches(listing.haveGoodsTypeId, candidate.goodsTypeId) {
            return true
        }
        return listing.haveGroupId == nil && listing.haveGoodsTypeId == nil
    }

    static func firstSelection(
        listings: [SupabaseHomeListingRow],
        optionsByListingID: [UUID: [SupabaseHomeListingWishOptionRow]],
        viewerInventory: [SupabaseHomeGoodsRow],
        listingInventory: [SupabaseHomeGoodsRow] = [],
        listingWantedInventory: [SupabaseHomeGoodsRow] = [],
        candidate: SupabaseHomeGoodsRow? = nil,
        includesCash: Bool = false
    ) -> HomeIndividualListingSelectionContext? {
        for listing in listings {
            if let candidate, !listingIncludesCandidate(listing, candidate: candidate) {
                continue
            }

            let sortedOptions = optionsByListingID[listing.id, default: []]
                .sorted { lhs, rhs in
                    if lhs.position == rhs.position {
                        return lhs.id.uuidString < rhs.id.uuidString
                    }
                    return lhs.position < rhs.position
                }
            let wantedOptions = sortedOptions.compactMap { option in
                wantedOption(
                    from: option,
                    viewerInventory: viewerInventory,
                    previewInventory: listingWantedInventory,
                    includesCash: includesCash
                )
            }
            guard let firstOption = wantedOptions.first else {
                continue
            }

            let detailWantedOptions = sortedOptions.compactMap { option in
                HomeCandidateListingWantedOptionFactory.detailWantedOption(
                    from: option,
                    viewerInventory: viewerInventory,
                    previewInventory: listingWantedInventory,
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
        return nil
    }

    static func optionWantsViewerGoods(
        _ option: SupabaseHomeListingWishOptionRow,
        viewerItem: SupabaseHomeGoodsRow
    ) -> Bool {
        guard option.isCashOffer != true else {
            return false
        }
        if option.wishIds.contains(viewerItem.id) {
            return true
        }
        guard option.wishGroupId != nil || option.wishGoodsTypeId != nil else {
            return false
        }
        return HomeCandidateGoodsMatchPolicy.fieldMatches(option.wishGroupId, viewerItem.groupId)
            && HomeCandidateGoodsMatchPolicy.fieldMatches(option.wishGoodsTypeId, viewerItem.goodsTypeId)
    }

    static func wantedOption(
        from option: SupabaseHomeListingWishOptionRow,
        viewerInventory: [SupabaseHomeGoodsRow],
        previewInventory: [SupabaseHomeGoodsRow] = [],
        includesCash: Bool
    ) -> HomeIndividualListingWantedOption? {
        HomeCandidateListingWantedOptionFactory.wantedOption(
            from: option,
            viewerInventory: viewerInventory,
            previewInventory: previewInventory,
            includesCash: includesCash
        )
    }
}
