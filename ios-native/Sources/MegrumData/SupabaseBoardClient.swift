import Foundation
import MegrumCore

public enum SupabaseBoardClientError: Error, Equatable, Sendable {
    case imageTooLarge
}

public final class SupabaseBoardClient: @unchecked Sendable {
    private static let threadSelect = "id,author_id,title,body,audience_scope,origin_lat,origin_lng,prefecture,image_paths,latest_activity_at,created_at"
    private static let nearbyRadiusMeters = 3_000.0
    private static let boardMediaBucket = "meguri-board-media"
    private static let maxUploadBytes = Int(9.5 * 1_024 * 1_024)

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
        let signedURLs = await signedURLMap(for: rows)
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
            return row.thread(signedURLs: signedURLs)
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
            body: SupabaseTextNormalizer.trimmed(input.body)
        )
    }

    public func createThread(_ input: BoardThreadCreateInput) async throws -> BoardThread {
        let imagePaths = try await boardImagePaths(for: input)
        let rows: [BoardThreadRow] = try await client.insertRows(
            into: "meguri_board_threads",
            values: [BoardThreadInsertPayload(input: input, imagePaths: imagePaths)],
            select: Self.threadSelect
        )
        let signedURLs = await signedURLMap(for: rows)
        return rows.first?.thread(signedURLs: signedURLs) ?? BoardThread(
            id: UUID(),
            authorID: input.authorID,
            title: SupabaseTextNormalizer.trimmed(input.title),
            body: SupabaseTextNormalizer.trimmed(input.body),
            audience: input.audience,
            latitude: input.latitude,
            longitude: input.longitude,
            prefecture: SupabaseTextNormalizer.optional(input.prefecture),
            imageURLs: imagePaths.compactMap { displayURL(for: $0, signedURLs: signedURLs) },
            imagePaths: imagePaths
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
            values: [BoardThreadInsertPayload(input: input, imagePaths: input.imagePaths)],
            select: Self.threadSelect
        )
    }

    private func boardImagePaths(for input: BoardThreadCreateInput) async throws -> [String] {
        var paths = input.imagePaths.map(SupabaseTextNormalizer.trimmed)
            .filter { !$0.isEmpty }
        if let upload = input.thumbnailUpload {
            guard upload.data.count <= Self.maxUploadBytes else {
                throw SupabaseBoardClientError.imageTooLarge
            }
            let contentType = normalizedImageContentType(upload.contentType)
            let imagePath = boardImagePath(userID: input.authorID, contentType: contentType)
            try await client.uploadObject(
                bucket: Self.boardMediaBucket,
                path: imagePath,
                data: upload.data,
                contentType: contentType,
                upsert: false
            )
            paths.insert(imagePath, at: 0)
        }
        return Array(paths.prefix(4))
    }

    private func signedURLMap(for rows: [BoardThreadRow]) async -> [String: URL] {
        var signedURLs: [String: URL] = [:]
        let paths = Set(rows.flatMap { $0.imagePaths ?? [] }.filter { storagePathCandidate($0) })
        for path in paths {
            signedURLs[path] = try? await client.createSignedURL(bucket: Self.boardMediaBucket, path: path)
        }
        return signedURLs
    }

    private func storagePathCandidate(_ path: String) -> Bool {
        URL(string: path)?.scheme == nil
    }

    private func displayURL(for path: String, signedURLs: [String: URL]) -> URL? {
        signedURLs[path] ?? URL(string: path)
    }

    private func boardImagePath(userID: UUID, contentType: String) -> String {
        let milliseconds = Int(Date().timeIntervalSince1970 * 1_000)
        return "\(userID.uuidString.lowercased())/\(milliseconds)_\(UUID().uuidString.lowercased()).\(fileExtension(for: contentType))"
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
    var imagePaths: [String]?
    var latestActivityAt: Date?
    var createdAt: Date?

    func thread(signedURLs: [String: URL]) -> BoardThread? {
        let audience = BoardThread.Audience(rawValue: audienceScope ?? "") ?? .nearby3km
        let paths = imagePaths ?? []
        return BoardThread(
            id: id,
            authorID: authorId,
            title: title,
            body: body,
            audience: audience,
            latitude: originLat,
            longitude: originLng,
            prefecture: prefecture,
            imageURLs: paths.compactMap { signedURLs[$0] ?? URL(string: $0) },
            imagePaths: paths,
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
                let requestedPrefecture = SupabaseTextNormalizer.optional(prefecture),
                let threadPrefecture = SupabaseTextNormalizer.optional(self.prefecture)
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

    init(input: BoardThreadCreateInput, imagePaths: [String]) {
        self.authorId = input.authorID
        self.audienceScope = input.audience.rawValue
        self.body = SupabaseTextNormalizer.trimmed(input.body)
        self.category = "chat"
        self.imagePaths = imagePaths
        self.originLat = input.latitude
        self.originLng = input.longitude
        self.prefecture = SupabaseTextNormalizer.optional(input.prefecture)
        self.spotKey = nil
        self.spotLabel = nil
        self.title = SupabaseTextNormalizer.trimmed(input.title)
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
        self.pBody = SupabaseTextNormalizer.trimmed(input.body)
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
        let trimmedPrefecture = SupabaseTextNormalizer.optional(prefecture)
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

private func normalizedImageContentType(_ value: String) -> String {
    switch value.lowercased() {
    case "image/png":
        "image/png"
    case "image/webp":
        "image/webp"
    default:
        "image/jpeg"
    }
}

private func fileExtension(for contentType: String) -> String {
    switch normalizedImageContentType(contentType) {
    case "image/png":
        "png"
    case "image/webp":
        "webp"
    default:
        "jpg"
    }
}
