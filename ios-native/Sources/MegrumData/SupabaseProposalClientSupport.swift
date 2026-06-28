import Foundation
import MegrumCore

extension SupabaseProposalClient {
    func loadProposal(proposalID: UUID) async throws -> TradeProposal {
        let rows: [ProposalRow]
        do {
            rows = try await client.fetchRows(
                from: "proposals",
                select: ProposalRow.select,
                queryItems: proposalQueryItems(proposalID: proposalID)
            )
        } catch {
            rows = try await client.fetchRows(
                from: "proposals",
                select: ProposalRow.legacySelect,
                queryItems: proposalQueryItems(proposalID: proposalID)
            )
        }
        guard let proposal = rows.first?.proposal else {
            throw SupabaseProposalClientError.proposalNotFound
        }
        return proposal
    }

    func createSystemMessage(
        proposalID: UUID,
        senderID: UUID,
        body: String,
        meta: [String: String] = [:]
    ) async throws {
        let _: [ProposalSystemMessageAckRow] = try await client.insertRows(
            into: "messages",
            values: [ProposalSystemMessagePayload(proposalID: proposalID, senderID: senderID, body: body, meta: meta)],
            select: "id"
        )
    }

    func proposalQueryItems(proposalID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(proposalID.uuidString.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    func cancelApprovalQueryItems(proposalID: UUID, userID: UUID) -> [URLQueryItem] {
        let viewer = userID.uuidString.lowercased()
        return [
            URLQueryItem(name: "id", value: "eq.\(proposalID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: "eq.\(ProposalStatus.agreed.rawValue)"),
            URLQueryItem(name: "or", value: "(sender_id.eq.\(viewer),receiver_id.eq.\(viewer))"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    func participantProposalQueryItems(proposalID: UUID, userID: UUID) -> [URLQueryItem] {
        let viewer = userID.uuidString.lowercased()
        return [
            URLQueryItem(name: "id", value: "eq.\(proposalID.uuidString.lowercased())"),
            URLQueryItem(name: "or", value: "(sender_id.eq.\(viewer),receiver_id.eq.\(viewer))"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    func evidencePhotoDeleteQueryItems(userID: UUID, proposalID: UUID, photoID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(photoID.uuidString.lowercased())"),
            URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
            URLQueryItem(name: "taken_by", value: "eq.\(userID.uuidString.lowercased())")
        ]
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}
