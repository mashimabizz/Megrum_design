import Foundation
import MegrumCore

struct DisputeDetailRow: Decodable, Sendable {
    static let select = [
        "id",
        "proposal_id",
        "reporter_id",
        "respondent_id",
        "category",
        "fact_memo",
        "evidence_photo_urls",
        "status",
        "outcome",
        "operator_comment",
        "ticket_no",
        "respondent_deadline_at",
        "operator_deadline_at",
        "submitted_at",
        "closed_at",
        "created_at",
        "updated_at",
        "respondent_response",
        "respondent_response_text",
        "respondent_evidence_urls",
        "respondent_responded_at",
        "dispute_messages(\(DisputeMessageRow.select))"
    ].joined(separator: ",")

    var id: UUID
    var proposalId: UUID
    var reporterId: UUID
    var respondentId: UUID
    var category: String?
    var factMemo: String?
    var evidencePhotoUrls: [String]?
    var status: String
    var outcome: String?
    var operatorComment: String?
    var ticketNo: String
    var respondentDeadlineAt: Date?
    var operatorDeadlineAt: Date?
    var submittedAt: Date?
    var closedAt: Date?
    var createdAt: Date?
    var updatedAt: Date?
    var respondentResponse: String?
    var respondentResponseText: String?
    var respondentEvidenceUrls: [String]?
    var respondentRespondedAt: Date?
    var disputeMessages: [DisputeMessageRow]?

    var detail: SupabaseDisputeDetail {
        SupabaseDisputeDetail(
            id: id,
            proposalID: proposalId,
            reporterID: reporterId,
            respondentID: respondentId,
            category: category.flatMap(TradeDisputeCategory.init(rawValue:)),
            factMemo: factMemo,
            evidencePhotoURLs: evidencePhotoUrls ?? [],
            status: status,
            outcome: outcome,
            operatorComment: operatorComment,
            ticketNo: ticketNo,
            respondentDeadlineAt: respondentDeadlineAt,
            operatorDeadlineAt: operatorDeadlineAt,
            submittedAt: submittedAt ?? .now,
            closedAt: closedAt,
            respondentResponse: respondentResponse,
            respondentResponseText: respondentResponseText,
            respondentEvidenceURLs: respondentEvidenceUrls ?? [],
            respondentRespondedAt: respondentRespondedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            messages: (disputeMessages ?? []).map(\.message)
        )
    }
}

struct DisputeProposalRow: Decodable, Sendable {
    static let select = "id,sender_id,receiver_id,status"

    var id: UUID
    var senderId: UUID
    var receiverId: UUID
    var status: String?

    var proposal: TradeProposal {
        TradeProposal(
            id: id,
            senderID: senderId,
            receiverID: receiverId,
            status: ProposalStatus(rawValue: status ?? "agreed") ?? .agreed,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: []
        )
    }
}

struct DisputeInsertPayload: Encodable, Sendable {
    var proposalID: UUID
    var reporterID: UUID
    var respondentID: UUID
    var category: String
    var factMemo: String
    var evidencePhotoUrls: [String]
    var ticketNo: String
}

struct DisputeReplyInsertPayload: Encodable, Sendable {
    var disputeID: UUID
    var senderID: UUID
    var senderRole: String
    var body: String
    var photoUrls: [String]

    init(input: SupabaseDisputeReplyCreateInput) {
        self.disputeID = input.disputeID
        self.senderID = input.senderID
        self.senderRole = input.senderRole.rawValue
        self.body = SupabaseTextNormalizer.trimmed(input.body)
        self.photoUrls = SupabaseTextNormalizer.nonEmptyValues(input.photoURLs)
    }
}

struct DisputeRespondentReplyPayload: Encodable, Sendable {
    var respondentResponse = "disputed"
    var respondentResponseText: String
    var respondentEvidenceUrls: [String]
    var respondentRespondedAt: String
    var status = "arbitrating"

    init(input: SupabaseDisputeReplyCreateInput, respondedAt: String) {
        self.respondentResponseText = SupabaseTextNormalizer.trimmed(input.body)
        self.respondentEvidenceUrls = SupabaseTextNormalizer.nonEmptyValues(input.photoURLs)
        self.respondentRespondedAt = respondedAt
    }
}

struct DisputeWithdrawPayload: Encodable, Sendable {
    var status = "closed"
    var closedAt: String
}

struct DisputeRow: Decodable, Sendable {
    static let select = "id,proposal_id,ticket_no,status,submitted_at"

    var id: UUID
    var proposalId: UUID?
    var ticketNo: String
    var status: String
    var submittedAt: Date?

    func ticket(proposalID fallbackProposalID: UUID) -> TradeDisputeTicket {
        TradeDisputeTicket(
            id: id,
            proposalID: proposalId ?? fallbackProposalID,
            ticketNo: ticketNo,
            status: status,
            submittedAt: submittedAt ?? .now
        )
    }
}

struct DisputeMessageRow: Decodable, Sendable {
    static let select = "id,dispute_id,sender_id,sender_role,body,photo_urls,created_at"

    var id: UUID
    var disputeId: UUID
    var senderId: UUID?
    var senderRole: String
    var body: String
    var photoUrls: [String]?
    var createdAt: Date?

    var message: SupabaseDisputeMessage {
        SupabaseDisputeMessage(
            id: id,
            disputeID: disputeId,
            senderID: senderId,
            senderRole: SupabaseDisputeParticipantRole(rawValue: senderRole),
            body: body,
            photoURLs: photoUrls ?? [],
            createdAt: createdAt ?? .now
        )
    }
}

struct DisputeSystemMessagePayload: Encodable, Sendable {
    var proposalID: UUID
    var senderID: UUID
    var messageType = TradeMessageType.system.rawValue
    var body: String
}

struct DisputeSystemMessageAckRow: Decodable, Sendable {
    var id: UUID
}
