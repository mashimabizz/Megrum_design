import Foundation
import MegrumCore

enum TradeEvaluationAttentionPolicy {
    static func needsViewerEvaluation(
        proposal: TradeProposal,
        viewerID: UUID?,
        messages: [TradeMessage],
        localSubmission: Bool = false
    ) -> Bool {
        guard
            let viewerID,
            proposal.isParticipant(viewerID),
            isSettledCompletedTrade(proposal)
        else {
            return false
        }

        let state = TradeEvaluationPromptState(
            proposal: proposal,
            viewerID: viewerID,
            messages: messages,
            localSubmission: localSubmission
        )
        return !state.hasSubmittedEvaluation
    }

    static func isSettledCompletedTrade(_ proposal: TradeProposal) -> Bool {
        proposal.status == .completed
            && proposal.agreedBySender
            && proposal.agreedByReceiver
            && proposal.approvedBySender
            && proposal.approvedByReceiver
            && proposal.completedAt != nil
    }
}
