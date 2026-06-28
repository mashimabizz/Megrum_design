import Foundation
import MegrumCore

extension SupabaseProposalClient {
    public func makeLoadProposalsRequest(viewerID: UUID) throws -> URLRequest {
        let viewer = viewerID.uuidString.lowercased()
        return try client.makeRequest(
            path: "/rest/v1/proposals",
            queryItems: [
                URLQueryItem(name: "select", value: ProposalRow.select),
                URLQueryItem(name: "or", value: "(sender_id.eq.\(viewer),receiver_id.eq.\(viewer))"),
                URLQueryItem(name: "order", value: "updated_at.desc.nullslast,created_at.desc")
            ]
        )
    }

    public func makeLoadEvidencePhotosRequest(proposalID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/proposal_evidence_photos",
            queryItems: [
                URLQueryItem(name: "select", value: EvidencePhotoRow.select),
                URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
                URLQueryItem(name: "order", value: "position.asc")
            ]
        )
    }

    public func makeDeleteEvidencePhotoRequest(userID: UUID, proposalID: UUID, photoID: UUID) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/proposal_evidence_photos",
            queryItems: evidencePhotoDeleteQueryItems(userID: userID, proposalID: proposalID, photoID: photoID),
            method: "DELETE",
            body: nil,
            prefer: "return=minimal"
        )
    }

    public func makeCreateProposalRequest(senderID: UUID, input: ProposalCreateInput, now: Date = .now) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/proposals",
            queryItems: [
                URLQueryItem(name: "select", value: ProposalRow.legacySelect)
            ],
            method: "POST",
            body: encoder.encode([try ProposalCreatePayload(senderID: senderID, input: input, now: now)]),
            prefer: "resolution=merge-duplicates,return=representation"
        )
    }

    public func makeReviseProposalRequest(userID: UUID, proposalID: UUID, input: ProposalCreateInput, now: Date = .now) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/proposals",
            queryItems: [
                URLQueryItem(name: "select", value: ProposalRow.select)
            ] + participantProposalQueryItems(proposalID: proposalID, userID: userID),
            method: "PATCH",
            body: encoder.encode(try ProposalRevisionPayload(senderID: userID, input: input, now: now)),
            prefer: "return=representation"
        )
    }

    public func makeAgreeProposalRequest(
        userID: UUID,
        proposal: TradeProposal,
        acceptedExchangeMethod: ExchangeMethod? = nil
    ) throws -> URLRequest {
        _ = userID
        let resolvedExchangeMethod = try proposal.resolvedExchangeMethod(forAcceptance: acceptedExchangeMethod)
        return try client.makeRPCRequest(
            function: "respond_to_proposal_for_viewer",
            payload: ProposalResponseRPCPayload(
                proposalID: proposal.id,
                action: "agree",
                acceptedExchangeMethod: resolvedExchangeMethod == proposal.exchangeMethod ? nil : resolvedExchangeMethod.rawValue
            )
        )
    }

    public func makeRejectProposalRequest(proposalID: UUID) throws -> URLRequest {
        try client.makeRPCRequest(
            function: "respond_to_proposal_for_viewer",
            payload: ProposalResponseRPCPayload(
                proposalID: proposalID,
                action: "reject",
                acceptedExchangeMethod: nil
            )
        )
    }

    public func makeApproveEvidenceRequest(
        userID: UUID,
        proposal: TradeProposal,
        photoID: UUID? = nil
    ) throws -> URLRequest {
        guard proposal.isParticipant(userID) else {
            throw SupabaseProposalClientError.notParticipant
        }
        guard proposal.status == .agreed || proposal.status == .completed else {
            throw SupabaseProposalClientError.invalidStatus
        }
        guard proposal.evidencePhotoURL != nil else {
            throw SupabaseProposalClientError.missingEvidence
        }
        return try client.makeRPCRequest(
            function: "approve_trade_evidence_for_viewer",
            payload: ProposalApprovalRPCPayload(proposalID: proposal.id, photoID: photoID)
        )
    }

    public func makeApproveCancelRequest(userID: UUID, proposal: TradeProposal, now: Date = .now) throws -> URLRequest {
        guard proposal.isParticipant(userID) else {
            throw SupabaseProposalClientError.notParticipant
        }
        guard proposal.status == .agreed else {
            throw SupabaseProposalClientError.invalidStatus
        }
        return try client.makeMutationRequest(
            path: "/rest/v1/proposals",
            queryItems: [
                URLQueryItem(name: "select", value: ProposalRow.select)
            ] + cancelApprovalQueryItems(proposalID: proposal.id, userID: userID),
            method: "PATCH",
            body: encoder.encode(ProposalCancelApprovalUpdatePayload(now: now)),
            prefer: "return=representation"
        )
    }

    public func makeSubmitEvaluationRequest(userID: UUID, proposal: TradeProposal, input: TradeEvaluationCreateInput) throws -> URLRequest {
        guard (1...5).contains(input.stars) else {
            throw SupabaseProposalClientError.invalidRating
        }
        guard proposal.isParticipant(userID), let rateeID = proposal.partnerID(for: userID) else {
            throw SupabaseProposalClientError.notParticipant
        }
        guard proposal.status == .completed else {
            throw SupabaseProposalClientError.invalidStatus
        }
        return try client.makeInsertRequest(
            into: "user_evaluations",
            values: [
                EvaluationInsertPayload(
                    proposalID: input.proposalID,
                    raterID: userID,
                    rateeID: rateeID,
                    stars: input.stars,
                    comment: SupabaseTextNormalizer.optional(input.comment)
                )
            ],
            select: "id,rater_id,stars,comment,created_at"
        )
    }
}
