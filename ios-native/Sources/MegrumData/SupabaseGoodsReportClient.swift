import Foundation
import MegrumCore

public final class SupabaseGoodsReportClient: @unchecked Sendable {
    private let client: SupabaseRESTClient

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
    }

    public func createReport(reporterID: UUID, input: GoodsReportCreateInput) async throws -> GoodsReportTicket {
        let rows: [GoodsReportRow] = try await client.insertRows(
            into: "goods_reports",
            values: [GoodsReportPayload(reporterID: reporterID, input: input)],
            select: GoodsReportRow.select
        )
        return rows.first?.ticket ?? GoodsReportTicket(
            id: UUID(),
            goodsItemID: input.goodsItemID,
            status: "open"
        )
    }

    public func makeCreateReportRequest(reporterID: UUID, input: GoodsReportCreateInput) throws -> URLRequest {
        try client.makeInsertRequest(
            into: "goods_reports",
            values: [GoodsReportPayload(reporterID: reporterID, input: input)],
            select: GoodsReportRow.select
        )
    }

}

private struct GoodsReportRow: Decodable, Sendable {
    static let select = "id,goods_inventory_id,status,created_at"

    var id: UUID
    var goodsInventoryId: UUID
    var status: String
    var createdAt: Date?

    var ticket: GoodsReportTicket {
        GoodsReportTicket(
            id: id,
            goodsItemID: goodsInventoryId,
            status: status,
            submittedAt: createdAt ?? .now
        )
    }
}

private struct GoodsReportPayload: Encodable, Sendable {
    var reporterId: UUID
    var goodsInventoryId: UUID
    var reportedUserId: UUID
    var reason: String
    var note: String?

    init(reporterID: UUID, input: GoodsReportCreateInput) {
        self.reporterId = reporterID
        self.goodsInventoryId = input.goodsItemID
        self.reportedUserId = input.reportedUserID
        self.reason = input.reason.rawValue
        self.note = input.note
    }
}
