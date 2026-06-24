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

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedStage) {
                ForEach(TradeStage.allCases) { stage in
                    tradeStagePage(stage)
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

    private func tradeStagePage(_ stage: TradeStage) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                let stageProposals = visibleProposals(for: stage)
                if stageProposals.isEmpty {
                    EmptyTradeStage(stage: stage)
                        .padding(.top, 8)
                } else {
                    ForEach(stageProposals) { proposal in
                        let canWithdraw = canWithdrawPendingProposal(proposal, in: stage)
                        TradeCard(
                            proposal: proposal,
                            viewerID: appState.viewer?.id,
                            profilesByUserID: appState.publicProfilesByUserID,
                            goodsByID: goodsByID,
                            lastActivityAt: TradeListOrdering.lastActivityAt(
                                for: proposal,
                                messagesByProposalID: appState.messagesByProposalID
                            ),
                            viewerLastReadAt: appState.viewerReadAtByProposalID[proposal.id],
                            isSelectionMode: isSelectingPendingProposals && stage == .pending,
                            isSelected: selectedPendingProposalIDs.contains(proposal.id),
                            isSelectionEnabled: canWithdraw,
                            onLongPress: {
                                guard canWithdraw else {
                                    return
                                }
                                withAnimation(.snappy(duration: 0.22)) {
                                    _ = selectedPendingProposalIDs.insert(proposal.id)
                                }
                            }
                        ) {
                            if isSelectingPendingProposals && stage == .pending {
                                togglePendingProposalSelection(proposal)
                            } else {
                                openProposal(proposal)
                            }
                        }
                    }
                    if stage == .completed {
                        AdBannerSlot(
                            placement: .pastTradesFooterBanner,
                            displayContext: adDisplayContext
                        )
                        .padding(.top, 12)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 132)
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
        if isSelectingPendingProposals {
            Button {
                withdrawSelectedPendingProposals()
            } label: {
                Label("打診を取り下げる", systemImage: "arrow.uturn.backward")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(MegrumTheme.lavender, in: Capsule())
                    .shadow(color: MegrumTheme.lavender.opacity(0.30), radius: 18, y: 10)
            }
            .buttonStyle(.plain)
            .disabled(selectedPendingProposalIDs.isEmpty || appState.respondingProposalID != nil)
            .accessibilityLabel("選択した\(selectedPendingProposalIDs.count)件の打診を取り下げる")
        } else {
            TradeStageBar(
                selectedStage: $selectedStage,
                pendingCount: proposals.filter { TradeStage.pending.contains($0.status) }.count,
                inProgressCount: proposals.filter { TradeStage.inProgress.contains($0.status) }.count,
                completedCount: proposals.filter { TradeStage.completed.contains($0.status) }.count
            )
        }
    }

    private var selectedStageSubtitle: String {
        "\(selectedStage.subtitle) ・ \(visibleProposals.count)件"
    }

    private var partnerProfileTaskKey: String {
        visiblePartnerIDs
            .map(\.uuidString)
            .sorted()
            .joined(separator: ",")
    }

    private var visiblePartnerIDs: [UUID] {
        guard let viewerID = appState.viewer?.id else {
            return []
        }
        var seen: Set<UUID> = []
        return visibleProposals.compactMap { proposal in
            guard let partnerID = proposal.partnerID(for: viewerID), !seen.contains(partnerID) else {
                return nil
            }
            seen.insert(partnerID)
            return partnerID
        }
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
        guard (stage ?? selectedStage) == .pending, proposal.senderID == appState.viewer?.id else {
            return false
        }
        return [.sent, .negotiating, .agreementOneSide].contains(proposal.status)
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
