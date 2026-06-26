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
    var partnerRatingText: String?
    var partnerDemographicText: String?
    var updatedText: String
    var readState: TradeCardReadState
    var unreadBadgeCount: Int
    var meetupSummaryText: String?
    var conditionIconSystemName: String

    init(
        proposal: TradeProposal,
        viewerID: UUID?,
        profilesByUserID: [UUID: PublicUserProfile],
        messages: [TradeMessage] = [],
        lastActivityAt: Date? = nil,
        viewerLastReadAt: Date? = nil,
        now: Date = .now
    ) {
        let partnerID = viewerID.flatMap { proposal.partnerID(for: $0) }
            ?? proposal.receiverID
        let partnerProfile = profilesByUserID[partnerID]
        let handle = profilesByUserID[partnerID]?.profile.handle
            ?? Self.fallbackHandle(for: partnerID)
        self.partnerHandle = handle
        self.partnerInitial = String(handle.prefix(1)).uppercased()
        self.partnerRatingText = Self.ratingText(for: partnerProfile)
        self.partnerDemographicText = Self.demographicText(for: partnerProfile?.profile)
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
        self.unreadBadgeCount = Self.unreadBadgeCount(
            for: proposal,
            viewerID: viewerID,
            messages: messages,
            viewerLastReadAt: viewerLastReadAt,
            needsAction: needsAction
        )
        let conditionSummary = TradeExchangeConditionSummary.make(for: proposal)
        self.meetupSummaryText = conditionSummary.text
        self.conditionIconSystemName = conditionSummary.iconSystemName
    }

    private static func fallbackHandle(for userID: UUID) -> String {
        "user_\(userID.uuidString.prefix(4).lowercased())"
    }

    private static func ratingText(for profile: PublicUserProfile?) -> String? {
        guard let profile else {
            return nil
        }
        guard let averageStars = profile.averageStars else {
            return profile.evaluationCount > 0 ? "評価\(profile.evaluationCount)件" : "評価なし"
        }
        return String(format: "★ %.1f（%d件）", averageStars, profile.evaluationCount)
    }

    private static func demographicText(for profile: UserProfile?) -> String? {
        guard let profile else {
            return nil
        }
        let ageDecade = profile.age.flatMap(Self.ageDecadeText)
        let gender = profile.gender.flatMap(Self.publicGenderText)
        let parts = [ageDecade, gender].compactMap(\.self)
        return parts.isEmpty ? nil : parts.joined(separator: "・")
    }

    private static func ageDecadeText(for age: Int) -> String? {
        guard age > 0 else {
            return nil
        }
        if age < 10 {
            return "10歳未満"
        }
        return "\(age / 10 * 10)代"
    }

    private static func publicGenderText(for gender: UserGender) -> String? {
        switch gender {
        case .noAnswer:
            return nil
        case .female, .male, .other:
            return gender.displayName
        }
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

    private static func unreadBadgeCount(
        for proposal: TradeProposal,
        viewerID: UUID?,
        messages: [TradeMessage],
        viewerLastReadAt: Date?,
        needsAction: Bool
    ) -> Int {
        guard let viewerID else {
            return 0
        }

        let proposalActionAt = proposal.updatedAt ?? proposal.createdAt
        let hasOpenedProposalAction = viewerLastReadAt.map { $0 >= proposalActionAt } ?? false
        let proposalBadgeCount = needsAction && !hasOpenedProposalAction ? 1 : 0
        let unreadIncomingMessageCount = messages.reduce(0) { count, message in
            guard message.proposalID == proposal.id, message.senderID != viewerID else {
                return count
            }
            if let viewerLastReadAt, message.createdAt <= viewerLastReadAt {
                return count
            }
            return count + 1
        }

        return proposalBadgeCount + unreadIncomingMessageCount
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

}

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
