import Foundation
import MegrumCore

public enum SupabaseDisputeClientError: Error, Equatable, Sendable {
    case proposalNotFound
    case notParticipant
    case missingRespondent
    case emptyFactMemo
    case malformedResponse
}

public final class SupabaseDisputeClient: @unchecked Sendable {
    private let client: SupabaseRESTClient

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
    }

    public func createDispute(userID: UUID, input: TradeDisputeCreateInput) async throws -> TradeDisputeTicket {
        let proposal = try await loadProposal(proposalID: input.proposalID)
        return try await createDispute(userID: userID, proposal: proposal, input: input)
    }

    public func createDispute(
        userID: UUID,
        proposal: TradeProposal,
        input: TradeDisputeCreateInput
    ) async throws -> TradeDisputeTicket {
        guard proposal.isParticipant(userID) else {
            throw SupabaseDisputeClientError.notParticipant
        }
        guard let respondentID = proposal.partnerID(for: userID) else {
            throw SupabaseDisputeClientError.missingRespondent
        }
        guard !input.factMemo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SupabaseDisputeClientError.emptyFactMemo
        }

        let ticketNo = Self.makeTicketNo()
        let rows: [DisputeRow] = try await client.insertRows(
            into: "disputes",
            values: [
                DisputeInsertPayload(
                    proposalID: input.proposalID,
                    reporterID: userID,
                    respondentID: respondentID,
                    category: input.category.rawValue,
                    factMemo: input.factMemo.trimmingCharacters(in: .whitespacesAndNewlines),
                    evidencePhotoUrls: [],
                    ticketNo: ticketNo
                )
            ],
            select: DisputeRow.select
        )
        guard let ticket = rows.first?.ticket(proposalID: input.proposalID) else {
            throw SupabaseDisputeClientError.malformedResponse
        }
        try? await createSystemMessage(
            proposalID: input.proposalID,
            senderID: userID,
            body: "取引の申告を受け付けました（\(ticket.ticketNo)）"
        )
        return ticket
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
        return try client.makeInsertRequest(
            into: "disputes",
            values: [
                DisputeInsertPayload(
                    proposalID: input.proposalID,
                    reporterID: userID,
                    respondentID: respondentID,
                    category: input.category.rawValue,
                    factMemo: input.factMemo.trimmingCharacters(in: .whitespacesAndNewlines),
                    evidencePhotoUrls: [],
                    ticketNo: ticketNo
                )
            ],
            select: DisputeRow.select
        )
    }

    private func loadProposal(proposalID: UUID) async throws -> TradeProposal {
        let rows: [DisputeProposalRow] = try await client.fetchRows(
            from: "proposals",
            select: DisputeProposalRow.select,
            queryItems: [
                URLQueryItem(name: "id", value: "eq.\(proposalID.uuidString.lowercased())"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        guard let proposal = rows.first?.proposal else {
            throw SupabaseDisputeClientError.proposalNotFound
        }
        return proposal
    }

    private func createSystemMessage(proposalID: UUID, senderID: UUID, body: String) async throws {
        let _: [SystemMessageAckRow] = try await client.insertRows(
            into: "messages",
            values: [SystemMessagePayload(proposalID: proposalID, senderID: senderID, body: body)],
            select: "id"
        )
    }

    private static func makeTicketNo(now: Date = .now, id: UUID = UUID()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyMMdd"
        return "DPT-\(formatter.string(from: now))-\(id.uuidString.prefix(8).uppercased())"
    }
}

private struct DisputeProposalRow: Decodable, Sendable {
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

private struct DisputeInsertPayload: Encodable, Sendable {
    var proposalID: UUID
    var reporterID: UUID
    var respondentID: UUID
    var category: String
    var factMemo: String
    var evidencePhotoUrls: [String]
    var ticketNo: String
}

private struct DisputeRow: Decodable, Sendable {
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

private struct SystemMessagePayload: Encodable, Sendable {
    var proposalID: UUID
    var senderID: UUID
    var messageType = TradeMessageType.system.rawValue
    var body: String
}

private struct SystemMessageAckRow: Decodable, Sendable {
    var id: UUID
}
