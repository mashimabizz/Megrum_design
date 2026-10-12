import Foundation

public enum SupabaseProposalClientError: Error, Equatable, Sendable {
    case imageTooLarge
    case proposalNotFound
    case notParticipant
    case invalidStatus
    case missingEvidence
    case malformedResponse
    case invalidRating
    case missingMeetup
    /// iter1226.423：同じ取引を二重に評価した（unique違反）。
    case alreadyEvaluated
}

enum SupabaseProposalSystemAction: String, Sendable {
    case evidenceAdded = "evidence_added"
    case tradeCompleted = "trade_completed"
    case evaluationSubmitted = "evaluation_submitted"
}
