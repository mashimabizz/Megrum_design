import Foundation
import MegrumCore
import SwiftUI

struct HomeDiscoverySheetContent: View {
    let sheet: HomeDiscoverySheet
    let viewerOfferGoods: [HomeMockGoods]
    let addedExtraCandidateIDs: Set<UUID>
    /// 「他にも交換できそうなもの」用の同じ相手の他候補（primaryシートのみ／入れ子は .empty）。iter1226.383 / FB6-1。
    var otherExchangeCandidates: HomeOtherExchangeCandidateGroups = .empty
    let presentationContext: HomeDiscoverySheetPresentationContext
    let allowsNonOshiOfferSection: Bool
    let copyingWishGoodsID: UUID?
    let onClose: (() -> Void)?
    let onOpenOwnerProfile: (UUID) -> Void
    let onOpenNestedSheet: (HomeDiscoverySheet) -> Void
    let onStartProposal: (HomeDiscoveryProposalSelection) -> Void
    let onCopyToWish: (HomeMockGoods) -> Void
    /// ガイドツアーのデモ用：グッズヒット詳細に選択済み状態を注入する（通常は nil）。
    var initialGoodsHitSelectionState: HomeListingSheetSelectionState? = nil

    var body: some View {
        switch sheet {
        case .goodsHit(let payload):
            HomeGoodsHitDetailSheet(
                selection: payload,
                viewerOfferGoods: viewerOfferGoods,
                addedExtraCandidateIDs: addedExtraCandidateIDs,
                showsOtherExchangeRows: presentationContext.showsOtherExchangeRows,
                otherExchangeCandidates: otherExchangeCandidates,
                bottomButtonTitle: presentationContext.bottomButtonTitle,
                preselectPreferredOffer: presentationContext.preselectPreferredOffer,
                initialSelectionState: initialGoodsHitSelectionState,
                onOpenOwnerProfile: onOpenOwnerProfile,
                onOpenNestedSheet: onOpenNestedSheet,
                onStartProposal: onStartProposal,
                onCopyToWish: onCopyToWish,
                isWishCopyInProgress: copyingWishGoodsID == payload.goods.id
            )
        case .wishHit(let payload):
            HomeWishHitDetailSheet(
                showsNonOshiOfferSection: allowsNonOshiOfferSection,
                selection: payload,
                viewerOfferGoods: viewerOfferGoods,
                addedExtraCandidateIDs: addedExtraCandidateIDs,
                showsOtherExchangeRows: presentationContext.showsOtherExchangeRows,
                otherExchangeCandidates: otherExchangeCandidates,
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
                viewerGoodsImageURLByID: Dictionary(
                    viewerOfferGoods.compactMap { goods in
                        goods.imageURL.map { (goods.id, $0) }
                    },
                    uniquingKeysWith: { first, _ in first }
                ),
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
                    showsNonOshiOfferSection: allowsNonOshiOfferSection,
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
