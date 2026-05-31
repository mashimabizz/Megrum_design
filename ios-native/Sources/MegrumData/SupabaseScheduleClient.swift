import Foundation
import MegrumCore

public enum SupabaseScheduleClientError: Error, Equatable, Sendable {
    case invalidInput
    case malformedResponse
}

public final class SupabaseScheduleClient: @unchecked Sendable {
    private let client: SupabaseRESTClient
    private let dateFormatter: ISO8601DateFormatter

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
        self.dateFormatter = Self.makeDateFormatter()
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
        self.dateFormatter = Self.makeDateFormatter()
    }

    public func loadSchedules(
        userIDs: [UUID],
        startAt: Date,
        endAt: Date,
        limit: Int = 120
    ) async throws -> [PersonalSchedule] {
        guard !userIDs.isEmpty, startAt < endAt else {
            return []
        }
        let rows: [ScheduleRow] = try await client.fetchRows(
            from: "schedules",
            select: ScheduleRow.select,
            queryItems: loadScheduleQueryItems(userIDs: userIDs, startAt: startAt, endAt: endAt, limit: limit)
        )
        return rows.compactMap(\.schedule)
    }

    public func createSchedule(userID: UUID, input: PersonalScheduleCreateInput) async throws -> PersonalSchedule {
        guard input.isValid else {
            throw SupabaseScheduleClientError.invalidInput
        }
        let rows: [ScheduleRow] = try await client.insertRows(
            into: "schedules",
            values: [ScheduleCreatePayload(userID: userID, input: input, dateFormatter: dateFormatter)],
            select: ScheduleRow.select
        )
        guard let schedule = rows.first?.schedule else {
            throw SupabaseScheduleClientError.malformedResponse
        }
        return schedule
    }

    public func makeLoadSchedulesRequest(
        userIDs: [UUID],
        startAt: Date,
        endAt: Date,
        limit: Int = 120
    ) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/schedules",
            queryItems: [URLQueryItem(name: "select", value: ScheduleRow.select)]
                + loadScheduleQueryItems(userIDs: userIDs, startAt: startAt, endAt: endAt, limit: limit)
        )
    }

    public func makeCreateScheduleRequest(userID: UUID, input: PersonalScheduleCreateInput) throws -> URLRequest {
        guard input.isValid else {
            throw SupabaseScheduleClientError.invalidInput
        }
        return try client.makeInsertRequest(
            into: "schedules",
            values: [ScheduleCreatePayload(userID: userID, input: input, dateFormatter: dateFormatter)],
            select: ScheduleRow.select
        )
    }

    private func loadScheduleQueryItems(
        userIDs: [UUID],
        startAt: Date,
        endAt: Date,
        limit: Int
    ) -> [URLQueryItem] {
        let joinedUserIDs = userIDs.map { $0.uuidString.lowercased() }.joined(separator: ",")
        return [
            URLQueryItem(name: "user_id", value: "in.(\(joinedUserIDs))"),
            URLQueryItem(name: "start_at", value: "lt.\(dateFormatter.string(from: endAt))"),
            URLQueryItem(name: "end_at", value: "gt.\(dateFormatter.string(from: startAt))"),
            URLQueryItem(name: "order", value: "start_at.asc"),
            URLQueryItem(name: "limit", value: "\(max(1, min(limit, 200)))")
        ]
    }

    private static func makeDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }
}

private struct ScheduleCreatePayload: Encodable, Sendable {
    var userId: UUID
    var title: String
    var placeName: String?
    var startAt: String
    var endAt: String
    var allDay: Bool
    var note: String?

    init(userID: UUID, input: PersonalScheduleCreateInput, dateFormatter: ISO8601DateFormatter) {
        self.userId = userID
        self.title = input.normalizedTitle
        self.placeName = input.normalizedPlaceName
        self.startAt = dateFormatter.string(from: input.startAt)
        self.endAt = dateFormatter.string(from: input.endAt)
        self.allDay = input.allDay
        self.note = input.normalizedNote
    }
}

private struct ScheduleRow: Decodable, Sendable {
    static let select = "id,user_id,title,place_name,start_at,end_at,all_day,note"

    var id: UUID
    var userId: UUID
    var title: String?
    var placeName: String?
    var startAt: Date?
    var endAt: Date?
    var allDay: Bool?
    var note: String?

    var schedule: PersonalSchedule? {
        guard let startAt, let endAt else {
            return nil
        }
        return PersonalSchedule(
            id: id,
            userID: userId,
            title: title?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank ?? "予定",
            placeName: placeName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank,
            startAt: startAt,
            endAt: endAt,
            allDay: allDay ?? false,
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        )
    }
}

private extension String {
    var nilIfBlank: String? {
        isEmpty ? nil : self
    }
}
