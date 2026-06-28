import Foundation
import MegrumCore

struct TradeStageAttentionCounts: Equatable {
    var pendingNeedsResponse: Int
    var inProgressUnread: Int
    var completedNeedsEvaluation: Int

    var total: Int {
        pendingNeedsResponse + inProgressUnread + completedNeedsEvaluation
    }

    init(
        proposals: [TradeProposal],
        messagesByProposalID: [UUID: [TradeMessage]],
        viewerReadAtByProposalID: [UUID: Date],
        viewerID: UUID?
    ) {
        guard let viewerID else {
            pendingNeedsResponse = 0
            inProgressUnread = 0
            completedNeedsEvaluation = 0
            return
        }

        pendingNeedsResponse = proposals.filter { proposal in
            TradeStage.pending.contains(proposal.status)
                && TradeCardPresentation.needsAction(proposal: proposal, viewerID: viewerID)
        }.count

        inProgressUnread = proposals.filter { proposal in
            guard TradeStage.inProgress.contains(proposal.status) else {
                return false
            }
            let messages = messagesByProposalID[proposal.id] ?? []
            return TradeCardPresentation(
                proposal: proposal,
                viewerID: viewerID,
                profilesByUserID: [:],
                messages: messages,
                lastActivityAt: TradeListOrdering.lastActivityAt(
                    for: proposal,
                    messagesByProposalID: messagesByProposalID
                ),
                viewerLastReadAt: viewerReadAtByProposalID[proposal.id]
            ).unreadBadgeCount > 0
        }.count

        completedNeedsEvaluation = proposals.filter { proposal in
            TradeEvaluationAttentionPolicy.needsViewerEvaluation(
                proposal: proposal,
                viewerID: viewerID,
                messages: messagesByProposalID[proposal.id] ?? []
            )
        }.count
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
