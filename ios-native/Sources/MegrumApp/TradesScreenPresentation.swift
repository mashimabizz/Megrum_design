import Foundation
import MegrumCore

struct TradeStageCounts: Equatable {
    var pending: Int
    var inProgress: Int
    var completed: Int

    init(proposals: [TradeProposal]) {
        pending = proposals.filter { TradeStage.pending.contains($0.status) }.count
        inProgress = proposals.filter { TradeStage.inProgress.contains($0.status) }.count
        completed = proposals.filter { TradeStage.completed.contains($0.status) }.count
    }
}

enum TradePendingWithdrawalPolicy {
    static func canWithdraw(_ proposal: TradeProposal, stage: TradeStage, viewerID: UUID?) -> Bool {
        guard stage == .pending, proposal.senderID == viewerID else {
            return false
        }
        return [.sent, .negotiating, .agreementOneSide].contains(proposal.status)
    }
}

enum TradesVisiblePartnerProfiles {
    static func partnerIDs(in proposals: [TradeProposal], viewerID: UUID?) -> [UUID] {
        guard let viewerID else {
            return []
        }
        var seen: Set<UUID> = []
        return proposals.compactMap { proposal in
            guard let partnerID = proposal.partnerID(for: viewerID), !seen.contains(partnerID) else {
                return nil
            }
            seen.insert(partnerID)
            return partnerID
        }
    }

    static func taskKey(for partnerIDs: [UUID]) -> String {
        partnerIDs
            .map(\.uuidString)
            .sorted()
            .joined(separator: ",")
    }
}
