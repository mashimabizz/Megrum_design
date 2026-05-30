import Foundation
import MegrumCore

public final class SupabaseProposalClient: @unchecked Sendable {
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

    public func loadProposals(viewerID: UUID) async throws -> [TradeProposal] {
        let viewer = viewerID.uuidString.lowercased()
        let rows: [ProposalRow] = try await client.fetchRows(
            from: "proposals",
            select: ProposalRow.select,
            queryItems: [
                URLQueryItem(name: "or", value: "(sender_id.eq.\(viewer),receiver_id.eq.\(viewer))"),
                URLQueryItem(name: "order", value: "created_at.desc")
            ]
        )
        return rows.compactMap(\.proposal)
    }

    public func createProposal(senderID: UUID, input: ProposalCreateInput) async throws -> TradeProposal {
        let rows: [ProposalRow] = try await client.upsertRows(
            into: "proposals",
            values: [ProposalCreatePayload(senderID: senderID, input: input)],
            select: ProposalRow.select
        )
        return rows.first?.proposal ?? TradeProposal(
            id: UUID(),
            senderID: senderID,
            receiverID: input.receiverID,
            status: input.status,
            exchangeMethod: input.exchangeMethod,
            senderGoodsIDs: input.senderGoodsIDs,
            receiverGoodsIDs: input.receiverGoodsIDs,
            conditionTags: input.conditionTags
        )
    }

    public func makeLoadProposalsRequest(viewerID: UUID) throws -> URLRequest {
        let viewer = viewerID.uuidString.lowercased()
        return try client.makeRequest(
            path: "/rest/v1/proposals",
            queryItems: [
                URLQueryItem(name: "select", value: ProposalRow.select),
                URLQueryItem(name: "or", value: "(sender_id.eq.\(viewer),receiver_id.eq.\(viewer))"),
                URLQueryItem(name: "order", value: "created_at.desc")
            ]
        )
    }

    public func makeCreateProposalRequest(senderID: UUID, input: ProposalCreateInput) throws -> URLRequest {
        try client.makeMutationRequest(
            path: "/rest/v1/proposals",
            queryItems: [
                URLQueryItem(name: "select", value: ProposalRow.select)
            ],
            method: "POST",
            body: encoder.encode([ProposalCreatePayload(senderID: senderID, input: input)]),
            prefer: "resolution=merge-duplicates,return=representation"
        )
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}

private struct ProposalRow: Decodable, Sendable {
    static let select = "id,sender_id,receiver_id,status,exchange_method,sender_have_ids,receiver_have_ids,option_tags,created_at"

    var id: UUID
    var senderId: UUID
    var receiverId: UUID
    var status: String
    var exchangeMethod: String?
    var senderHaveIds: [UUID]?
    var receiverHaveIds: [UUID]?
    var optionTags: [String]?
    var createdAt: Date?

    var proposal: TradeProposal? {
        guard let proposalStatus = ProposalStatus(rawValue: status) else {
            return nil
        }
        return TradeProposal(
            id: id,
            senderID: senderId,
            receiverID: receiverId,
            status: proposalStatus,
            exchangeMethod: ExchangeMethod(rawValue: exchangeMethod ?? "hand") ?? .hand,
            senderGoodsIDs: senderHaveIds ?? [],
            receiverGoodsIDs: receiverHaveIds ?? [],
            conditionTags: optionTags ?? [],
            createdAt: createdAt ?? .now
        )
    }
}

private struct ProposalCreatePayload: Encodable, Sendable {
    var senderId: UUID
    var receiverId: UUID
    var matchType: String
    var senderHaveIds: [UUID]
    var senderHaveQtys: [Int]
    var receiverHaveIds: [UUID]
    var receiverHaveQtys: [Int]
    var message: String?
    var status: String
    var exchangeMethod: String
    var optionTags: [String]
    var exposeCalendar: Bool

    init(senderID: UUID, input: ProposalCreateInput) {
        self.senderId = senderID
        self.receiverId = input.receiverID
        self.matchType = input.matchType.rawValue
        self.senderHaveIds = input.senderGoodsIDs
        self.senderHaveQtys = input.senderGoodsIDs.map { _ in 1 }
        self.receiverHaveIds = input.receiverGoodsIDs
        self.receiverHaveQtys = input.receiverGoodsIDs.map { _ in 1 }
        self.message = input.message?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.status = input.status.rawValue
        self.exchangeMethod = input.exchangeMethod.rawValue
        self.optionTags = input.conditionTags
        self.exposeCalendar = false
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
