import MegrumCore
import MegrumDesign
import SwiftUI

struct MatchRelationScreen: View {
    @ObservedObject var appState: MegrumAppState
    var targetItem: GoodsItem
    var matchType: ProposalMatchType = .perfect
    var onCompletionAction: (ProposalCompletionAction) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State var currentTargetItem: GoodsItem
    @State var selectionState = MatchRelationSelectionState()
    @State var popupTarget: MatchRelationWishPopupTarget?
    @State var proposalTarget: MatchRelationProposalTarget?
    @State var relationSwipeOffset: CGFloat = 0
    @State var didApplyVisualQACandidateExpansion = false
    let visualQAInitialScreen: VisualQAInitialScreen?

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
