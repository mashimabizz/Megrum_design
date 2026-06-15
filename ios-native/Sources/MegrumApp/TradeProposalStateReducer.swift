import MegrumCore

public enum TradeProposalStateReducer {
    public static func prependingCreatedProposal(
        _ proposal: TradeProposal,
        to proposals: [TradeProposal]
    ) -> [TradeProposal] {
        [proposal] + proposals
    }

    public static func replacingOrPrepending(
        _ proposal: TradeProposal,
        in proposals: [TradeProposal]
    ) -> [TradeProposal] {
        var next = proposals
        if let index = next.firstIndex(where: { $0.id == proposal.id }) {
            next[index] = proposal
        } else {
            next.insert(proposal, at: 0)
        }
        return next
    }
}
