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

    @State private var selectedPairID: String?
    @State private var nestedPresentation: HomeDiscoveryNestedPresentation?
    @State private var addedExtraSelections: [HomeDiscoveryProposalSelection] = []

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
                onOpenNestedSheet: { nestedPresentation = .discoverySheet($0) },
                showsLeadingDivider: !otherMutualPairs.isEmpty
            ) {
                if !otherMutualPairs.isEmpty {
                    HomeOtherMutualMatchPairsSection(
                        pairs: otherMutualPairs,
                        selectedPairID: selectedPairID,
                        onSelect: { selectedPairID = $0.id }
                    )
                }
            }
        }
        .onAppear(perform: seedInitialSelection)
        .onChange(of: mutualPairs.map(\.id)) { _, _ in
            seedInitialSelection()
        }
        .sheet(item: $nestedPresentation) { presentation in
            switch presentation {
            case .discoverySheet(let sheet):
                HomeDiscoverySheetView(
                    sheet: sheet,
                    appState: appState,
                    viewerOfferGoods: viewerOfferGoods,
                    presentationContext: .additionalCandidate,
                    onClose: {
                        nestedPresentation = nil
                    },
                    onAddExtraProposalSelection: { selection in
                        addedExtraSelections.append(selection)
                        nestedPresentation = nil
                    },
                    onOpenOwnerProfile: openOwnerProfile,
                    onStartProposal: startNestedProposal
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            case .publicProfile(let route):
                if let appState {
                    NavigationStack {
                        PublicUserProfileScreen(
                            appState: appState,
                            userID: route.userID,
                            presentationContext: .stackedFromHomeDiscoverySheet
                        )
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
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
        if let selectedPairID,
           let pair = mutualPairs.first(where: { $0.id == selectedPairID }) {
            return pair
        }
        return tappedCandidatePairs.first ?? mutualPairs.first
    }

    private var excludedGoodsIDs: Set<UUID> {
        Set(mutualPairs.compactMap { $0.receiverDisplayItem.goods?.id })
    }

    private var addedExtraCandidateIDs: Set<UUID> {
        Set(addedExtraSelections.flatMap(\.receiverGoodsIDs))
    }

    private var selectedPartnerUserID: UUID? {
        selectedPair?.receiverGoods.ownerID ?? candidate.partnerID
    }

    private var partnerScopedListingHitPayloads: [HomeExtraHitPayload] {
        partnerScopedPayloads(kind: .listing) { $0.goods.hasIndividualListingHit }
    }

    private var partnerScopedWishHitPayloads: [HomeExtraHitPayload] {
        partnerScopedPayloads(kind: .wish) { $0.goods.hasWishHit }
    }

    private func partnerScopedPayloads(
        kind: HomeExtraHitKind,
        matching predicate: (HomeCandidateConditionSignals) -> Bool
    ) -> [HomeExtraHitPayload] {
        guard let selectedPartnerUserID else {
            return []
        }
        return partnerScopedCandidateEntries(partnerUserID: selectedPartnerUserID)
            .filter { predicate($0.signals) }
            .map { entry in
                HomeExtraHitPayload(
                    kind: kind,
                    goods: entry.goods,
                    signals: entry.signals
                )
            }
    }

    private func partnerScopedCandidateEntries(
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

    private func seedInitialSelection() {
        guard selectedPair == nil else {
            return
        }
        selectedPairID = tappedCandidatePairs.first?.id ?? mutualPairs.first?.id
    }

    private func startProposal() {
        guard let selectedPair else {
            return
        }
        onStartProposal(
            HomeDiscoveryProposalSelection(
                receiverGoodsID: selectedPair.receiverGoods.id,
                receiverGoodsIDs: [selectedPair.receiverGoods.id],
                senderGoodsIDs: selectedPair.senderDisplayItem.goods.map { [$0.id] } ?? [],
                matchType: .perfect,
                receiverGoods: selectedPair.receiverGoods,
                senderGoods: selectedPair.senderDisplayItem.goods.map { [$0] } ?? [],
                exchangeMethod: HomeMutualMatchProposalExchangeMethodPolicy.preferredExchangeMethod(for: selectedPair.signals),
                cashAmount: selectedPair.proposalCashAmount
            )
            .includingExtraSelections(addedExtraSelections)
        )
    }

    private func startNestedProposal(_ selection: HomeDiscoveryProposalSelection) {
        nestedPresentation = nil
        onStartProposal(selection)
    }

    private func openOwnerProfile(_ userID: UUID) {
        switch HomeDiscoveryOwnerProfileRoutingPolicy.decision(
            for: userID,
            canPresentNestedProfile: appState != nil
        ) {
        case .nested(let route):
            nestedPresentation = .publicProfile(route)
        case .parent(let userID):
            onOpenOwnerProfile(userID)
        }
    }
}
