import Foundation
import MegrumCore

struct TradeEvaluationPromptState: Equatable, Sendable {
    var hasSubmittedEvaluation: Bool
    var hasPartnerSubmittedEvaluation: Bool
    var revealedEvaluations: [TradeCompletedEvaluationPresentation]
    var shouldRevealEvaluations: Bool {
        hasSubmittedEvaluation && hasPartnerSubmittedEvaluation && revealedEvaluations.count >= 2
    }

    init(
        proposal: TradeProposal,
        viewerID: UUID?,
        messages: [TradeMessage],
        localSubmission: Bool = false
    ) {
        guard proposal.status == .completed, let viewerID else {
            self.hasSubmittedEvaluation = false
            self.hasPartnerSubmittedEvaluation = false
            self.revealedEvaluations = []
            return
        }

        let evaluationMessages = messages.filter { TradeEvaluationSystemMessage.isEvaluationNotice($0) }
        self.hasSubmittedEvaluation = localSubmission || evaluationMessages.contains { message in
            message.senderID == viewerID
        }
        self.hasPartnerSubmittedEvaluation = evaluationMessages.contains { message in
            message.senderID != viewerID
        }
        self.revealedEvaluations = messages
            .compactMap { TradeEvaluationSystemMessage.evaluation(from: $0, viewerID: viewerID) }
            .sorted { lhs, rhs in
                if lhs.isMine != rhs.isMine {
                    return lhs.isMine
                }
                return lhs.createdAt < rhs.createdAt
            }
    }
}

struct TradeCompletedEvaluationPresentation: Identifiable, Equatable, Sendable {
    var id: String { raterID?.uuidString ?? "\(displayName)-\(createdAt.timeIntervalSince1970)" }
    var raterID: UUID?
    var displayName: String
    var roleTag: String
    var stars: Int
    var comment: String?
    var createdAt: Date
    var isMine: Bool
}

struct TradeCancelApprovalPrompt: Equatable, Sendable {
    var canApprove: Bool

    init(
        message: TradeMessage,
        proposal: TradeProposal,
        viewerID: UUID?,
        messages: [TradeMessage]
    ) {
        guard
            let viewerID,
            proposal.status == .agreed,
            proposal.isParticipant(viewerID),
            message.messageType == .system,
            message.meta["action"] == TradeAssistanceSystemIntent.Action.cancelRequested.rawValue
        else {
            canApprove = false
            return
        }

        let viewerKey = viewerID.uuidString.lowercased()
        let requesterKey = message.meta["requested_by"]?.lowercased()
            ?? message.senderID.uuidString.lowercased()
        let alreadyApproved = messages.contains { $0.meta["action"] == "cancel_approved" }
        canApprove = requesterKey != viewerKey && !alreadyApproved
    }
}
