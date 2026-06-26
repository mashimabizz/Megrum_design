import MegrumCore
import MegrumDesign
import SwiftUI

struct TradesScreen: View {
    @ObservedObject var appState: MegrumAppState
    @Binding var requestedStage: TradeStage?
    @Binding var detailRoute: TradeDetailRoute?
    var adDisplayContext: AdDisplayContext = AdDisplayContext()

    @State private var selectedStage: TradeStage = .pending
    @State private var selectedPendingProposalIDs: Set<UUID> = []
    @State private var activeDetailListSnapshot: TradeListDisplaySnapshot?
    @State private var settledDetailProposalID: UUID?

    private var proposals: [TradeProposal] {
        activeDetailListSnapshot?.proposals ?? appState.proposals
    }

    private var messagesByProposalID: [UUID: [TradeMessage]] {
        activeDetailListSnapshot?.messagesByProposalID ?? appState.messagesByProposalID
    }

    private var viewerReadAtByProposalID: [UUID: Date] {
        activeDetailListSnapshot?.viewerReadAtByProposalID ?? appState.viewerReadAtByProposalID
    }

    private var visibleProposals: [TradeProposal] {
        visibleProposals(for: selectedStage)
    }

    private func visibleProposals(for stage: TradeStage) -> [TradeProposal] {
        TradeListOrdering.sorted(
            proposals.filter { stage.contains($0.status) },
            viewerID: appState.viewer?.id,
            messagesByProposalID: messagesByProposalID,
            viewerReadAtByProposalID: viewerReadAtByProposalID
        )
    }

    private var goodsByID: [UUID: GoodsItem] {
        TradeGoodsLookup.build(
            inventory: appState.inventory,
            homeMatchedItems: appState.homeMatchedItems,
            homePossibleItems: appState.homePossibleItems,
            wishes: appState.wishes,
            publicTradeGoodsByUserID: appState.publicTradeGoodsByUserID
        )
    }

    private var isSelectingPendingProposals: Bool {
        selectedStage == .pending && !selectedPendingProposalIDs.isEmpty
    }

    private var stageCounts: TradeStageCounts {
        TradeStageCounts(proposals: proposals)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedStage) {
                ForEach(TradeStage.allCases) { stage in
                    TradeStagePage(
                        stage: stage,
                        proposals: visibleProposals(for: stage),
                        viewerID: appState.viewer?.id,
                        profilesByUserID: appState.publicProfilesByUserID,
                        goodsByID: goodsByID,
                        messagesByProposalID: messagesByProposalID,
                        viewerReadAtByProposalID: viewerReadAtByProposalID,
                        isSelectingPendingProposals: isSelectingPendingProposals,
                        selectedPendingProposalIDs: selectedPendingProposalIDs,
                        adDisplayContext: adDisplayContext,
                        canWithdraw: { canWithdrawPendingProposal($0, in: stage) },
                        onStartSelection: startPendingProposalSelection,
                        onToggleSelection: togglePendingProposalSelection,
                        onOpen: openProposal
                    )
                        .tag(stage)
                }
            }
            .megrumPageTabViewStyle()
            .ignoresSafeArea(.keyboard, edges: .bottom)

            tradeFooter
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .onAppear {
            consumeRequestedStage()
        }
        .onChange(of: requestedStage) { _, _ in
            consumeRequestedStage()
        }
        .onChange(of: selectedStage) { _, _ in
            selectedPendingProposalIDs.removeAll()
        }
        .onChange(of: detailRoute) { _, newValue in
            if newValue == nil {
                settledDetailProposalID = nil
                synchronizeActiveDetailListSnapshot()
                clearActiveDetailListSnapshotAfterDismiss()
            } else if let newValue {
                scheduleActiveDetailListSnapshotSynchronization(for: newValue.proposalID)
            }
        }
        .onChange(of: appState.proposals) { _, _ in
            synchronizeActiveDetailListSnapshot()
        }
        .onChange(of: appState.messagesByProposalID) { _, _ in
            synchronizeActiveDetailListSnapshot()
        }
        .onChange(of: appState.viewerReadAtByProposalID) { _, _ in
            synchronizeActiveDetailListSnapshot()
        }
        .task(id: partnerProfileTaskKey) {
            for userID in visiblePartnerIDs where appState.publicProfilesByUserID[userID] == nil {
                await appState.loadPublicUserProfile(userID: userID)
            }
        }
    }

    @ViewBuilder
    private var tradeFooter: some View {
        TradesFooter(
            selectedStage: $selectedStage,
            isSelectingPendingProposals: isSelectingPendingProposals,
            selectedPendingCount: selectedPendingProposalIDs.count,
            isResponding: appState.respondingProposalID != nil,
            pendingCount: stageCounts.pending,
            inProgressCount: stageCounts.inProgress,
            completedCount: stageCounts.completed,
            onWithdrawSelected: withdrawSelectedPendingProposals
        )
    }

    private var partnerProfileTaskKey: String {
        TradesVisiblePartnerProfiles.taskKey(for: visiblePartnerIDs)
    }

    private var visiblePartnerIDs: [UUID] {
        TradesVisiblePartnerProfiles.partnerIDs(
            in: visibleProposals,
            viewerID: appState.viewer?.id
        )
    }

    private func consumeRequestedStage() {
        guard let requestedStage else {
            return
        }
        selectedStage = TradeStageRouteRequestResolver.resolve(
            current: selectedStage,
            requested: requestedStage
        )
        self.requestedStage = nil
    }

    private func canWithdrawPendingProposal(_ proposal: TradeProposal, in stage: TradeStage? = nil) -> Bool {
        TradePendingWithdrawalPolicy.canWithdraw(
            proposal,
            stage: stage ?? selectedStage,
            viewerID: appState.viewer?.id
        )
    }

    private func openProposal(_ proposal: TradeProposal) {
        settledDetailProposalID = nil
        activeDetailListSnapshot = TradeListDisplaySnapshot.current(
            proposals: appState.proposals,
            messagesByProposalID: appState.messagesByProposalID,
            viewerReadAtByProposalID: appState.viewerReadAtByProposalID
        )
        withAnimation(TradeDetailSlidePresentationMetrics.animation) {
            detailRoute = TradeDetailRoute(proposalID: proposal.id)
        }
    }

    private func scheduleActiveDetailListSnapshotSynchronization(for proposalID: UUID) {
        settledDetailProposalID = nil
        Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: TradeDetailSlidePresentationMetrics.presentationSettledDelayNanoseconds)
            } catch {
                return
            }
            guard detailRoute?.proposalID == proposalID else {
                return
            }
            settledDetailProposalID = proposalID
            synchronizeActiveDetailListSnapshot()
        }
    }

    private func synchronizeActiveDetailListSnapshot() {
        guard activeDetailListSnapshot != nil, canSynchronizeActiveDetailListSnapshot else {
            return
        }
        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            activeDetailListSnapshot = TradeListDisplaySnapshot.current(
                proposals: appState.proposals,
                messagesByProposalID: appState.messagesByProposalID,
                viewerReadAtByProposalID: appState.viewerReadAtByProposalID
            )
        }
    }

    private var canSynchronizeActiveDetailListSnapshot: Bool {
        guard let detailRoute else {
            return true
        }
        return settledDetailProposalID == detailRoute.proposalID
    }

    private func clearActiveDetailListSnapshotAfterDismiss() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 380_000_000)
            guard detailRoute == nil else {
                return
            }
            var transaction = Transaction()
            transaction.animation = nil
            withTransaction(transaction) {
                activeDetailListSnapshot = nil
            }
        }
    }

    private func togglePendingProposalSelection(_ proposal: TradeProposal) {
        guard canWithdrawPendingProposal(proposal) else {
            return
        }
        withAnimation(.snappy(duration: 0.2)) {
            if selectedPendingProposalIDs.contains(proposal.id) {
                selectedPendingProposalIDs.remove(proposal.id)
            } else {
                selectedPendingProposalIDs.insert(proposal.id)
            }
        }
    }

    private func startPendingProposalSelection(_ proposal: TradeProposal) {
        guard canWithdrawPendingProposal(proposal) else {
            return
        }
        withAnimation(.snappy(duration: 0.22)) {
            _ = selectedPendingProposalIDs.insert(proposal.id)
        }
    }

    private func withdrawSelectedPendingProposals() {
        let proposalIDs = Array(selectedPendingProposalIDs)
        guard !proposalIDs.isEmpty else {
            return
        }
        Task {
            for proposalID in proposalIDs {
                _ = await appState.rejectProposal(proposalID: proposalID)
            }
            selectedPendingProposalIDs.removeAll()
        }
    }
}
