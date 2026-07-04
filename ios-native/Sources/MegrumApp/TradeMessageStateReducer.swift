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

    static func replacingMessagesPreservingViewerEvaluationNotices(
        in messagesByProposalID: [UUID: [TradeMessage]],
        proposalID: UUID,
        messages: [TradeMessage],
        viewerID: UUID?
    ) -> [UUID: [TradeMessage]] {
        replacingMessages(
            in: messagesByProposalID,
            proposalID: proposalID,
            messages: messagesPreservingViewerEvaluationNotices(
                remoteMessages: messages,
                existingMessages: messagesByProposalID[proposalID] ?? [],
                viewerID: viewerID
            )
        )
    }

    static func messagesPreservingViewerEvaluationNotices(
        remoteMessages: [TradeMessage],
        existingMessages: [TradeMessage],
        viewerID: UUID?
    ) -> [TradeMessage] {
        guard let viewerID else {
            return remoteMessages
        }
        let remoteHasViewerEvaluation = remoteMessages.contains { message in
            TradeEvaluationSystemMessage.isEvaluationNotice(message)
                && TradeEvaluationSystemMessage.raterID(for: message) == viewerID
        }
        guard !remoteHasViewerEvaluation else {
            return remoteMessages
        }

        let remoteIDs = Set(remoteMessages.map(\.id))
        let localViewerEvaluationNotices = existingMessages.filter { message in
            TradeEvaluationSystemMessage.isEvaluationNotice(message)
                && TradeEvaluationSystemMessage.raterID(for: message) == viewerID
                && !remoteIDs.contains(message.id)
        }
        guard !localViewerEvaluationNotices.isEmpty else {
            return remoteMessages
        }

        return (remoteMessages + localViewerEvaluationNotices).sorted { lhs, rhs in
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
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
