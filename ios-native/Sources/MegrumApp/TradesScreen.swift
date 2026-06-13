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

    @State private var selectedStage: TradeStage = .pending
    @State private var detailRoute: TradeDetailRoute?

    private var proposals: [TradeProposal] {
        appState.proposals
    }

    private var visibleProposals: [TradeProposal] {
        proposals
            .filter { selectedStage.contains($0.status) }
            .sorted(by: compareForRnPendingList)
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if visibleProposals.isEmpty {
                    EmptyTradeStage(stage: selectedStage)
                } else {
                    ForEach(visibleProposals) { proposal in
                        TradeCard(
                            proposal: proposal,
                            viewerID: appState.viewer?.id,
                            profilesByUserID: appState.publicProfilesByUserID,
                            goodsByID: goodsByID
                        ) {
                            detailRoute = TradeDetailRoute(proposalID: proposal.id)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 132)
        }
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .safeAreaInset(edge: .bottom) {
            TradeStageBar(
                selectedStage: $selectedStage,
                pendingCount: proposals.filter { TradeStage.pending.contains($0.status) }.count,
                inProgressCount: proposals.filter { TradeStage.inProgress.contains($0.status) }.count,
                completedCount: proposals.filter { TradeStage.completed.contains($0.status) }.count
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
        .navigationDestination(item: $detailRoute) { route in
            if let proposal = proposals.first(where: { $0.id == route.proposalID }) {
                TradeDetailScreen(appState: appState, proposal: proposal)
            } else {
                TradeDetailUnavailableScreen()
            }
        }
        .onAppear {
            consumeRequestedStage()
        }
        .onChange(of: requestedStage) { _, _ in
            consumeRequestedStage()
        }
        .task(id: partnerProfileTaskKey) {
            for userID in visiblePartnerIDs where appState.publicProfilesByUserID[userID] == nil {
                await appState.loadPublicUserProfile(userID: userID)
            }
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

    private func compareForRnPendingList(_ lhs: TradeProposal, _ rhs: TradeProposal) -> Bool {
        let lhsPriority = rnPendingPriority(for: lhs)
        let rhsPriority = rnPendingPriority(for: rhs)
        if lhsPriority != rhsPriority {
            return lhsPriority < rhsPriority
        }
        return lhs.createdAt > rhs.createdAt
    }

    private func rnPendingPriority(for proposal: TradeProposal) -> Int {
        switch proposal.status {
        case .negotiating:
            return 0
        case .agreementOneSide:
            return 1
        case .sent:
            return proposal.senderID == appState.viewer?.id ? 2 : 3
        case .agreed:
            return 4
        case .completed:
            return 5
        case .cancelled, .rejected, .expired:
            return 6
        case .draft:
            return 7
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
}
