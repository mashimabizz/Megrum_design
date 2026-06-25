import Foundation
import MegrumCore
import SwiftUI

struct HomeDiscoverySheetContent: View {
    let sheet: HomeDiscoverySheet
    let viewerOfferGoods: [HomeMockGoods]
    let addedExtraCandidateIDs: Set<UUID>
    let presentationContext: HomeDiscoverySheetPresentationContext
    let copyingWishGoodsID: UUID?
    let onClose: (() -> Void)?
    let onOpenOwnerProfile: (UUID) -> Void
    let onOpenNestedSheet: (HomeDiscoverySheet) -> Void
    let onStartProposal: (HomeDiscoveryProposalSelection) -> Void
    let onCopyToWish: (HomeMockGoods) -> Void

    var body: some View {
        switch sheet {
        case .goodsHit(let payload):
            HomeGoodsHitDetailSheet(
                selection: payload,
                viewerOfferGoods: viewerOfferGoods,
                addedExtraCandidateIDs: addedExtraCandidateIDs,
                showsOtherExchangeRows: presentationContext.showsOtherExchangeRows,
                bottomButtonTitle: presentationContext.bottomButtonTitle,
                preselectPreferredOffer: presentationContext.preselectPreferredOffer,
                onOpenOwnerProfile: onOpenOwnerProfile,
                onOpenNestedSheet: onOpenNestedSheet,
                onStartProposal: onStartProposal,
                onCopyToWish: onCopyToWish,
                isWishCopyInProgress: copyingWishGoodsID == payload.goods.id
            )
        case .wishHit(let payload):
            HomeWishHitDetailSheet(
                selection: payload,
                viewerOfferGoods: viewerOfferGoods,
                addedExtraCandidateIDs: addedExtraCandidateIDs,
                showsOtherExchangeRows: presentationContext.showsOtherExchangeRows,
                bottomButtonTitle: presentationContext.bottomButtonTitle,
                preselectFirstOffer: presentationContext.preselectPreferredOffer,
                onOpenOwnerProfile: onOpenOwnerProfile,
                onOpenNestedSheet: onOpenNestedSheet,
                onStartProposal: onStartProposal,
                onCopyToWish: onCopyToWish,
                isWishCopyInProgress: copyingWishGoodsID == payload.goods.id
            )
        case .havesLookup(let payload):
            HomeHavesLookupSheet(
                payload: payload,
                onOpenNestedSheet: onOpenNestedSheet
            )
        case .extraListingHit(let payload), .extraWishHit(let payload):
            switch payload.kind {
            case .listing:
                HomeExtraHitDetailSheet(
                    payload: payload,
                    viewerOfferGoods: viewerOfferGoods,
                    onClose: onClose,
                    onOpenOwnerProfile: onOpenOwnerProfile
                )
            case .wish:
                HomeWishHitDetailSheet(
                    selection: payload.sheetPayload,
                    viewerOfferGoods: viewerOfferGoods,
                    addedExtraCandidateIDs: addedExtraCandidateIDs,
                    showsOtherExchangeRows: presentationContext.showsOtherExchangeRows,
                    bottomButtonTitle: presentationContext.bottomButtonTitle,
                    preselectFirstOffer: presentationContext.preselectPreferredOffer,
                    onOpenOwnerProfile: onOpenOwnerProfile,
                    onOpenNestedSheet: onOpenNestedSheet,
                    onStartProposal: onStartProposal,
                    onCopyToWish: onCopyToWish,
                    isWishCopyInProgress: copyingWishGoodsID == payload.goods.id
                )
            }
        }
    }
}
