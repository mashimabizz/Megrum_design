import Foundation
import MegrumCore

public enum SupabaseBoardClientError: Error, Equatable, Sendable {
    case imageTooLarge
    case malformedResponse
}

public final class SupabaseBoardClient: @unchecked Sendable {
    private static let threadSelect = "id,author_id,title,body,audience_scope,origin_lat,origin_lng,prefecture,image_paths,group_id,character_id,series_name,status,reply_count,latest_activity_at,expires_at,created_at,anonymous_display_name,anonymous_avatar_id"
    private static let nearbyRadiusMeters = 1_000.0
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
        scope: BoardThread.Audience,
        allowsExtendedBoardAccess: Bool = false
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
                radiusMeters: Self.nearbyRadiusMeters,
                allowsExtendedBoardAccess: allowsExtendedBoardAccess
            ) else {
                return nil
            }
            return row.thread(signedURLs: signedURLs)
        }
    }

    /// 地図の吹き出し用：複数スレッドの最新リプライ本文をまとめて取得する。
    public func loadReplyPreviews(threadIDs: [UUID], perThreadLimit: Int = 3) async throws -> [UUID: [String]] {
        guard !threadIDs.isEmpty else {
            return [:]
        }
        struct PreviewRow: Decodable {
            var threadId: UUID
            var body: String?
        }
        let idList = threadIDs.map { $0.uuidString.lowercased() }.sorted().joined(separator: ",")
        let rows: [PreviewRow] = try await client.fetchRows(
            from: "meguri_board_replies",
            select: "thread_id,body",
            queryItems: [
                URLQueryItem(name: "thread_id", value: "in.(\(idList))"),
                URLQueryItem(name: "status", value: "eq.visible"),
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: "\(max(perThreadLimit * threadIDs.count, 30))")
            ]
        )
        var previews: [UUID: [String]] = [:]
        for row in rows {
            guard let body = row.body?.trimmingCharacters(in: .whitespacesAndNewlines), !body.isEmpty else {
                continue
            }
            if previews[row.threadId, default: []].count < perThreadLimit {
                previews[row.threadId, default: []].append(body)
            }
        }
        return previews
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
        let signedURLs = await signedURLMap(for: rows)
        return rows.compactMap { $0.reply(signedURLs: signedURLs) }
    }

    public func appendReply(_ input: BoardReplyCreateInput) async throws -> BoardReply {
        let imagePaths = try await boardImagePaths(for: input)
        var input = input
        input.imagePaths = imagePaths
        let rows: [BoardReplyRow] = try await client.rpcRows(
            function: "append_meguri_board_reply_for_viewer",
            payload: BoardReplyAppendPayload(input: input)
        )
        let signedURLs = await signedURLMap(for: rows)
        guard let reply = rows.first?.reply(signedURLs: signedURLs) else {
            throw SupabaseBoardClientError.malformedResponse
        }
        return reply
    }

    public func setThreadReaction(threadID: UUID, reaction: BoardMessageReaction?) async throws {
        try await client.rpcVoid(
            function: "set_meguri_board_thread_message_reaction",
            payload: BoardThreadReactionPayload(threadID: threadID, reaction: reaction)
        )
    }

    public func setReplyReaction(replyID: UUID, reaction: BoardMessageReaction?) async throws {
        try await client.rpcVoid(
            function: "set_meguri_board_reply_message_reaction",
            payload: BoardReplyReactionPayload(replyID: replyID, reaction: reaction)
        )
    }

    public func reportThread(threadID: UUID, reason: String) async throws {
        try await client.rpcVoid(
            function: "report_meguri_board_thread",
            payload: BoardThreadReportPayload(threadID: threadID, reason: reason)
        )
    }

    public func createThread(_ input: BoardThreadCreateInput) async throws -> BoardThread {
        let imagePaths = try await boardImagePaths(for: input)
        let rows: [BoardThreadRow] = try await client.rpcRows(
            function: "create_meguri_board_thread_for_viewer",
            payload: BoardThreadCreatePayload(input: input, imagePaths: imagePaths)
        )
        guard let row = rows.first else {
            throw SupabaseBoardClientError.malformedResponse
        }
        let signedURLs = await signedURLMap(for: rows)
        guard let thread = row.thread(signedURLs: signedURLs) else {
            throw SupabaseBoardClientError.malformedResponse
        }
        return thread
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
        try client.makeRPCRequest(
            function: "create_meguri_board_thread_for_viewer",
            payload: BoardThreadCreatePayload(input: input, imagePaths: input.imagePaths)
        )
    }

    private func boardImagePaths(for input: BoardThreadCreateInput) async throws -> [String] {
        var paths = input.imagePaths.map(SupabaseTextNormalizer.trimmed)
            .filter { !$0.isEmpty }
        if let upload = input.thumbnailUpload {
            guard upload.data.count <= Self.maxUploadBytes else {
                throw SupabaseBoardClientError.imageTooLarge
            }
            let contentType = SupabaseImageContentTypeNormalizer.lenient(upload.contentType)
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

    private func signedURLMap(for rows: [BoardReplyRow]) async -> [String: URL] {
        var signedURLs: [String: URL] = [:]
        let paths = Set(rows.flatMap { $0.imagePaths ?? [] }.filter { storagePathCandidate($0) })
        for path in paths {
            signedURLs[path] = try? await client.createSignedURL(bucket: Self.boardMediaBucket, path: path)
        }
        return signedURLs
    }

    private func boardImagePaths(for input: BoardReplyCreateInput) async throws -> [String] {
        var paths = input.imagePaths.map(SupabaseTextNormalizer.trimmed)
            .filter { !$0.isEmpty }
        if let upload = input.imageUpload {
            guard upload.data.count <= Self.maxUploadBytes else {
                throw SupabaseBoardClientError.imageTooLarge
            }
            guard let authorID = input.authorID else {
                throw SupabaseBoardClientError.malformedResponse
            }
            let contentType = SupabaseImageContentTypeNormalizer.lenient(upload.contentType)
            let imagePath = boardImagePath(userID: authorID, contentType: contentType)
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

    private func storagePathCandidate(_ path: String) -> Bool {
        URL(string: path)?.scheme == nil
    }

    private func boardImagePath(userID: UUID, contentType: String) -> String {
        let milliseconds = Int(Date().timeIntervalSince1970 * 1_000)
        return "\(userID.uuidString.lowercased())/\(milliseconds)_\(UUID().uuidString.lowercased()).\(SupabaseImageContentTypeNormalizer.lenientFileExtension(for: contentType))"
    }
}
