import Foundation
import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeWishHitDetailSheet: View {
    var selection: HomeDiscoverySheetPayload
    var viewerOfferGoods: [HomeMockGoods]
    var addedExtraCandidateIDs: Set<UUID>
    var showsOtherExchangeRows: Bool = true
    var bottomButtonTitle: String = "この内容で打診する"
    var preselectFirstOffer: Bool = true
    var onOpenOwnerProfile: (UUID) -> Void
    var onOpenNestedSheet: (HomeDiscoverySheet) -> Void
    var onStartProposal: (HomeDiscoveryProposalSelection) -> Void
    var onCopyToWish: (HomeMockGoods) -> Void
    var isWishCopyInProgress: Bool
    @State private var selectedOfferIndex: Int?

    var body: some View {
        HomeSheetScaffold(
            bottomButton: bottomButtonTitle,
            showsWishCopyButton: false,
            wishCopyButtonDisabled: isWishCopyInProgress,
            wishCopyButtonAction: { onCopyToWish(selection.goods) },
            bottomButtonDisabled: selectedOfferIndex == nil,
            bottomButtonAction: startProposal
        ) {
            HomeSelectedGoodsHeader(
                goods: selection.goods,
                conditionTags: selection.conditionTags,
                exchangeSummary: HomeDiscoveryOwnerExchangeSummary.fromListingSignals(selection.signals),
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
                    selectedIndices: selectedOfferIndex.map { [$0] } ?? [],
                    selectedBannerText: "これを譲る",
                    onSelect: { selectedOfferIndex = $0 }
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
        guard preselectFirstOffer else {
            selectedOfferIndex = nil
            return
        }
        selectedOfferIndex = offerGoods.isEmpty ? nil : 0
    }

    private func startProposal() {
        guard let selectedOfferIndex,
              offerGoods.indices.contains(selectedOfferIndex)
        else {
            return
        }
        onStartProposal(
            HomeDiscoveryProposalSelection(
                receiverGoodsID: selection.goods.id,
                senderGoodsIDs: [offerGoods[selectedOfferIndex].id],
                matchType: .forward,
                receiverGoods: selection.goods,
                senderGoods: [offerGoods[selectedOfferIndex]],
                exchangeMethod: selection.signals.preferredProposalExchangeMethod
            )
        )
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
