import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeWishHitDetailSheet: View {
    var selection: HomeDiscoverySheetPayload
    var viewerOfferGoods: [HomeMockGoods]
    var addedExtraCandidateIDs: Set<UUID>
    var showsOtherExchangeRows: Bool = true
    var bottomButtonTitle: String = "交換内容を確認する"
    var preselectFirstOffer: Bool = true
    var onOpenOwnerProfile: (UUID) -> Void
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void
    var onStartProposal: (HomeDiscoveryProposalSelection) -> Void
    var onCopyToWish: (HomeMockGoods) -> Void
    var isWishCopyInProgress: Bool
    @State private var presentationState = HomeWishHitDetailPresentationState()

    var body: some View {
        HomeSheetScaffold(
            bottomButton: bottomButtonTitle,
            showsWishCopyButton: false,
            wishCopyButtonDisabled: isWishCopyInProgress,
            wishCopyButtonAction: { onCopyToWish(selection.goods) },
            bottomButtonDisabled: !presentationState.canStartProposal,
            bottomButtonAction: startProposal
        ) {
            HomeSelectedGoodsHeader(
                goods: selection.goods,
                conditionTags: selection.conditionTags,
                exchangeSummary: HomeDiscoveryOwnerExchangeSummary.fromCandidateSignals(selection.signals),
                exchangeCalendarContext: HomePartnerExchangeCalendarContext.from(
                    signals: selection.signals,
                    ownerName: selection.goods.ownerSummary?.displayName
                ),
                listingNote: selection.individualListingSelection.listingNote,
                listingDetail: selection.individualListingSelection.detail,
                onOpenOwnerProfile: onOpenOwnerProfile
            )

            Divider().opacity(0.55)

            HomeSheetSectionTitle(
                systemName: "gift",
                title: "あなたが譲れる相手のWish"
            )

            if offerGoods.isEmpty {
                HomeNoMatchingOfferGoodsPanel()
            } else {
                HomeGoodsImagePanelPagedGrid(
                    goods: offerGoods,
                    selectedIndices: presentationState.selectedOfferIndices,
                    selectedBannerText: "これを譲る",
                    onSelect: { presentationState.selectOffer(at: $0) }
                )
                .overlay(alignment: .bottomTrailing) {
                    Text("\(offerGoods.count)件の候補")
                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                        .foregroundStyle(MegrumTheme.lavender)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.92), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(MegrumTheme.lavender.opacity(0.18), lineWidth: 1)
                        }
                        .padding(.trailing, 18)
                        .padding(.bottom, 2)
                }
            }

            if showsOtherExchangeRows {
                HomeOtherExchangeRows(
                    addedCandidateIDs: addedExtraCandidateIDs,
                    excludedGoodsIDs: [selection.goods.id],
                    onOpenNestedSheet: onOpenNestedSheet
                )
            }
        }
        .onAppear(perform: prepareInitialSelection)
        .onChange(of: selection.id) { _, _ in
            prepareInitialSelection()
        }
    }

    private var offerGoods: [HomeMockGoods] {
        HomeWishHitOfferGoodsPolicy.offerGoods(
            viewerOfferGoods: viewerOfferGoods,
            matchedOfferGoodsIDs: selection.signals.wishMatchedOfferGoodsIDs,
            preferredOfferGoodsID: selection.preferredOfferGoodsID
        )
    }

    private func prepareInitialSelection() {
        presentationState.prepareInitialSelection(
            preselectFirstOffer: preselectFirstOffer,
            offerGoods: offerGoods
        )
    }

    private func startProposal() {
        guard let proposalSelection = presentationState.proposalSelection(
            selection: selection,
            offerGoods: offerGoods
        ) else {
            return
        }
        onStartProposal(proposalSelection)
    }
}

enum HomeWishHitOfferGoodsPolicy {
    static func offerGoods(
        viewerOfferGoods: [HomeMockGoods],
        matchedOfferGoodsIDs: [UUID],
        preferredOfferGoodsID: UUID?
    ) -> [HomeMockGoods] {
        let matchedOfferIDs = Set(matchedOfferGoodsIDs)
        guard !matchedOfferIDs.isEmpty else {
            return []
        }
        return HomeOfferGoodsOrdering.ordered(
            viewerOfferGoods.filter { matchedOfferIDs.contains($0.id) },
            preferredOfferGoodsID: preferredOfferGoodsID
        )
    }
}
