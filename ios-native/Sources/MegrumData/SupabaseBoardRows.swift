import Foundation
import MegrumCore

struct BoardThreadListPayload: Encodable, Sendable {
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

struct BoardThreadRow: Decodable, Sendable {
    var id: UUID
    var authorId: UUID
    var title: String
    var body: String
    var audienceScope: String?
    var originLat: Double?
    var originLng: Double?
    var prefecture: String?
    var imagePaths: [String]?
    var groupId: UUID?
    var characterId: UUID?
    var seriesName: String?
    var status: String?
    var replyCount: Int?
    var latestActivityAt: Date?
    var expiresAt: Date?
    var createdAt: Date?
    var anonymousDisplayName: String?
    var anonymousAvatarID: String?
    var reactionCount: Int?
    var goodReactionCount: Int?
    var badReactionCount: Int?
    var viewerReacted: Bool?
    var viewerReactionType: String?

    enum CodingKeys: String, CodingKey {
        case id
        case authorId
        case title
        case body
        case audienceScope
        case originLat
        case originLng
        case prefecture
        case imagePaths
        case groupId
        case characterId
        case seriesName
        case status
        case replyCount
        case latestActivityAt
        case expiresAt
        case createdAt
        case anonymousDisplayName
        case anonymousAvatarID = "anonymousAvatarId"
        case reactionCount
        case goodReactionCount
        case badReactionCount
        case viewerReacted
        case viewerReactionType
    }

    func thread(signedURLs: [String: URL]) -> BoardThread? {
        let audience = BoardThread.Audience(rawValue: audienceScope ?? "") ?? .nearby3km
        let paths = imagePaths ?? []
        let created = createdAt ?? latestActivityAt ?? .now
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
            groupID: groupId,
            characterID: characterId,
            seriesName: SupabaseTextNormalizer.optional(seriesName),
            createdAt: created,
            latestActivityAt: latestActivityAt ?? created,
            expiresAt: expiresAt,
            replyCount: max(0, replyCount ?? 0),
            status: status ?? "visible",
            anonymousDisplayName: SupabaseTextNormalizer.optional(anonymousDisplayName),
            anonymousAvatarID: SupabaseTextNormalizer.optional(anonymousAvatarID),
            goodReactionCount: max(0, goodReactionCount ?? reactionCount ?? 0),
            badReactionCount: max(0, badReactionCount ?? 0),
            viewerReaction: BoardMessageReaction(rawValue: viewerReactionType ?? "")
                ?? ((viewerReacted ?? false) ? .good : nil)
        )
    }

    func isVisibleInRequestedScope(
        latitude: Double?,
        longitude: Double?,
        prefecture: String?,
        scope: BoardThread.Audience,
        radiusMeters: Double,
        allowsExtendedBoardAccess: Bool
    ) -> Bool {
        switch scope {
        case .nearby3km, .sameSpot:
            if allowsExtendedBoardAccess {
                return true
            }
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

struct BoardThreadCreatePayload: Encodable, Sendable {
    var pTitle: String
    var pBody: String
    var pScope: String
    var pOriginLat: Double?
    var pOriginLng: Double?
    var pPrefecture: String?
    var pImagePaths: [String]
    var pAnonymousDisplayName: String?
    var pAnonymousAvatarID: String?
    var pGroupID: UUID?
    var pCharacterID: UUID?
    var pSeriesName: String?

    init(input: BoardThreadCreateInput, imagePaths: [String]) {
        self.pTitle = SupabaseTextNormalizer.trimmed(input.title)
        self.pBody = SupabaseTextNormalizer.trimmed(input.body)
        self.pScope = input.audience.rawValue
        self.pOriginLat = input.latitude
        self.pOriginLng = input.longitude
        self.pPrefecture = SupabaseTextNormalizer.optional(input.prefecture)
        self.pImagePaths = imagePaths
        self.pAnonymousDisplayName = SupabaseTextNormalizer.optional(input.anonymousDisplayName)
        self.pAnonymousAvatarID = SupabaseTextNormalizer.optional(input.anonymousAvatarID)
        self.pGroupID = input.groupID
        self.pCharacterID = input.characterID
        self.pSeriesName = SupabaseTextNormalizer.optional(input.seriesName)
    }

    enum CodingKeys: String, CodingKey {
        case pTitle
        case pBody
        case pScope
        case pOriginLat
        case pOriginLng
        case pPrefecture
        case pImagePaths
        case pAnonymousDisplayName
        case pAnonymousAvatarID
        case pGroupID
        case pCharacterID
        case pSeriesName
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pTitle, forKey: .pTitle)
        try container.encode(pBody, forKey: .pBody)
        try container.encode(pScope, forKey: .pScope)
        if let pOriginLat {
            try container.encode(pOriginLat, forKey: .pOriginLat)
        } else {
            try container.encodeNil(forKey: .pOriginLat)
        }
        if let pOriginLng {
            try container.encode(pOriginLng, forKey: .pOriginLng)
        } else {
            try container.encodeNil(forKey: .pOriginLng)
        }
        if let pPrefecture {
            try container.encode(pPrefecture, forKey: .pPrefecture)
        } else {
            try container.encodeNil(forKey: .pPrefecture)
        }
        try container.encode(pImagePaths, forKey: .pImagePaths)
        if let pAnonymousDisplayName {
            try container.encode(pAnonymousDisplayName, forKey: .pAnonymousDisplayName)
        } else {
            try container.encodeNil(forKey: .pAnonymousDisplayName)
        }
        if let pAnonymousAvatarID {
            try container.encode(pAnonymousAvatarID, forKey: .pAnonymousAvatarID)
        } else {
            try container.encodeNil(forKey: .pAnonymousAvatarID)
        }
        if let pGroupID {
            try container.encode(pGroupID, forKey: .pGroupID)
        } else {
            try container.encodeNil(forKey: .pGroupID)
        }
        if let pCharacterID {
            try container.encode(pCharacterID, forKey: .pCharacterID)
        } else {
            try container.encodeNil(forKey: .pCharacterID)
        }
        if let pSeriesName {
            try container.encode(pSeriesName, forKey: .pSeriesName)
        } else {
            try container.encodeNil(forKey: .pSeriesName)
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
