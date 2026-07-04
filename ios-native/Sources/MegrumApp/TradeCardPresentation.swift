import Foundation
import MegrumCore

struct TradeCardPresentation: Equatable {
    var partnerHandle: String
    var partnerInitial: String
    var partnerRatingText: String?
    var partnerDemographicText: String?
    var updatedText: String
    var readState: TradeCardReadState
    var unreadBadgeCount: Int
    var needsEvaluationAttention: Bool
    var meetupSummaryText: String?
    var conditionIconSystemName: String

    init(
        proposal: TradeProposal,
        viewerID: UUID?,
        profilesByUserID: [UUID: PublicUserProfile],
        messages: [TradeMessage] = [],
        lastActivityAt: Date? = nil,
        viewerLastReadAt: Date? = nil,
        viewerHasSubmittedEvaluation: Bool = false,
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
        self.needsEvaluationAttention = TradeEvaluationAttentionPolicy.needsViewerEvaluation(
            proposal: proposal,
            viewerID: viewerID,
            messages: messages,
            localSubmission: viewerHasSubmittedEvaluation
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

    static func needsAction(proposal: TradeProposal, viewerID: UUID?) -> Bool {
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
