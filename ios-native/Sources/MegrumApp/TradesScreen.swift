import MegrumCore
import MegrumDesign
import Foundation
import PhotosUI
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct TradesScreen: View {
    @ObservedObject var appState: MegrumAppState
    @Binding var requestedStage: TradeStage?
    var adDisplayContext: AdDisplayContext = AdDisplayContext()

    @State private var selectedStage: TradeStage = .pending
    @State private var detailRoute: TradeDetailRoute?
    @State private var selectedPendingProposalIDs: Set<UUID> = []

    private var proposals: [TradeProposal] {
        appState.proposals
    }

    private var visibleProposals: [TradeProposal] {
        visibleProposals(for: selectedStage)
    }

    private func visibleProposals(for stage: TradeStage) -> [TradeProposal] {
        TradeListOrdering.sorted(
            proposals.filter { stage.contains($0.status) },
            viewerID: appState.viewer?.id,
            messagesByProposalID: appState.messagesByProposalID,
            viewerReadAtByProposalID: appState.viewerReadAtByProposalID
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
                        messagesByProposalID: appState.messagesByProposalID,
                        viewerReadAtByProposalID: appState.viewerReadAtByProposalID,
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
        .tradeDetailPresentation(item: $detailRoute) { route in
            tradeDetailView(for: route)
        }
        .onAppear {
            consumeRequestedStage()
        }
        .onChange(of: requestedStage) { _, _ in
            consumeRequestedStage()
        }
        .onChange(of: selectedStage) { _, _ in
            selectedPendingProposalIDs.removeAll()
        }
        .task(id: partnerProfileTaskKey) {
            for userID in visiblePartnerIDs where appState.publicProfilesByUserID[userID] == nil {
                await appState.loadPublicUserProfile(userID: userID)
            }
        }
    }

    @ViewBuilder
    private func tradeDetailView(for route: TradeDetailRoute) -> some View {
        NavigationStack {
            if let proposal = proposals.first(where: { $0.id == route.proposalID }) {
                TradeDetailScreen(appState: appState, proposal: proposal)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                detailRoute = nil
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .heavy))
                            }
                            .accessibilityLabel("やりとり一覧に戻る")
                        }
                    }
            } else {
                TradeDetailUnavailableScreen()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("閉じる") {
                                detailRoute = nil
                            }
                        }
                    }
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
        detailRoute = TradeDetailRoute(proposalID: proposal.id)
        Task {
            await appState.markProposalRead(proposalID: proposal.id)
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

private extension View {
    @ViewBuilder
    func tradeDetailPresentation<Content: View>(
        item: Binding<TradeDetailRoute?>,
        @ViewBuilder content: @escaping (TradeDetailRoute) -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, content: content)
        #else
        sheet(item: item, content: content)
        #endif
    }
}
