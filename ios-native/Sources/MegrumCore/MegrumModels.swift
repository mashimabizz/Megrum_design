import Foundation

public enum ExchangeMethod: String, Codable, Sendable, CaseIterable, Identifiable {
    case hand
    case mail
    case both

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .hand:
            "現地交換"
        case .mail:
            "郵送交換"
        case .both:
            "どちらもOK"
        }
    }
}

public enum ProposalStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case draft
    case sent
    case negotiating
    case agreementOneSide = "agreement_one_side"
    case agreed
    case rejected
    case expired

    public var id: String { rawValue }
}

public enum MatchBucket: String, Codable, Sendable, CaseIterable, Identifiable {
    case matched
    case possible
    case noMatch = "no_match"

    public var id: String { rawValue }
}

public struct UserProfile: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var handle: String
    public var displayName: String
    public var avatarURL: URL?
    public var prefecture: String?

    public init(
        id: UUID,
        handle: String,
        displayName: String,
        avatarURL: URL? = nil,
        prefecture: String? = nil
    ) {
        self.id = id
        self.handle = handle
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.prefecture = prefecture
    }
}

public struct GoodsTag: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String

    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}

public struct GoodsItem: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var ownerID: UUID
    public var groupID: UUID?
    public var memberID: UUID?
    public var goodsTypeID: UUID?
    public var title: String
    public var imageURL: URL?
    public var tags: [GoodsTag]
    public var quantity: Int

    public init(
        id: UUID,
        ownerID: UUID,
        groupID: UUID? = nil,
        memberID: UUID? = nil,
        goodsTypeID: UUID? = nil,
        title: String,
        imageURL: URL? = nil,
        tags: [GoodsTag] = [],
        quantity: Int = 1
    ) {
        self.id = id
        self.ownerID = ownerID
        self.groupID = groupID
        self.memberID = memberID
        self.goodsTypeID = goodsTypeID
        self.title = title
        self.imageURL = imageURL
        self.tags = tags
        self.quantity = quantity
    }
}

public struct WishItem: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var ownerID: UUID
    public var groupID: UUID?
    public var memberID: UUID?
    public var goodsTypeID: UUID?
    public var title: String
    public var tags: [GoodsTag]

    public init(
        id: UUID,
        ownerID: UUID,
        groupID: UUID? = nil,
        memberID: UUID? = nil,
        goodsTypeID: UUID? = nil,
        title: String,
        tags: [GoodsTag] = []
    ) {
        self.id = id
        self.ownerID = ownerID
        self.groupID = groupID
        self.memberID = memberID
        self.goodsTypeID = goodsTypeID
        self.title = title
        self.tags = tags
    }
}

public struct TradeProposal: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var senderID: UUID
    public var receiverID: UUID
    public var status: ProposalStatus
    public var exchangeMethod: ExchangeMethod
    public var senderGoodsIDs: [UUID]
    public var receiverGoodsIDs: [UUID]
    public var conditionTags: [String]
    public var createdAt: Date

    public init(
        id: UUID,
        senderID: UUID,
        receiverID: UUID,
        status: ProposalStatus,
        exchangeMethod: ExchangeMethod,
        senderGoodsIDs: [UUID],
        receiverGoodsIDs: [UUID],
        conditionTags: [String] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.senderID = senderID
        self.receiverID = receiverID
        self.status = status
        self.exchangeMethod = exchangeMethod
        self.senderGoodsIDs = senderGoodsIDs
        self.receiverGoodsIDs = receiverGoodsIDs
        self.conditionTags = conditionTags
        self.createdAt = createdAt
    }
}

public struct GroomPost: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var authorID: UUID
    public var imageURL: URL
    public var latitude: Double
    public var longitude: Double
    public var createdAt: Date

    public init(
        id: UUID,
        authorID: UUID,
        imageURL: URL,
        latitude: Double,
        longitude: Double,
        createdAt: Date = .now
    ) {
        self.id = id
        self.authorID = authorID
        self.imageURL = imageURL
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
    }
}

public struct BoardThread: Identifiable, Codable, Hashable, Sendable {
    public enum Audience: String, Codable, Sendable, CaseIterable, Identifiable {
        case nearby3km = "nearby_3km"
        case prefecture

        public var id: String { rawValue }
    }

    public var id: UUID
    public var authorID: UUID
    public var title: String
    public var body: String
    public var audience: Audience
    public var latitude: Double?
    public var longitude: Double?
    public var prefecture: String?
    public var createdAt: Date

    public init(
        id: UUID,
        authorID: UUID,
        title: String,
        body: String,
        audience: Audience,
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.authorID = authorID
        self.title = title
        self.body = body
        self.audience = audience
        self.latitude = latitude
        self.longitude = longitude
        self.prefecture = prefecture
        self.createdAt = createdAt
    }
}
