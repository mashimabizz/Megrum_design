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
}

enum SupabaseProposalSystemAction: String, Sendable {
    case evidenceAdded = "evidence_added"
}
