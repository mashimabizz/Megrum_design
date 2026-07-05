import Foundation
import MegrumCore

struct BoardReplyListPayload: Encodable, Sendable {
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

struct BoardReplyAppendPayload: Encodable, Sendable {
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
        self.pImagePaths = input.imagePaths
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

struct BoardReplyRow: Decodable, Sendable {
    var id: UUID
    var threadId: UUID
    var authorId: UUID
    var body: String?
    var status: String?
    var createdAt: Date?
    var reactionCount: Int?
    var goodReactionCount: Int?
    var badReactionCount: Int?
    var imagePaths: [String]?
    var viewerReacted: Bool?
    var viewerReactionType: String?

    func reply(signedURLs: [String: URL] = [:]) -> BoardReply? {
        let status = BoardReply.Status(rawValue: status ?? "visible") ?? .visible
        let paths = imagePaths ?? []
        return BoardReply(
            id: id,
            threadID: threadId,
            authorID: authorId,
            body: body ?? "",
            imageURLs: paths.compactMap { signedURLs[$0] ?? URL(string: $0) },
            imagePaths: paths,
            status: status,
            createdAt: createdAt ?? .now,
            goodReactionCount: max(0, goodReactionCount ?? reactionCount ?? 0),
            badReactionCount: max(0, badReactionCount ?? 0),
            viewerReaction: BoardMessageReaction(rawValue: viewerReactionType ?? "")
                ?? ((viewerReacted ?? false) ? .good : nil)
        )
    }
}

struct BoardThreadReactionPayload: Encodable, Sendable {
    var pThreadId: UUID
    var pReactionType: String?

    init(threadID: UUID, reaction: BoardMessageReaction?) {
        self.pThreadId = threadID
        self.pReactionType = reaction?.rawValue
    }
}

struct BoardReplyReactionPayload: Encodable, Sendable {
    var pReplyId: UUID
    var pReactionType: String?

    init(replyID: UUID, reaction: BoardMessageReaction?) {
        self.pReplyId = replyID
        self.pReactionType = reaction?.rawValue
    }
}

struct BoardThreadReportPayload: Encodable, Sendable {
    var pThreadId: UUID
    var pReason: String

    init(threadID: UUID, reason: String) {
        self.pThreadId = threadID
        self.pReason = SupabaseTextNormalizer.trimmed(reason).isEmpty
            ? "user_report"
            : SupabaseTextNormalizer.trimmed(reason)
    }
}
