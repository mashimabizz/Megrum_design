import MegrumCore
import MegrumDesign
import SwiftUI

enum TradesFooterLayoutMetrics {
    static let bottomPadding: CGFloat = 22
}

struct TradesScreen: View {
    @ObservedObject var appState: MegrumAppState
    @Binding var requestedStage: TradeStage?
    @Binding var detailRoute: TradeDetailRoute?
    var adDisplayContext: AdDisplayContext = AdDisplayContext()

    @State private var presentationState = TradesScreenPresentationState()

    private var proposals: [TradeProposal] {
        // ガイドツアー中で実データが空の時はサンプル打診を表示する（実データ不変）。
        let fallback = appState.isTutorialActive && appState.proposals.isEmpty
            ? NativePreviewData.proposals
            : appState.proposals
        return presentationState.proposals(fallback: fallback)
    }

    /// ガイドツアー中は広告を出さない（説明の主役である実画面を隠さない）。
    private var effectiveAdDisplayContext: AdDisplayContext {
        if appState.isTutorialActive {
            return AdDisplayContext(viewerID: appState.viewer?.id, isPremiumSubscriber: true)
        }
        return adDisplayContext
    }

    private var messagesByProposalID: [UUID: [TradeMessage]] {
        presentationState.messagesByProposalID(fallback: appState.messagesByProposalID)
    }

    private var viewerReadAtByProposalID: [UUID: Date] {
        presentationState.viewerReadAtByProposalID(fallback: appState.viewerReadAtByProposalID)
    }

    private var visibleProposals: [TradeProposal] {
        visibleProposals(for: presentationState.selectedStage)
    }

    private func visibleProposals(for stage: TradeStage) -> [TradeProposal] {
        TradeListOrdering.sorted(
            proposals.filter { stage.containsForDisplay($0) },
            viewerID: appState.viewer?.id,
            messagesByProposalID: messagesByProposalID,
            viewerReadAtByProposalID: viewerReadAtByProposalID,
            evaluatedProposalIDs: appState.viewerEvaluatedProposalIDs
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
        presentationState.isSelectingPendingProposals
    }

    private var attentionCounts: TradeStageAttentionCounts {
        TradeStageAttentionCounts(
            proposals: proposals,
            messagesByProposalID: messagesByProposalID,
            viewerReadAtByProposalID: viewerReadAtByProposalID,
            viewerID: appState.viewer?.id,
            evaluatedProposalIDs: appState.viewerEvaluatedProposalIDs
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                // 広告はタブ横断・スクロールしても固定のヘッダーとして表示する。
                AdBannerSlot(
                    placement: .tradesListTopBanner,
                    displayContext: effectiveAdDisplayContext,
                    bottomSpacing: 6
                )
                .padding(.horizontal, 20)
                .padding(.top, 4)

                TabView(selection: $presentationState.selectedStage) {
                    ForEach(TradeStage.allCases) { stage in
                        TradeStagePage(
                            stage: stage,
                            proposals: visibleProposals(for: stage),
                            viewerID: appState.viewer?.id,
                            profilesByUserID: appState.publicProfilesByUserID,
                            goodsByID: goodsByID,
                            messagesByProposalID: messagesByProposalID,
                            viewerReadAtByProposalID: viewerReadAtByProposalID,
                            evaluatedProposalIDs: appState.viewerEvaluatedProposalIDs,
                            isSelectingPendingProposals: isSelectingPendingProposals,
                            selectedPendingProposalIDs: presentationState.selectedPendingProposalIDs,
                            adDisplayContext: effectiveAdDisplayContext,
                            topContentInset: 0,
                            canWithdraw: { canWithdrawPendingProposal($0, in: stage) },
                            onStartSelection: startPendingProposalSelection,
                            onToggleSelection: togglePendingProposalSelection,
                            onOpen: openProposal
                        )
                            .tag(stage)
                    }
                }
                .megrumPageTabViewStyle()
                .megrumHiddenBottomScrollEdgeEffect()
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .ignoresSafeArea(.container, edges: .bottom)
                }

                tradeFooter
                    .padding(.horizontal, 20)
                    .padding(.bottom, TradesFooterLayoutMetrics.bottomPadding)
            }
            .overlay(alignment: .top) {
                MegrumStatusBarProgressiveBlur(topSafeAreaInset: proxy.safeAreaInsets.top)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .onAppear {
            consumeRequestedStage()
        }
        .onChange(of: requestedStage) { _, _ in
            consumeRequestedStage()
        }
        .onChange(of: presentationState.selectedStage) { _, _ in
            presentationState.clearPendingSelection()
        }
        .onChange(of: detailRoute) { _, newValue in
            if newValue == nil {
                presentationState.markDetailRouteDismissed()
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
            selectedStage: $presentationState.selectedStage,
            isSelectingPendingProposals: isSelectingPendingProposals,
            selectedPendingCount: presentationState.selectedPendingProposalIDs.count,
            isResponding: appState.respondingProposalID != nil,
            pendingBadgeCount: attentionCounts.pendingNeedsResponse,
            inProgressBadgeCount: attentionCounts.inProgressUnread,
            completedBadgeCount: attentionCounts.completedNeedsEvaluation,
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
        if presentationState.consumeRequestedStage(requestedStage) {
            self.requestedStage = nil
        }
    }

    private func canWithdrawPendingProposal(_ proposal: TradeProposal, in stage: TradeStage? = nil) -> Bool {
        TradePendingWithdrawalPolicy.canWithdraw(
            proposal,
            stage: stage ?? presentationState.selectedStage,
            viewerID: appState.viewer?.id
        )
    }

    private func openProposal(_ proposal: TradeProposal) {
        presentationState.prepareToOpenDetail(
            snapshot: TradeListDisplaySnapshot.current(
                proposals: appState.proposals,
                messagesByProposalID: appState.messagesByProposalID,
                viewerReadAtByProposalID: appState.viewerReadAtByProposalID
            )
        )
        withAnimation(TradeDetailSlidePresentationMetrics.animation) {
            detailRoute = TradeDetailRoute(proposalID: proposal.id)
        }
    }

    private func scheduleActiveDetailListSnapshotSynchronization(for proposalID: UUID) {
        presentationState.prepareDetailSettlement()
        Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: TradeDetailSlidePresentationMetrics.presentationSettledDelayNanoseconds)
            } catch {
                return
            }
            guard detailRoute?.proposalID == proposalID else {
                return
            }
            presentationState.markDetailSettled(proposalID: proposalID)
            synchronizeActiveDetailListSnapshot()
        }
    }

    private func synchronizeActiveDetailListSnapshot() {
        guard presentationState.shouldSynchronizeActiveDetailListSnapshot(detailRoute: detailRoute) else {
            return
        }
        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            presentationState.activeDetailListSnapshot = TradeListDisplaySnapshot.current(
                proposals: appState.proposals,
                messagesByProposalID: appState.messagesByProposalID,
                viewerReadAtByProposalID: appState.viewerReadAtByProposalID
            )
        }
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
                presentationState.clearActiveDetailListSnapshot()
            }
        }
    }

    private func togglePendingProposalSelection(_ proposal: TradeProposal) {
        guard canWithdrawPendingProposal(proposal) else {
            return
        }
        withAnimation(.snappy(duration: 0.2)) {
            presentationState.togglePendingProposalSelection(proposalID: proposal.id)
        }
    }

    private func startPendingProposalSelection(_ proposal: TradeProposal) {
        guard canWithdrawPendingProposal(proposal) else {
            return
        }
        withAnimation(.snappy(duration: 0.22)) {
            presentationState.startPendingProposalSelection(proposalID: proposal.id)
        }
    }

    private func withdrawSelectedPendingProposals() {
        let proposalIDs = Array(presentationState.selectedPendingProposalIDs)
        guard !proposalIDs.isEmpty else {
            return
        }
        Task {
            for proposalID in proposalIDs {
                _ = await appState.withdrawProposal(proposalID: proposalID)
            }
            presentationState.clearPendingSelection()
        }
    }
}
