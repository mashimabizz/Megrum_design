import Foundation
import MegrumCore

extension MegrumAppState {
    func replaceProposal(_ proposal: TradeProposal) {
        proposals = TradeProposalStateReducer.replacingOrPrepending(proposal, in: proposals)
    }
}
