import Foundation
import MegrumCore

public final class SupabaseBoardClient: @unchecked Sendable {
    private static let threadSelect = "id,author_id,title,body,audience_scope,origin_lat,origin_lng,prefecture,latest_activity_at,created_at"
    private static let nearbyRadiusMeters = 3_000.0

    private let client: SupabaseRESTClient

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
    }

    public func loadThreads(
        latitude: Double?,
        longitude: Double?,
        prefecture: String?,
        scope: BoardThread.Audience
    ) async throws -> [BoardThread] {
        let rows: [BoardThreadRow] = try await client.rpcRows(
            function: "list_meguri_board_threads_for_viewer",
            payload: BoardThreadListPayload(
                latitude: latitude,
                longitude: longitude,
                prefecture: prefecture,
                scope: scope
            )
        )
        return rows.compactMap { row in
            guard row.isVisibleInRequestedScope(
                latitude: latitude,
                longitude: longitude,
                prefecture: prefecture,
                scope: scope,
                radiusMeters: Self.nearbyRadiusMeters
            ) else {
                return nil
            }
            return row.thread
        }
    }

    public func loadReplies(
        threadID: UUID,
        latitude: Double?,
        longitude: Double?,
        prefecture: String?,
        scope: BoardThread.Audience
    ) async throws -> [BoardReply] {
        let rows: [BoardReplyRow] = try await client.rpcRows(
            function: "list_meguri_board_replies_for_viewer",
            payload: BoardReplyListPayload(
                threadID: threadID,
                latitude: latitude,
                longitude: longitude,
                prefecture: prefecture,
                scope: scope
            )
        )
        return rows.compactMap(\.reply)
    }

    public func appendReply(_ input: BoardReplyCreateInput) async throws -> BoardReply {
        let rows: [BoardReplyRow] = try await client.rpcRows(
            function: "append_meguri_board_reply_for_viewer",
            payload: BoardReplyAppendPayload(input: input)
        )
        return rows.first?.reply ?? BoardReply(
            id: UUID(),
            threadID: input.threadID,
            authorID: UUID(),
            body: input.body.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    public func createThread(_ input: BoardThreadCreateInput) async throws -> BoardThread {
        let rows: [BoardThreadRow] = try await client.insertRows(
            into: "meguri_board_threads",
            values: [BoardThreadInsertPayload(input: input)],
            select: Self.threadSelect
        )
        return rows.first?.thread ?? BoardThread(
            id: UUID(),
            authorID: input.authorID,
            title: input.title.trimmingCharacters(in: .whitespacesAndNewlines),
            body: input.body.trimmingCharacters(in: .whitespacesAndNewlines),
            audience: input.audience,
            latitude: input.latitude,
            longitude: input.longitude,
            prefecture: input.prefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        )
    }

    public func makeLoadThreadsRequest(
        latitude: Double?,
        longitude: Double?,
        prefecture: String?,
        scope: BoardThread.Audience
    ) throws -> URLRequest {
        try client.makeRPCRequest(
            function: "list_meguri_board_threads_for_viewer",
            payload: BoardThreadListPayload(
                latitude: latitude,
                longitude: longitude,
                prefecture: prefecture,
                scope: scope
            )
        )
    }

    public func makeLoadRepliesRequest(
        threadID: UUID,
        latitude: Double?,
        longitude: Double?,
        prefecture: String?,
        scope: BoardThread.Audience
    ) throws -> URLRequest {
        try client.makeRPCRequest(
            function: "list_meguri_board_replies_for_viewer",
            payload: BoardReplyListPayload(
                threadID: threadID,
                latitude: latitude,
                longitude: longitude,
                prefecture: prefecture,
                scope: scope
            )
        )
    }

    public func makeAppendReplyRequest(_ input: BoardReplyCreateInput) throws -> URLRequest {
        try client.makeRPCRequest(
            function: "append_meguri_board_reply_for_viewer",
            payload: BoardReplyAppendPayload(input: input)
        )
    }

    public func makeCreateThreadRequest(_ input: BoardThreadCreateInput) throws -> URLRequest {
        try client.makeInsertRequest(
            into: "meguri_board_threads",
            values: [BoardThreadInsertPayload(input: input)],
            select: Self.threadSelect
        )
    }
}

private struct BoardThreadListPayload: Encodable, Sendable {
    var pViewerLat: Double?
    var pViewerLng: Double?
    var pPrefecture: String?
    var pScope: String

    init(latitude: Double?, longitude: Double?, prefecture: String?, scope: BoardThread.Audience) {
        let context = BoardScopeQueryContext(
            latitude: latitude,
            longitude: longitude,
            prefecture: prefecture,
            scope: scope
        )
        self.pViewerLat = context.latitude
        self.pViewerLng = context.longitude
        self.pPrefecture = context.prefecture
        self.pScope = context.rpcScope.rawValue
    }

    enum CodingKeys: String, CodingKey {
        case pViewerLat
        case pViewerLng
        case pPrefecture
        case pScope
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let pViewerLat {
            try container.encode(pViewerLat, forKey: .pViewerLat)
        } else {
            try container.encodeNil(forKey: .pViewerLat)
        }
        if let pViewerLng {
            try container.encode(pViewerLng, forKey: .pViewerLng)
        } else {
            try container.encodeNil(forKey: .pViewerLng)
        }
        if let pPrefecture {
            try container.encode(pPrefecture, forKey: .pPrefecture)
        } else {
            try container.encodeNil(forKey: .pPrefecture)
        }
        try container.encode(pScope, forKey: .pScope)
    }
}

private struct BoardThreadRow: Decodable, Sendable {
    var id: UUID
    var authorId: UUID
    var title: String
    var body: String
    var audienceScope: String?
    var originLat: Double?
    var originLng: Double?
    var prefecture: String?
    var latestActivityAt: Date?
    var createdAt: Date?

    var thread: BoardThread? {
        let audience = BoardThread.Audience(rawValue: audienceScope ?? "") ?? .nearby3km
        return BoardThread(
            id: id,
            authorID: authorId,
            title: title,
            body: body,
            audience: audience,
            latitude: originLat,
            longitude: originLng,
            prefecture: prefecture,
            createdAt: latestActivityAt ?? createdAt ?? .now
        )
    }

    func isVisibleInRequestedScope(
        latitude: Double?,
        longitude: Double?,
        prefecture: String?,
        scope: BoardThread.Audience,
        radiusMeters: Double
    ) -> Bool {
        switch scope {
        case .nearby3km, .sameSpot:
            guard
                let latitude,
                let longitude,
                let originLat,
                let originLng
            else {
                return true
            }
            return haversineMeters(
                fromLatitude: latitude,
                fromLongitude: longitude,
                toLatitude: originLat,
                toLongitude: originLng
            ) <= radiusMeters
        case .samePrefecture:
            guard
                let requestedPrefecture = prefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                let threadPrefecture = self.prefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            else {
                return true
            }
            return threadPrefecture.replacingOccurrences(of: " ", with: "")
                == requestedPrefecture.replacingOccurrences(of: " ", with: "")
        case .global:
            return true
        }
    }
}

private struct BoardThreadInsertPayload: Encodable, Sendable {
    var authorId: UUID
    var audienceScope: String
    var body: String
    var category: String
    var imagePaths: [String]
    var originLat: Double?
    var originLng: Double?
    var prefecture: String?
    var spotKey: String?
    var spotLabel: String?
    var title: String

    init(input: BoardThreadCreateInput) {
        self.authorId = input.authorID
        self.audienceScope = input.audience.rawValue
        self.body = input.body.trimmingCharacters(in: .whitespacesAndNewlines)
        self.category = "chat"
        self.imagePaths = []
        self.originLat = input.latitude
        self.originLng = input.longitude
        self.prefecture = input.prefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.spotKey = nil
        self.spotLabel = nil
        self.title = input.title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    enum CodingKeys: String, CodingKey {
        case authorId
        case audienceScope
        case body
        case category
        case imagePaths
        case originLat
        case originLng
        case prefecture
        case spotKey
        case spotLabel
        case title
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(authorId, forKey: .authorId)
        try container.encode(audienceScope, forKey: .audienceScope)
        try container.encode(body, forKey: .body)
        try container.encode(category, forKey: .category)
        try container.encode(imagePaths, forKey: .imagePaths)
        if let originLat {
            try container.encode(originLat, forKey: .originLat)
        } else {
            try container.encodeNil(forKey: .originLat)
        }
        if let originLng {
            try container.encode(originLng, forKey: .originLng)
        } else {
            try container.encodeNil(forKey: .originLng)
        }
        if let prefecture {
            try container.encode(prefecture, forKey: .prefecture)
        } else {
            try container.encodeNil(forKey: .prefecture)
        }
        try container.encodeNil(forKey: .spotKey)
        try container.encodeNil(forKey: .spotLabel)
        try container.encode(title, forKey: .title)
    }
}

private struct BoardReplyListPayload: Encodable, Sendable {
    var pThreadId: UUID
    var pViewerLat: Double?
    var pViewerLng: Double?
    var pPrefecture: String?
    var pScope: String

    init(
        threadID: UUID,
        latitude: Double?,
        longitude: Double?,
        prefecture: String?,
        scope: BoardThread.Audience
    ) {
        let context = BoardScopeQueryContext(
            latitude: latitude,
            longitude: longitude,
            prefecture: prefecture,
            scope: scope
        )
        self.pThreadId = threadID
        self.pViewerLat = context.latitude
        self.pViewerLng = context.longitude
        self.pPrefecture = context.prefecture
        self.pScope = context.rpcScope.rawValue
    }

    enum CodingKeys: String, CodingKey {
        case pThreadId
        case pViewerLat
        case pViewerLng
        case pPrefecture
        case pScope
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pThreadId, forKey: .pThreadId)
        if let pViewerLat {
            try container.encode(pViewerLat, forKey: .pViewerLat)
        } else {
            try container.encodeNil(forKey: .pViewerLat)
        }
        if let pViewerLng {
            try container.encode(pViewerLng, forKey: .pViewerLng)
        } else {
            try container.encodeNil(forKey: .pViewerLng)
        }
        if let pPrefecture {
            try container.encode(pPrefecture, forKey: .pPrefecture)
        } else {
            try container.encodeNil(forKey: .pPrefecture)
        }
        try container.encode(pScope, forKey: .pScope)
    }
}

private struct BoardReplyAppendPayload: Encodable, Sendable {
    var pThreadId: UUID
    var pBody: String
    var pViewerLat: Double?
    var pViewerLng: Double?
    var pPrefecture: String?
    var pScope: String
    var pParentReplyId: UUID?
    var pQuoteAuthorName: String?
    var pQuoteBody: String?
    var pImagePaths: [String]

    init(input: BoardReplyCreateInput) {
        let context = BoardScopeQueryContext(
            latitude: input.latitude,
            longitude: input.longitude,
            prefecture: input.prefecture,
            scope: input.scope
        )
        self.pThreadId = input.threadID
        self.pBody = input.body.trimmingCharacters(in: .whitespacesAndNewlines)
        self.pViewerLat = context.latitude
        self.pViewerLng = context.longitude
        self.pPrefecture = context.prefecture
        self.pScope = context.rpcScope.rawValue
        self.pParentReplyId = nil
        self.pQuoteAuthorName = nil
        self.pQuoteBody = nil
        self.pImagePaths = []
    }

    enum CodingKeys: String, CodingKey {
        case pThreadId
        case pBody
        case pViewerLat
        case pViewerLng
        case pPrefecture
        case pScope
        case pParentReplyId
        case pQuoteAuthorName
        case pQuoteBody
        case pImagePaths
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pThreadId, forKey: .pThreadId)
        try container.encode(pBody, forKey: .pBody)
        if let pViewerLat {
            try container.encode(pViewerLat, forKey: .pViewerLat)
        } else {
            try container.encodeNil(forKey: .pViewerLat)
        }
        if let pViewerLng {
            try container.encode(pViewerLng, forKey: .pViewerLng)
        } else {
            try container.encodeNil(forKey: .pViewerLng)
        }
        if let pPrefecture {
            try container.encode(pPrefecture, forKey: .pPrefecture)
        } else {
            try container.encodeNil(forKey: .pPrefecture)
        }
        try container.encode(pScope, forKey: .pScope)
        try container.encodeNil(forKey: .pParentReplyId)
        try container.encodeNil(forKey: .pQuoteAuthorName)
        try container.encodeNil(forKey: .pQuoteBody)
        try container.encode(pImagePaths, forKey: .pImagePaths)
    }
}

private struct BoardReplyRow: Decodable, Sendable {
    var id: UUID
    var threadId: UUID
    var authorId: UUID
    var body: String?
    var status: String?
    var createdAt: Date?

    var reply: BoardReply? {
        let status = BoardReply.Status(rawValue: status ?? "visible") ?? .visible
        return BoardReply(
            id: id,
            threadID: threadId,
            authorID: authorId,
            body: body ?? "",
            status: status,
            createdAt: createdAt ?? .now
        )
    }
}

private struct BoardScopeQueryContext: Sendable {
    var latitude: Double?
    var longitude: Double?
    var prefecture: String?
    var rpcScope: BoardThread.Audience

    init(latitude: Double?, longitude: Double?, prefecture: String?, scope: BoardThread.Audience) {
        let trimmedPrefecture = prefecture?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        switch scope {
        case .nearby3km:
            self.latitude = latitude
            self.longitude = longitude
            self.prefecture = nil
            self.rpcScope = .nearby3km
        case .samePrefecture:
            self.latitude = nil
            self.longitude = nil
            self.prefecture = trimmedPrefecture
            self.rpcScope = .samePrefecture
        case .sameSpot, .global:
            self.latitude = latitude
            self.longitude = longitude
            self.prefecture = trimmedPrefecture
            self.rpcScope = scope == .sameSpot ? .nearby3km : .global
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private func haversineMeters(
    fromLatitude: Double,
    fromLongitude: Double,
    toLatitude: Double,
    toLongitude: Double
) -> Double {
    let earthRadius = 6_371_000.0
    let fromLat = fromLatitude * .pi / 180
    let toLat = toLatitude * .pi / 180
    let deltaLat = (toLatitude - fromLatitude) * .pi / 180
    let deltaLng = (toLongitude - fromLongitude) * .pi / 180
    let a = sin(deltaLat / 2) * sin(deltaLat / 2)
        + cos(fromLat) * cos(toLat) * sin(deltaLng / 2) * sin(deltaLng / 2)
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a))
}
