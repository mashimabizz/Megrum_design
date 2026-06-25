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

struct BoardThreadInsertPayload: Encodable, Sendable {
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
