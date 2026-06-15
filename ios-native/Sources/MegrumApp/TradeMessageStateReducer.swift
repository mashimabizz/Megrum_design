import Foundation
import MegrumCore

public enum TradeMessageStateReducer {
    public static func replacingMessages(
        in messagesByProposalID: [UUID: [TradeMessage]],
        proposalID: UUID,
        messages: [TradeMessage]
    ) -> [UUID: [TradeMessage]] {
        var next = messagesByProposalID
        next[proposalID] = messages
        return next
    }

    public static func appendingMessage(
        _ message: TradeMessage,
        to messagesByProposalID: [UUID: [TradeMessage]],
        proposalID: UUID
    ) -> [UUID: [TradeMessage]] {
        var next = messagesByProposalID
        next[proposalID, default: []].append(message)
        return next
    }

    public static func settingReadAt(
        in readAtByProposalID: [UUID: Date],
        proposalID: UUID,
        readAt: Date?
    ) -> [UUID: Date] {
        var next = readAtByProposalID
        next[proposalID] = readAt
        return next
    }

    public static func latestReadAt(
        for proposal: TradeProposal,
        proposalID: UUID,
        messages: [TradeMessage]
    ) -> Date {
        TradeListOrdering.lastActivityAt(
            for: proposal,
            messagesByProposalID: [proposalID: messages]
        )
    }

    public static func resolvedReadAt(
        from readState: ProposalReadState?,
        fallback: Date
    ) -> Date {
        readState?.lastReadAt ?? fallback
    }
}
