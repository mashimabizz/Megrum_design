import Foundation
import MegrumCore

public final class SupabaseUserReportClient: @unchecked Sendable {
    private let client: SupabaseRESTClient

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
    }

    public func createReport(reporterID: UUID, input: UserReportCreateInput) async throws -> UserReportTicket {
        let rows: [UserReportRow] = try await client.insertRows(
            into: "reports",
            values: [UserReportPayload(reporterID: reporterID, input: input)],
            select: UserReportRow.select
        )
        return rows.first?.ticket ?? UserReportTicket(
            id: UUID(),
            targetUserID: input.targetUserID,
            status: "open"
        )
    }

    public func makeCreateReportRequest(reporterID: UUID, input: UserReportCreateInput) throws -> URLRequest {
        try client.makeInsertRequest(
            into: "reports",
            values: [UserReportPayload(reporterID: reporterID, input: input)],
            select: UserReportRow.select
        )
    }
}

private struct UserReportRow: Decodable, Sendable {
    static let select = "id,target_user_id,status,created_at"

    var id: UUID
    var targetUserId: UUID
    var status: String
    var createdAt: Date?

    var ticket: UserReportTicket {
        UserReportTicket(
            id: id,
            targetUserID: targetUserId,
            status: status,
            submittedAt: createdAt ?? .now
        )
    }
}

private struct UserReportPayload: Encodable, Sendable {
    var reporterId: UUID
    var targetUserId: UUID
    var category: String
    var description: String?
    var evidenceUrls: [String]

    init(reporterID: UUID, input: UserReportCreateInput) {
        self.reporterId = reporterID
        self.targetUserId = input.targetUserID
        self.category = input.reason.rawValue
        self.description = SupabaseTextNormalizer.optional(input.note)
        self.evidenceUrls = []
    }
}
