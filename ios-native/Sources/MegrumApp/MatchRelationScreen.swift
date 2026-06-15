import MegrumCore
import MegrumDesign
import SwiftUI

struct MatchRelationScreen: View {
    @ObservedObject var appState: MegrumAppState
    var targetItem: GoodsItem
    var matchType: ProposalMatchType = .perfect
    var onCompletionAction: (ProposalCompletionAction) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var currentTargetItem: GoodsItem
    @State private var selectionState = MatchRelationSelectionState()
    @State private var popupTarget: MatchRelationWishPopupTarget?
    @State private var proposalTarget: MatchRelationProposalTarget?
    @State private var relationSwipeOffset: CGFloat = 0
    @State private var didApplyVisualQACandidateExpansion = false
    private let visualQAInitialScreen: VisualQAInitialScreen?

    init(
        appState: MegrumAppState,
        targetItem: GoodsItem,
        matchType: ProposalMatchType = .perfect,
        visualQAInitialScreen: VisualQAInitialScreen? = nil,
        onCompletionAction: @escaping (ProposalCompletionAction) -> Void = { _ in }
    ) {
        self._appState = ObservedObject(wrappedValue: appState)
        self.targetItem = targetItem
        self.matchType = matchType
        self.onCompletionAction = onCompletionAction
        self.visualQAInitialScreen = visualQAInitialScreen ?? VisualQAPreviewMode.initialScreen(
            environment: ProcessInfo.processInfo.environment
        )
        _currentTargetItem = State(initialValue: targetItem)
    }

    private var partnerProfile: PublicUserProfile? {
        appState.publicProfilesByUserID[currentTargetItem.ownerID]
    }

    private var partnerHandle: String {
        partnerProfile?.profile.handle ?? "相手"
    }

    private var partnerGoods: [GoodsItem] {
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

    private var senderGoods: [GoodsItem] {
        MatchRelationComposer.selectableSenderGoods(from: appState.inventory)
    }

    private var partnerListings: [IndividualListing] {
        (appState.publicListingsByUserID[currentTargetItem.ownerID] ?? [])
            .filter { $0.status == .active }
    }

    private var ownListings: [IndividualListing] {
        appState.listings.filter { $0.status == .active }
    }

    private var relationDetails: [MatchRelationListingDetail] {
        MatchRelationComposer.buildRelationDetails(
            ownListings: ownListings,
            partnerListings: partnerListings,
            senderGoods: senderGoods,
            partnerGoods: partnerGoods,
            highlightedItemID: currentTargetItem.id
        )
    }

    private var aggregate: MatchRelationAggregate {
        MatchRelationComposer.aggregateSelection(
            details: relationDetails,
            selectedCandidateIDsByListingID: selectionState.selectedCandidateIDsByListingID,
            selectedHaveIDsByListingID: selectionState.selectedHaveIDsByListingID
        )
    }

    private var simpleReceiverIDs: [UUID] {
        [currentTargetItem.id]
    }

    private var simpleSenderIDs: [UUID] {
        MatchRelationComposer.fallbackSenderIDs(for: currentTargetItem, inventory: senderGoods)
    }

    private var isLoading: Bool {
        appState.loadingPublicExchangeUserID == currentTargetItem.ownerID
            || appState.loadingPublicProfileUserID == currentTargetItem.ownerID
            || appState.isLoadingIndividualListings
    }

    private var canStartRelationProposal: Bool {
        !aggregate.isEmpty
    }

    private var canStartSimpleProposal: Bool {
        relationDetails.isEmpty && !simpleSenderIDs.isEmpty && !simpleReceiverIDs.isEmpty
    }

    private var relationSeedKey: String {
        [
            currentTargetItem.id.uuidString,
            senderGoods.map(\.id.uuidString).joined(separator: ","),
            partnerGoods.map(\.id.uuidString).joined(separator: ","),
            relationDetails.map(\.id.uuidString).joined(separator: ",")
        ]
        .joined(separator: "|")
    }

    private var swipeItems: [GoodsItem] {
        MatchRelationComposer.relationSwipeItems(
            homeMatchedItems: appState.homeMatchedItems,
            currentTarget: currentTargetItem
        )
    }

    private var previousSwipeTarget: GoodsItem? {
        MatchRelationComposer.adjacentSwipeTarget(
            in: swipeItems,
            currentID: currentTargetItem.id,
            direction: .previous
        )
    }

    private var nextSwipeTarget: GoodsItem? {
        MatchRelationComposer.adjacentSwipeTarget(
            in: swipeItems,
            currentID: currentTargetItem.id,
            direction: .next
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                MatchRelationContent(
                    isLoading: isLoading,
                    ownDetails: ownDetails,
                    partnerDetails: partnerDetails,
                    partnerHandle: partnerHandle,
                    highlightedItemID: currentTargetItem.id,
                    selectedCandidateIDsByListingID: selectionState.selectedCandidateIDsByListingID,
                    selectedHaveIDsByListingID: selectionState.selectedHaveIDsByListingID,
                    targetItem: currentTargetItem,
                    simpleSenderItems: simpleSenderIDs.compactMap { id in senderGoods.first { $0.id == id } },
                    showsSummary: canStartRelationProposal,
                    summarySenderItems: aggregate.senderItems,
                    summaryReceiverItems: aggregate.receiverItems,
                    onToggleHave: { listingID, haveID in
                        toggleHave(listingID: listingID, haveID: haveID)
                    },
                    onOpenPopup: { target in
                        popupTarget = target
                    }
                )
                .offset(x: relationSwipeOffset)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(relationSwipeGesture(screenWidth: geometry.size.width))
        }
        .background(MatchRelationVisual.background.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .safeAreaInset(edge: .top, spacing: 0) {
            MatchRelationHeader(
                onClose: { dismiss() }
            )
        }
        .safeAreaInset(edge: .bottom) {
            MatchRelationBottomBar(
                senderCount: currentSenderCount,
                receiverCount: currentReceiverCount,
                isEnabled: canStartRelationProposal || canStartSimpleProposal,
                showsReset: canStartRelationProposal,
                onSecondary: {
                    if canStartRelationProposal {
                        resetRelationSelection()
                    } else {
                        dismiss()
                    }
                },
                onStart: startProposal
            )
        }
        .task(id: currentTargetItem.ownerID) {
            await appState.loadPublicUserProfile(userID: currentTargetItem.ownerID)
            await appState.loadPublicExchangeContent(userID: currentTargetItem.ownerID)
            await appState.loadIndividualListings()
            seedInitialSelection(force: true)
        }
        .task(id: relationSeedKey) {
            seedInitialSelection(force: true)
        }
        .onChange(of: currentTargetItem.id) { _, _ in
            proposalTarget = nil
            popupTarget = nil
            didApplyVisualQACandidateExpansion = false
            seedInitialSelection(force: true)
        }
        .overlay {
            if let target = popupTarget {
                MatchRelationWishBottomSheet(
                    target: target,
                    partnerHandle: partnerHandle,
                    highlightedItemID: currentTargetItem.id,
                    selectedCandidateIDs: selectionState.selectedCandidateIDsByListingID[target.listingID] ?? [],
                    onToggleCandidate: { candidateID in
                        toggleCandidate(listingID: target.listingID, candidateID: candidateID)
                    },
                    onClose: {
                        popupTarget = nil
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(4)
            }
        }
        .relationProposalPresentation(item: $proposalTarget) { target in
            NavigationStack {
                ProposalCreateFlow(
                    appState: appState,
                    targetItem: target.targetItem,
                    listingID: target.listingID,
                    receiverGoodsIDs: target.receiverGoodsIDs,
                    initialSenderGoodsIDs: target.senderGoodsIDs,
                    matchType: target.matchType,
                    initialStep: .meetup,
                    onCompletionAction: { action in
                        proposalTarget = nil
                        dismiss()
                        onCompletionAction(action)
                    }
                )
            }
        }
    }

    private var ownDetails: [MatchRelationListingDetail] {
        relationDetails.filter(\.isMyListing)
    }

    private var partnerDetails: [MatchRelationListingDetail] {
        relationDetails.filter { !$0.isMyListing }
    }

    private var currentSenderCount: Int {
        canStartRelationProposal ? aggregate.senderIDs.count : simpleSenderIDs.count
    }

    private var currentReceiverCount: Int {
        canStartRelationProposal ? aggregate.receiverIDs.count : simpleReceiverIDs.count
    }

    private func seedInitialSelection(force: Bool) {
        let details = relationDetails
        selectionState = MatchRelationSelectionStateReducer.seedingInitialSelection(
            in: selectionState,
            details: details,
            highlightedItemID: currentTargetItem.id,
            force: force
        )
        applyVisualQACandidateExpansionIfNeeded(details: details)
    }

    private func applyVisualQACandidateExpansionIfNeeded(details: [MatchRelationListingDetail]) {
        guard visualQAInitialScreen == .matchRelationCandidates,
              !didApplyVisualQACandidateExpansion,
              let target = MatchRelationComposer.defaultPopupTarget(
                for: details,
                highlightedItemID: currentTargetItem.id
              )
        else {
            return
        }
        didApplyVisualQACandidateExpansion = true
        popupTarget = target
    }

    private func resetRelationSelection() {
        selectionState = MatchRelationSelectionStateReducer.resettingCandidates(in: selectionState)
        popupTarget = nil
    }

    private func toggleCandidate(listingID: UUID, candidateID: UUID) {
        selectionState = MatchRelationSelectionStateReducer.togglingCandidate(
            listingID: listingID,
            candidateID: candidateID,
            in: selectionState
        )
    }

    private func toggleHave(listingID: UUID, haveID: UUID) {
        selectionState = MatchRelationSelectionStateReducer.togglingHave(
            listingID: listingID,
            haveID: haveID,
            in: selectionState
        )
    }

    private func startProposal() {
        if canStartRelationProposal {
            let listingID = aggregate.referencedListingIDs.count == 1 ? aggregate.referencedListingIDs.first : nil
            let target = aggregate.receiverItems.first ?? currentTargetItem
            proposalTarget = MatchRelationProposalTarget(
                targetItem: target,
                listingID: listingID,
                receiverGoodsIDs: aggregate.receiverIDs,
                senderGoodsIDs: aggregate.senderIDs,
                matchType: matchType
            )
            return
        }

        guard canStartSimpleProposal else {
            return
        }
        proposalTarget = MatchRelationProposalTarget(
            targetItem: currentTargetItem,
            listingID: nil,
            receiverGoodsIDs: simpleReceiverIDs,
            senderGoodsIDs: simpleSenderIDs,
            matchType: matchType
        )
    }

    private func relationSwipeGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard let direction = MatchRelationSwipeResolver.direction(for: value.translation) else {
                    return
                }
                let hasTarget = direction == .next ? nextSwipeTarget != nil : previousSwipeTarget != nil
                guard let offset = MatchRelationSwipeResolver.presentationOffset(
                    translation: value.translation,
                    screenWidth: screenWidth,
                    hasAdjacentTarget: hasTarget
                ) else {
                    return
                }
                relationSwipeOffset = offset
            }
            .onEnded { value in
                guard let direction = MatchRelationSwipeResolver.direction(for: value.translation) else {
                    withAnimation(.snappy) {
                        relationSwipeOffset = 0
                    }
                    return
                }

                let target = direction == .next ? nextSwipeTarget : previousSwipeTarget
                let shouldSwitch = MatchRelationSwipeResolver.shouldSwitchTarget(
                    translation: value.translation,
                    predictedEndTranslationWidth: value.predictedEndTranslation.width,
                    screenWidth: screenWidth,
                    hasAdjacentTarget: target != nil
                )

                if let target, shouldSwitch {
                    withAnimation(.snappy) {
                        currentTargetItem = target
                        relationSwipeOffset = 0
                    }
                } else {
                    withAnimation(.snappy) {
                        relationSwipeOffset = 0
                    }
                }
            }
    }
}

private extension View {
    @ViewBuilder
    func relationProposalPresentation<Content: View>(
        item: Binding<MatchRelationProposalTarget?>,
        @ViewBuilder content: @escaping (MatchRelationProposalTarget) -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, content: content)
        #else
        sheet(item: item, content: content)
        #endif
    }
}
