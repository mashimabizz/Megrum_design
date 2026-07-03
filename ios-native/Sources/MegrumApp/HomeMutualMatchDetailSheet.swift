import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeMutualMatchDetailSheet: View {
    var candidate: HomeMutualMatchCandidate
    var allCandidates: [HomeMutualMatchCandidate]
    var appState: MegrumAppState?
    var viewerOfferGoods: [HomeMockGoods]
    var goodsTypes: [GoodsType]
    var matchedItems: [GoodsItem] = []
    var possibleItems: [GoodsItem] = []
    var conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals] = [:]
    var onOpenOwnerProfile: (UUID) -> Void
    var onStartProposal: (HomeDiscoveryProposalSelection) -> Void

    @State private var presentationState = HomeMutualMatchDetailPresentationState()

    var body: some View {
        HomeSheetScaffold(
            bottomButton: "このまま出品に進む",
            bottomButtonDisabled: selectedPair == nil,
            bottomButtonAction: startProposal
        ) {
            if let selectedPair {
                HomeMutualMatchSelectedPreviewCard(
                    pair: selectedPair,
                    review: HomeMutualMatchConditionReviewPolicy.review(for: selectedPair)
                )
            }

            HomeOtherExchangeRows(
                addedCandidateIDs: addedExtraCandidateIDs,
                excludedGoodsIDs: excludedGoodsIDs,
                listingHitPayloads: partnerScopedListingHitPayloads,
                wishHitPayloads: partnerScopedWishHitPayloads,
                onOpenNestedSheet: { presentationState.showNestedSheet($0) },
                showsLeadingDivider: !otherMutualPairs.isEmpty
            ) {
                if !otherMutualPairs.isEmpty {
                    HomeOtherMutualMatchPairsSection(
                        pairs: otherMutualPairs,
                        selectedPairID: presentationState.selectedPairID,
                        onSelect: { presentationState.selectPair(id: $0.id) }
                    )
                }
            }
        }
        .onAppear(perform: seedInitialSelection)
        .onChange(of: mutualPairs.map(\.id)) { _, _ in
            seedInitialSelection()
        }
        .modifier(
            HomeMutualMatchNestedPresentationModifier(
                nestedPresentation: $presentationState.nestedPresentation,
                appState: appState,
                viewerOfferGoods: viewerOfferGoods,
                onAddExtraProposalSelection: { selection in
                    presentationState.addExtraProposalSelectionAndDismiss(selection)
                },
                onOpenOwnerProfile: openOwnerProfile,
                onStartProposal: startNestedProposal
            )
        )
    }

    private var mutualPairs: [HomeMutualMatchProposalPair] {
        HomeMutualMatchProposalPairFactory.pairs(
            for: candidate,
            in: allCandidates,
            goodsTypes: goodsTypes
        )
    }

    private var tappedCandidatePairs: [HomeMutualMatchProposalPair] {
        HomeMutualMatchProposalPairFactory.pairs(
            for: candidate,
            in: [candidate],
            goodsTypes: goodsTypes
        )
    }

    private var otherMutualPairs: [HomeMutualMatchProposalPair] {
        let tappedPairIDs = Set(tappedCandidatePairs.map(\.id))
        return mutualPairs.filter { !tappedPairIDs.contains($0.id) }
    }

    private var selectedPair: HomeMutualMatchProposalPair? {
        if let selectedPairID = presentationState.selectedPairID,
           let pair = mutualPairs.first(where: { $0.id == selectedPairID }) {
            return pair
        }
        return tappedCandidatePairs.first ?? mutualPairs.first
    }

    private var excludedGoodsIDs: Set<UUID> {
        Set(mutualPairs.compactMap { $0.receiverDisplayItem.goods?.id })
    }

    private var addedExtraCandidateIDs: Set<UUID> {
        presentationState.addedExtraCandidateIDs
    }

    private var selectedPartnerUserID: UUID? {
        selectedPair?.receiverGoods.ownerID ?? candidate.partnerID
    }

    private var partnerScopedPayloadResolver: HomeMutualMatchPartnerScopedPayloadResolver {
        HomeMutualMatchPartnerScopedPayloadResolver(
            partnerUserID: selectedPartnerUserID,
            matchedItems: matchedItems,
            possibleItems: possibleItems,
            conditionSignalsByItemID: conditionSignalsByItemID,
            goodsTypes: goodsTypes
        )
    }

    private var partnerScopedListingHitPayloads: [HomeExtraHitPayload] {
        partnerScopedPayloadResolver.payloads(kind: .listing) { $0.goods.hasIndividualListingHit }
    }

    private var partnerScopedWishHitPayloads: [HomeExtraHitPayload] {
        partnerScopedPayloadResolver.payloads(kind: .wish) { $0.goods.hasWishHit }
    }

    private func seedInitialSelection() {
        presentationState.seedInitialSelectionIfNeeded(
            hasSelectedPair: selectedPair != nil,
            preferredPairID: tappedCandidatePairs.first?.id ?? mutualPairs.first?.id
        )
    }

    private func startProposal() {
        guard let selectedPair else {
            return
        }
        let selection = HomeDiscoveryProposalSelection(
            receiverGoodsID: selectedPair.receiverGoods.id,
            receiverGoodsIDs: [selectedPair.receiverGoods.id],
            senderGoodsIDs: selectedPair.senderDisplayItem.goods.map { [$0.id] } ?? [],
            matchType: .perfect,
            receiverGoods: selectedPair.receiverGoods,
            senderGoods: selectedPair.senderDisplayItem.goods.map { [$0] } ?? [],
            exchangeMethod: selectedPair.signals.preferredProposalExchangeMethod,
            cashAmount: selectedPair.proposalCashAmount
        )
        onStartProposal(presentationState.proposalSelection(selection))
    }

    private func startNestedProposal(_ selection: HomeDiscoveryProposalSelection) {
        presentationState.closeNestedPresentation()
        onStartProposal(selection)
    }

    private func openOwnerProfile(_ userID: UUID) {
        switch HomeDiscoveryOwnerProfileRoutingPolicy.decision(
            for: userID,
            canPresentNestedProfile: appState != nil
        ) {
        case .nested(let route):
            presentationState.showNestedProfile(route)
        case .parent(let userID):
            onOpenOwnerProfile(userID)
        }
    }
}

private struct HomeMutualMatchPartnerScopedPayloadResolver {
    var partnerUserID: UUID?
    var matchedItems: [GoodsItem]
    var possibleItems: [GoodsItem]
    var conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals]
    var goodsTypes: [GoodsType]

    func payloads(
        kind: HomeExtraHitKind,
        matching predicate: (HomeCandidateConditionSignals) -> Bool
    ) -> [HomeExtraHitPayload] {
        guard let partnerUserID else {
            return []
        }
        return candidateEntries(partnerUserID: partnerUserID)
            .filter { predicate($0.signals) }
            .map { entry in
                HomeExtraHitPayload(
                    kind: kind,
                    goods: entry.goods,
                    signals: entry.signals
                )
            }
    }

    private func candidateEntries(
        partnerUserID: UUID
    ) -> [(goods: HomeMockGoods, signals: HomeCandidateConditionSignals)] {
        let sourceItems = (matchedItems + possibleItems)
            .filter { $0.ownerID == partnerUserID }
        let uniqueItems = orderedUniqueGoods(sourceItems)
        return uniqueItems.enumerated().compactMap { index, item in
            guard let signals = conditionSignalsByItemID[item.id] else {
                return nil
            }
            return (
                goods: HomeMockGoods.from(item: item, index: index, goodsTypes: goodsTypes),
                signals: signals
            )
        }
    }

    private func orderedUniqueGoods(_ items: [GoodsItem]) -> [GoodsItem] {
        var seen: Set<UUID> = []
        var result: [GoodsItem] = []
        for item in items where seen.insert(item.id).inserted {
            result.append(item)
        }
        return result
    }
}
