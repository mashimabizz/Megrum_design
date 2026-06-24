import Foundation
import MegrumCore

extension MatchRelationScreen {
    var partnerProfile: PublicUserProfile? {
        appState.publicProfilesByUserID[currentTargetItem.ownerID]
    }

    var partnerHandle: String {
        partnerProfile?.profile.handle ?? "相手"
    }

    var partnerGoods: [GoodsItem] {
        let loaded = appState.publicTradeGoodsByUserID[currentTargetItem.ownerID] ?? []
        let visualQAFallback: [GoodsItem]
        if visualQAInitialScreen == .matchRelation || visualQAInitialScreen == .matchRelationCandidates {
            visualQAFallback = NativePreviewData.inventory.filter { item in
                item.ownerID == currentTargetItem.ownerID
            }
        } else {
            visualQAFallback = []
        }
        return MatchRelationComposer.deduplicatedGoods([currentTargetItem] + loaded + visualQAFallback)
            .filter { $0.marketAvailableQuantity > 0 }
    }

    var senderGoods: [GoodsItem] {
        MatchRelationComposer.selectableSenderGoods(from: appState.inventory)
    }

    var partnerListings: [IndividualListing] {
        (appState.publicListingsByUserID[currentTargetItem.ownerID] ?? [])
            .filter { $0.status == .active }
    }

    var ownListings: [IndividualListing] {
        appState.listings.filter { $0.status == .active }
    }

    var relationDetails: [MatchRelationListingDetail] {
        MatchRelationComposer.buildRelationDetails(
            ownListings: ownListings,
            partnerListings: partnerListings,
            senderGoods: senderGoods,
            partnerGoods: partnerGoods,
            highlightedItemID: currentTargetItem.id
        )
    }

    var aggregate: MatchRelationAggregate {
        MatchRelationComposer.aggregateSelection(
            details: relationDetails,
            selectedCandidateIDsByListingID: selectionState.selectedCandidateIDsByListingID,
            selectedHaveIDsByListingID: selectionState.selectedHaveIDsByListingID
        )
    }

    var simpleReceiverIDs: [UUID] {
        [currentTargetItem.id]
    }

    var simpleSenderIDs: [UUID] {
        MatchRelationComposer.fallbackSenderIDs(for: currentTargetItem, inventory: senderGoods)
    }

    var isLoading: Bool {
        appState.loadingPublicExchangeUserID == currentTargetItem.ownerID
            || appState.loadingPublicProfileUserID == currentTargetItem.ownerID
            || appState.isLoadingIndividualListings
    }

    var canStartRelationProposal: Bool {
        !aggregate.isEmpty
    }

    var canStartSimpleProposal: Bool {
        relationDetails.isEmpty && !simpleSenderIDs.isEmpty && !simpleReceiverIDs.isEmpty
    }

    var relationSeedKey: String {
        [
            currentTargetItem.id.uuidString,
            senderGoods.map(\.id.uuidString).joined(separator: ","),
            partnerGoods.map(\.id.uuidString).joined(separator: ","),
            relationDetails.map(\.id.uuidString).joined(separator: ",")
        ]
        .joined(separator: "|")
    }

    var swipeItems: [GoodsItem] {
        MatchRelationComposer.relationSwipeItems(
            homeMatchedItems: appState.homeMatchedItems,
            currentTarget: currentTargetItem
        )
    }

    var previousSwipeTarget: GoodsItem? {
        MatchRelationComposer.adjacentSwipeTarget(
            in: swipeItems,
            currentID: currentTargetItem.id,
            direction: .previous
        )
    }

    var nextSwipeTarget: GoodsItem? {
        MatchRelationComposer.adjacentSwipeTarget(
            in: swipeItems,
            currentID: currentTargetItem.id,
            direction: .next
        )
    }

    var ownDetails: [MatchRelationListingDetail] {
        relationDetails.filter(\.isMyListing)
    }

    var partnerDetails: [MatchRelationListingDetail] {
        relationDetails.filter { !$0.isMyListing }
    }

    var currentSenderCount: Int {
        canStartRelationProposal ? aggregate.senderIDs.count : simpleSenderIDs.count
    }

    var currentReceiverCount: Int {
        canStartRelationProposal ? aggregate.receiverIDs.count : simpleReceiverIDs.count
    }
}
