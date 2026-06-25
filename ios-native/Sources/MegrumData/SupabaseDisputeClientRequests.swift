import Foundation
import MegrumCore

extension SupabaseDisputeClient {
    public func makeLoadDisputesRequest(proposalID: UUID, limit: Int = 10) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/disputes",
            queryItems: [
                URLQueryItem(name: "select", value: DisputeDetailRow.select)
            ] + proposalDisputesQueryItems(proposalID: proposalID, limit: limit)
        )
    }

    public func makeLoadDisputeRequest(ticketID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/disputes",
            queryItems: [
                URLQueryItem(name: "select", value: DisputeDetailRow.select)
            ] + ticketDisputeQueryItems(ticketID: ticketID)
        )
    }

    public func makeCreateDisputeRequest(
        userID: UUID,
        proposal: TradeProposal,
        input: TradeDisputeCreateInput,
        ticketNo: String
    ) throws -> URLRequest {
        guard proposal.isParticipant(userID) else {
            throw SupabaseDisputeClientError.notParticipant
        }
        guard let respondentID = proposal.partnerID(for: userID) else {
            throw SupabaseDisputeClientError.missingRespondent
        }
        let factMemo = SupabaseTextNormalizer.trimmed(input.factMemo)
        guard !factMemo.isEmpty else {
            throw SupabaseDisputeClientError.emptyFactMemo
        }
        return try client.makeInsertRequest(
            into: "disputes",
            values: [
                DisputeInsertPayload(
                    proposalID: input.proposalID,
                    reporterID: userID,
                    respondentID: respondentID,
                    category: input.category.rawValue,
                    factMemo: factMemo,
                    evidencePhotoUrls: [],
                    ticketNo: ticketNo
                )
            ],
            select: DisputeRow.select
        )
    }

    public func makeCreateDisputeReplyRequest(_ input: SupabaseDisputeReplyCreateInput) throws -> URLRequest {
        try validateReply(input)
        return try client.makeInsertRequest(
            into: "dispute_messages",
            values: [DisputeReplyInsertPayload(input: input)],
            select: DisputeMessageRow.select
        )
    }

    public func makeMarkRespondentReplyReceivedRequest(
        _ input: SupabaseDisputeReplyCreateInput,
        respondedAt: Date
    ) throws -> URLRequest {
        try validateReply(input)
        return try client.makeMutationRequest(
            path: "/rest/v1/disputes",
            queryItems: [
                URLQueryItem(name: "select", value: DisputeDetailRow.select)
            ] + respondentReplyQueryItems(ticketID: input.disputeID, respondentID: input.senderID),
            method: "PATCH",
            body: encoder.encode(
                DisputeRespondentReplyPayload(
                    input: input,
                    respondedAt: SupabaseDateEncoding.isoTimestamp(respondedAt)
                )
            ),
            prefer: "return=representation"
        )
    }

    public func makeWithdrawDisputeRequest(
        ticketID: UUID,
        reporterID: UUID,
        closedAt: Date
    ) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/disputes",
            queryItems: [
                URLQueryItem(name: "select", value: DisputeDetailRow.select)
            ] + withdrawQueryItems(ticketID: ticketID, reporterID: reporterID),
            method: "PATCH",
            body: encoder.encode(DisputeWithdrawPayload(closedAt: SupabaseDateEncoding.isoTimestamp(closedAt))),
            prefer: "return=representation"
        )
    }
}
