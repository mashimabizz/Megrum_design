import Foundation
import MegrumCore

public enum SupabaseDisputeClientError: Error, Equatable, Sendable {
    case proposalNotFound
    case notParticipant
    case missingRespondent
    case emptyFactMemo
    case emptyReplyBody
    case replyBodyTooLong(maxLength: Int)
    case malformedResponse
}

public enum SupabaseDisputeParticipantRole: String, Codable, Sendable {
    case reporter
    case respondent
}

public struct SupabaseDisputeReplyCreateInput: Equatable, Sendable {
    public var disputeID: UUID
    public var senderID: UUID
    public var senderRole: SupabaseDisputeParticipantRole
    public var body: String
    public var photoURLs: [String]

    public init(
        disputeID: UUID,
        senderID: UUID,
        senderRole: SupabaseDisputeParticipantRole,
        body: String,
        photoURLs: [String] = []
    ) {
        self.disputeID = disputeID
        self.senderID = senderID
        self.senderRole = senderRole
        self.body = body
        self.photoURLs = photoURLs
    }
}

public struct SupabaseDisputeDetail: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var proposalID: UUID
    public var reporterID: UUID
    public var respondentID: UUID
    public var category: TradeDisputeCategory?
    public var factMemo: String?
    public var evidencePhotoURLs: [String]
    public var status: String
    public var outcome: String?
    public var operatorComment: String?
    public var ticketNo: String
    public var respondentDeadlineAt: Date?
    public var operatorDeadlineAt: Date?
    public var submittedAt: Date
    public var closedAt: Date?
    public var respondentResponse: String?
    public var respondentResponseText: String?
    public var respondentEvidenceURLs: [String]
    public var respondentRespondedAt: Date?
    public var createdAt: Date?
    public var updatedAt: Date?
    public var messages: [SupabaseDisputeMessage]

    public var ticket: TradeDisputeTicket {
        TradeDisputeTicket(
            id: id,
            proposalID: proposalID,
            ticketNo: ticketNo,
            status: status,
            submittedAt: submittedAt
        )
    }
}

public struct SupabaseDisputeMessage: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var disputeID: UUID
    public var senderID: UUID?
    public var senderRole: SupabaseDisputeParticipantRole?
    public var body: String
    public var photoURLs: [String]
    public var createdAt: Date
}
