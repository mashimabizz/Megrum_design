import Foundation
import MegrumCore

enum TradeStageRouteRequestResolver {
    static func resolve(current: TradeStage, requested: TradeStage?) -> TradeStage {
        requested ?? current
    }
}

struct TradeDetailRoute: Identifiable, Hashable {
    var proposalID: UUID

    var id: UUID { proposalID }
}

enum TradeCardReadState: Equatable {
    case unopened
    case opened
    case waitingForReply

    var title: String {
        switch self {
        case .unopened:
            "未開封"
        case .opened:
            "開封済み"
        case .waitingForReply:
            "返信待ち"
        }
    }
}

struct TradeCardPresentation: Equatable {
    var partnerHandle: String
    var partnerInitial: String
    var updatedText: String
    var readState: TradeCardReadState
    var meetupSummaryText: String

    init(
        proposal: TradeProposal,
        viewerID: UUID?,
        profilesByUserID: [UUID: PublicUserProfile],
        lastActivityAt: Date? = nil,
        viewerLastReadAt: Date? = nil,
        now: Date = .now
    ) {
        let partnerID = viewerID.flatMap { proposal.partnerID(for: $0) }
            ?? proposal.receiverID
        let handle = profilesByUserID[partnerID]?.profile.handle
            ?? Self.fallbackHandle(for: partnerID)
        self.partnerHandle = handle
        self.partnerInitial = String(handle.prefix(1)).uppercased()
        let activityAt = lastActivityAt ?? proposal.updatedAt ?? proposal.createdAt
        self.updatedText = Self.relativeTimeText(from: activityAt, now: now)
        let needsAction = Self.needsAction(proposal: proposal, viewerID: viewerID)
        self.readState = Self.readState(
            for: proposal,
            viewerID: viewerID,
            lastActivityAt: activityAt,
            viewerLastReadAt: viewerLastReadAt,
            needsAction: needsAction
        )
        self.meetupSummaryText = Self.meetupSummaryText(for: proposal)
    }

    private static func fallbackHandle(for userID: UUID) -> String {
        "user_\(userID.uuidString.prefix(4).lowercased())"
    }

    private static func needsAction(proposal: TradeProposal, viewerID: UUID?) -> Bool {
        guard let viewerID else {
            return false
        }
        switch proposal.status {
        case .sent:
            return proposal.receiverID == viewerID
        case .negotiating:
            return proposal.receiverID == viewerID
        case .agreementOneSide:
            return !proposal.agreementBy(viewerID)
        case .agreed:
            return false
        case .draft, .completed, .cancelled, .rejected, .expired:
            return false
        }
    }

    static func readState(
        for proposal: TradeProposal,
        viewerID: UUID?,
        lastActivityAt: Date? = nil,
        viewerLastReadAt: Date? = nil
    ) -> TradeCardReadState {
        readState(
            for: proposal,
            viewerID: viewerID,
            lastActivityAt: lastActivityAt ?? proposal.updatedAt ?? proposal.createdAt,
            viewerLastReadAt: viewerLastReadAt,
            needsAction: needsAction(proposal: proposal, viewerID: viewerID)
        )
    }

    private static func readState(
        for proposal: TradeProposal,
        viewerID: UUID?,
        lastActivityAt: Date,
        viewerLastReadAt: Date?,
        needsAction: Bool
    ) -> TradeCardReadState {
        guard let viewerID else {
            return .opened
        }

        let hasOpenedLatestActivity = viewerLastReadAt.map { $0 >= lastActivityAt } ?? false

        if proposal.senderID == viewerID, proposal.isProposalResponsePending, !needsAction {
            return .waitingForReply
        }

        switch proposal.status {
        case .sent:
            return proposal.receiverID == viewerID && !hasOpenedLatestActivity ? .unopened : .opened
        case .agreementOneSide:
            if proposal.agreementBy(viewerID) {
                return .waitingForReply
            }
            return hasOpenedLatestActivity ? .opened : .unopened
        case .negotiating:
            return needsAction && !hasOpenedLatestActivity ? .unopened : .opened
        case .draft, .agreed, .completed, .cancelled, .rejected, .expired:
            return .opened
        }
    }

    private static func relativeTimeText(from date: Date, now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        if seconds < 60 {
            return "たった今"
        }
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)分前"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)時間前"
        }
        return "\(hours / 24)日前"
    }

    private static func meetupSummaryText(for proposal: TradeProposal) -> String {
        switch proposal.exchangeMethod {
        case .hand, .both:
            let candidates = (proposal.meetupCandidates ?? []).filter(\.isValid)
            if let primary = candidates.first {
                return TradeMeetupSummaryCopy.displayText(
                    primaryText: TradeMeetupSummaryCopy.primaryText(for: primary),
                    additionalCandidateCount: max(0, candidates.count - 1)
                )
            }
            let primary = proposal.status == .agreed
                ? "横浜アリーナ 北口 × 今日 18:15-18:45"
                : "横浜アリーナ × 候補確認中"
            return TradeMeetupSummaryCopy.displayText(primaryText: primary, additionalCandidateCount: 0)
        case .mail:
            return "住所確認中"
        }
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
