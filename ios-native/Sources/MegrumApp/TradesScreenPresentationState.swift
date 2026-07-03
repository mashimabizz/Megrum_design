import Foundation
import MegrumCore

struct TradesScreenPresentationState {
    var selectedStage: TradeStage = .pending
    var selectedPendingProposalIDs: Set<UUID> = []
    var activeDetailListSnapshot: TradeListDisplaySnapshot?
    var settledDetailProposalID: UUID?

    var isSelectingPendingProposals: Bool {
        selectedStage == .pending && !selectedPendingProposalIDs.isEmpty
    }

    func proposals(fallback: [TradeProposal]) -> [TradeProposal] {
        activeDetailListSnapshot?.proposals ?? fallback
    }

    func messagesByProposalID(fallback: [UUID: [TradeMessage]]) -> [UUID: [TradeMessage]] {
        activeDetailListSnapshot?.messagesByProposalID ?? fallback
    }

    func viewerReadAtByProposalID(fallback: [UUID: Date]) -> [UUID: Date] {
        activeDetailListSnapshot?.viewerReadAtByProposalID ?? fallback
    }

    mutating func consumeRequestedStage(_ requestedStage: TradeStage?) -> Bool {
        guard let requestedStage else {
            return false
        }
        selectedStage = TradeStageRouteRequestResolver.resolve(
            current: selectedStage,
            requested: requestedStage
        )
        return true
    }

    mutating func clearPendingSelection() {
        selectedPendingProposalIDs.removeAll()
    }

    mutating func prepareToOpenDetail(snapshot: TradeListDisplaySnapshot) {
        settledDetailProposalID = nil
        activeDetailListSnapshot = snapshot
    }

    mutating func markDetailRouteDismissed() {
        settledDetailProposalID = nil
    }

    mutating func prepareDetailSettlement() {
        settledDetailProposalID = nil
    }

    mutating func markDetailSettled(proposalID: UUID) {
        settledDetailProposalID = proposalID
    }

    func shouldSynchronizeActiveDetailListSnapshot(detailRoute: TradeDetailRoute?) -> Bool {
        guard activeDetailListSnapshot != nil else {
            return false
        }
        guard let detailRoute else {
            return true
        }
        return settledDetailProposalID == detailRoute.proposalID
    }

    mutating func clearActiveDetailListSnapshot() {
        activeDetailListSnapshot = nil
    }

    mutating func togglePendingProposalSelection(proposalID: UUID) {
        if selectedPendingProposalIDs.contains(proposalID) {
            selectedPendingProposalIDs.remove(proposalID)
        } else {
            selectedPendingProposalIDs.insert(proposalID)
        }
    }

    mutating func startPendingProposalSelection(proposalID: UUID) {
        selectedPendingProposalIDs.insert(proposalID)
    }
}
