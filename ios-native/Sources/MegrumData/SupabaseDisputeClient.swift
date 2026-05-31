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

public final class SupabaseDisputeClient: @unchecked Sendable {
    private let client: SupabaseRESTClient
    private let encoder: JSONEncoder

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
        self.encoder = Self.makeEncoder()
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
        self.encoder = Self.makeEncoder()
    }

    public func loadDisputes(proposalID: UUID, limit: Int = 10) async throws -> [SupabaseDisputeDetail] {
        let rows: [DisputeDetailRow] = try await client.fetchRows(
            from: "disputes",
            select: DisputeDetailRow.select,
            queryItems: proposalDisputesQueryItems(proposalID: proposalID, limit: limit)
        )
        return rows.map(\.detail)
    }

    public func loadDispute(ticketID: UUID) async throws -> SupabaseDisputeDetail? {
        let rows: [DisputeDetailRow] = try await client.fetchRows(
            from: "disputes",
            select: DisputeDetailRow.select,
            queryItems: ticketDisputeQueryItems(ticketID: ticketID)
        )
        return rows.first?.detail
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

    public func createDisputeReply(_ input: SupabaseDisputeReplyCreateInput) async throws -> SupabaseDisputeMessage {
        try validateReply(input)
        let rows: [DisputeMessageRow] = try await client.insertRows(
            into: "dispute_messages",
            values: [DisputeReplyInsertPayload(input: input)],
            select: DisputeMessageRow.select
        )
        guard let message = rows.first?.message else {
            throw SupabaseDisputeClientError.malformedResponse
        }
        if input.senderRole == .respondent {
            _ = try await markRespondentReplyReceived(input, respondedAt: message.createdAt)
        }
        return message
    }

    @discardableResult
    public func markRespondentReplyReceived(
        _ input: SupabaseDisputeReplyCreateInput,
        respondedAt: Date = .now
    ) async throws -> SupabaseDisputeDetail? {
        try validateReply(input)
        let rows: [DisputeDetailRow] = try await client.updateRows(
            in: "disputes",
            values: DisputeRespondentReplyPayload(input: input, respondedAt: isoTimestamp(respondedAt)),
            select: DisputeDetailRow.select,
            queryItems: respondentReplyQueryItems(ticketID: input.disputeID, respondentID: input.senderID)
        )
        return rows.first?.detail
    }

    @discardableResult
    public func withdrawDispute(
        ticketID: UUID,
        reporterID: UUID,
        closedAt: Date = .now
    ) async throws -> SupabaseDisputeDetail? {
        let rows: [DisputeDetailRow] = try await client.updateRows(
            in: "disputes",
            values: DisputeWithdrawPayload(closedAt: isoTimestamp(closedAt)),
            select: DisputeDetailRow.select,
            queryItems: withdrawQueryItems(ticketID: ticketID, reporterID: reporterID)
        )
        return rows.first?.detail
    }

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
        guard !input.factMemo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
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
                    factMemo: input.factMemo.trimmingCharacters(in: .whitespacesAndNewlines),
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
            body: encoder.encode(DisputeRespondentReplyPayload(input: input, respondedAt: isoTimestamp(respondedAt))),
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
            body: encoder.encode(DisputeWithdrawPayload(closedAt: isoTimestamp(closedAt))),
            prefer: "return=representation"
        )
    }

    private func proposalDisputesQueryItems(proposalID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "proposal_id", value: "eq.\(proposalID.uuidString.lowercased())"),
            URLQueryItem(name: "order", value: "submitted_at.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
    }

    private func ticketDisputeQueryItems(ticketID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(ticketID.uuidString.lowercased())"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    private func withdrawQueryItems(ticketID: UUID, reporterID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(ticketID.uuidString.lowercased())"),
            URLQueryItem(name: "reporter_id", value: "eq.\(reporterID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: "neq.closed")
        ]
    }

    private func respondentReplyQueryItems(ticketID: UUID, respondentID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(ticketID.uuidString.lowercased())"),
            URLQueryItem(name: "respondent_id", value: "eq.\(respondentID.uuidString.lowercased())"),
            URLQueryItem(name: "status", value: "in.(submitted,response_pending)")
        ]
    }

    private func validateReply(_ input: SupabaseDisputeReplyCreateInput) throws {
        let body = input.body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else {
            throw SupabaseDisputeClientError.emptyReplyBody
        }
        guard body.count <= 4_000 else {
            throw SupabaseDisputeClientError.replyBodyTooLong(maxLength: 4_000)
        }
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

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
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

private struct DisputeDetailRow: Decodable, Sendable {
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

private struct DisputeReplyInsertPayload: Encodable, Sendable {
    var disputeID: UUID
    var senderID: UUID
    var senderRole: String
    var body: String
    var photoUrls: [String]

    init(input: SupabaseDisputeReplyCreateInput) {
        self.disputeID = input.disputeID
        self.senderID = input.senderID
        self.senderRole = input.senderRole.rawValue
        self.body = input.body.trimmingCharacters(in: .whitespacesAndNewlines)
        self.photoUrls = input.photoURLs
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private struct DisputeRespondentReplyPayload: Encodable, Sendable {
    var respondentResponse = "disputed"
    var respondentResponseText: String
    var respondentEvidenceUrls: [String]
    var respondentRespondedAt: String
    var status = "arbitrating"

    init(input: SupabaseDisputeReplyCreateInput, respondedAt: String) {
        self.respondentResponseText = input.body.trimmingCharacters(in: .whitespacesAndNewlines)
        self.respondentEvidenceUrls = input.photoURLs
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        self.respondentRespondedAt = respondedAt
    }
}

private struct DisputeWithdrawPayload: Encodable, Sendable {
    var status = "closed"
    var closedAt: String
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

private struct DisputeMessageRow: Decodable, Sendable {
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

private struct SystemMessagePayload: Encodable, Sendable {
    var proposalID: UUID
    var senderID: UUID
    var messageType = TradeMessageType.system.rawValue
    var body: String
}

private struct SystemMessageAckRow: Decodable, Sendable {
    var id: UUID
}

private func isoTimestamp(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
}
