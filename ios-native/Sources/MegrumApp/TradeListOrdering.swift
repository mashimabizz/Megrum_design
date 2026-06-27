import Foundation
import MegrumCore

struct TradeListDisplaySnapshot {
    var proposals: [TradeProposal]
    var messagesByProposalID: [UUID: [TradeMessage]]
    var viewerReadAtByProposalID: [UUID: Date]

    static func current(
        proposals: [TradeProposal],
        messagesByProposalID: [UUID: [TradeMessage]],
        viewerReadAtByProposalID: [UUID: Date]
    ) -> TradeListDisplaySnapshot {
        TradeListDisplaySnapshot(
            proposals: proposals,
            messagesByProposalID: messagesByProposalID,
            viewerReadAtByProposalID: viewerReadAtByProposalID
        )
    }
}

enum TradeListOrdering {
    static func sorted(
        _ proposals: [TradeProposal],
        viewerID: UUID?,
        messagesByProposalID: [UUID: [TradeMessage]],
        viewerReadAtByProposalID: [UUID: Date] = [:]
    ) -> [TradeProposal] {
        proposals.sorted {
            isOrderedBefore(
                lhs: $0,
                rhs: $1,
                viewerID: viewerID,
                messagesByProposalID: messagesByProposalID,
                viewerReadAtByProposalID: viewerReadAtByProposalID
            )
        }
    }

    static func lastActivityAt(
        for proposal: TradeProposal,
        messagesByProposalID: [UUID: [TradeMessage]]
    ) -> Date {
        let latestMessageAt = messagesByProposalID[proposal.id]?.map(\.createdAt).max()
        return [latestMessageAt, proposal.updatedAt, proposal.createdAt]
            .compactMap(\.self)
            .max() ?? proposal.createdAt
    }

    private static func isOrderedBefore(
        lhs: TradeProposal,
        rhs: TradeProposal,
        viewerID: UUID?,
        messagesByProposalID: [UUID: [TradeMessage]],
        viewerReadAtByProposalID: [UUID: Date]
    ) -> Bool {
        let lhsActivityAt = lastActivityAt(for: lhs, messagesByProposalID: messagesByProposalID)
        let rhsActivityAt = lastActivityAt(for: rhs, messagesByProposalID: messagesByProposalID)
        let lhsReadPriority = readPriority(
            for: lhs,
            viewerID: viewerID,
            lastActivityAt: lhsActivityAt,
            viewerLastReadAt: viewerReadAtByProposalID[lhs.id]
        )
        let rhsReadPriority = readPriority(
            for: rhs,
            viewerID: viewerID,
            lastActivityAt: rhsActivityAt,
            viewerLastReadAt: viewerReadAtByProposalID[rhs.id]
        )
        if lhsReadPriority != rhsReadPriority {
            return lhsReadPriority < rhsReadPriority
        }

        if lhsActivityAt != rhsActivityAt {
            return lhsActivityAt > rhsActivityAt
        }

        return lhs.id.uuidString < rhs.id.uuidString
    }

    private static func readPriority(
        for proposal: TradeProposal,
        viewerID: UUID?,
        lastActivityAt: Date,
        viewerLastReadAt: Date?
    ) -> Int {
        switch TradeCardPresentation.readState(
            for: proposal,
            viewerID: viewerID,
            lastActivityAt: lastActivityAt,
            viewerLastReadAt: viewerLastReadAt
        ) {
        case .unopened:
            return 0
        case .opened:
            return 1
        case .waitingForReply:
            return 2
        }
    }
}

struct TradeMeetupSummaryCopy: Equatable, Sendable {
    static func primaryText(for candidate: ProposalMeetupInput, calendar: Calendar = .current) -> String {
        let place = candidate.normalizedPlaceName.nilIfEmpty ?? "候補確認中"
        return "\(place) × \(timeText(candidate.startAt, calendar: calendar))-\(timeText(candidate.endAt, calendar: calendar))"
    }

    static func displayText(primaryText: String, additionalCandidateCount: Int) -> String {
        let trimmed = primaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? "候補確認中" : trimmed
        guard additionalCandidateCount > 0 else {
            return base
        }
        return "\(base) / 他\(additionalCandidateCount)件の候補"
    }

    private static func timeText(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }
}
