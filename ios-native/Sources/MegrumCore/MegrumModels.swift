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

public enum AccountStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case registered
    case verified
    case onboarding
    case active
    case suspended
    case deletionRequested = "deletion_requested"
    case deleted

    public var id: String { rawValue }

    public var requiresSetup: Bool {
        switch self {
        case .registered, .verified, .onboarding:
            true
        case .active, .suspended, .deletionRequested, .deleted:
            false
        }
    }
}

public struct UserProfile: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var handle: String
    public var displayName: String
    public var avatarURL: URL?
    public var prefecture: String?
    public var accountStatus: AccountStatus

    public init(
        id: UUID,
        handle: String,
        displayName: String,
        avatarURL: URL? = nil,
        prefecture: String? = nil,
        accountStatus: AccountStatus = .active
    ) {
        self.id = id
        self.handle = handle
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.prefecture = prefecture
        self.accountStatus = accountStatus
    }
}

public struct AuthUser: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var email: String?
    public var createdAt: Date?

    public init(id: UUID, email: String? = nil, createdAt: Date? = nil) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
    }
}

public struct AuthSession: Codable, Hashable, Sendable {
    public var accessToken: String
    public var refreshToken: String?
    public var expiresIn: Int?
    public var expiresAt: Date?
    public var tokenType: String
    public var user: AuthUser

    public init(
        accessToken: String,
        refreshToken: String? = nil,
        expiresIn: Int? = nil,
        expiresAt: Date? = nil,
        tokenType: String = "bearer",
        user: AuthUser
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.expiresAt = expiresAt
        self.tokenType = tokenType
        self.user = user
    }

    public var authorizationHeaderValue: String {
        "Bearer \(accessToken)"
    }
}

public enum OshiKind: String, Codable, Sendable, CaseIterable, Identifiable {
    case box
    case specific
    case multi

    public var id: String { rawValue }
}

public struct OshiGroup: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var aliases: [String]
    public var displayOrder: Int

    public init(id: UUID, name: String, aliases: [String] = [], displayOrder: Int = 0) {
        self.id = id
        self.name = name
        self.aliases = aliases
        self.displayOrder = displayOrder
    }
}

public struct OshiCharacter: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var groupID: UUID
    public var name: String
    public var aliases: [String]
    public var displayOrder: Int

    public init(
        id: UUID,
        groupID: UUID,
        name: String,
        aliases: [String] = [],
        displayOrder: Int = 0
    ) {
        self.id = id
        self.groupID = groupID
        self.name = name
        self.aliases = aliases
        self.displayOrder = displayOrder
    }
}

public struct GoodsType: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var category: String?
    public var displayOrder: Int

    public init(id: UUID, name: String, category: String? = nil, displayOrder: Int = 0) {
        self.id = id
        self.name = name
        self.category = category
        self.displayOrder = displayOrder
    }
}

public struct UserOshiSelection: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var userID: UUID
    public var groupID: UUID?
    public var characterID: UUID?
    public var kind: OshiKind
    public var priority: Int

    public init(
        id: UUID,
        userID: UUID,
        groupID: UUID?,
        characterID: UUID?,
        kind: OshiKind,
        priority: Int
    ) {
        self.id = id
        self.userID = userID
        self.groupID = groupID
        self.characterID = characterID
        self.kind = kind
        self.priority = priority
    }
}

public struct MailingAddress: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID { userID }
    public var userID: UUID
    public var recipientName: String
    public var postalCode: String
    public var prefecture: String
    public var city: String
    public var line1: String
    public var line2: String?
    public var phoneNumber: String?
    public var createdAt: Date?
    public var updatedAt: Date?

    public init(
        userID: UUID,
        recipientName: String,
        postalCode: String,
        prefecture: String,
        city: String,
        line1: String,
        line2: String? = nil,
        phoneNumber: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.userID = userID
        self.recipientName = recipientName
        self.postalCode = postalCode
        self.prefecture = prefecture
        self.city = city
        self.line1 = line1
        self.line2 = line2
        self.phoneNumber = phoneNumber
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isReady: Bool {
        [
            recipientName,
            postalCode,
            prefecture,
            city,
            line1
        ].allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } && postalCode.count == 7
    }

    public var formattedPostalCode: String {
        guard postalCode.count > 3 else {
            return postalCode.isEmpty ? "" : "〒\(postalCode)"
        }
        let prefix = postalCode.prefix(3)
        let suffix = postalCode.dropFirst(3)
        return "〒\(prefix)-\(suffix)"
    }

    public var summary: String {
        [formattedPostalCode, "\(prefecture)\(city)\(line1)"]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

public struct PostalCodeAddress: Codable, Hashable, Sendable {
    public var postalCode: String
    public var prefecture: String
    public var city: String
    public var town: String

    public init(
        postalCode: String,
        prefecture: String,
        city: String,
        town: String
    ) {
        self.postalCode = postalCode
        self.prefecture = prefecture
        self.city = city
        self.town = town
    }

    public var line1Suggestion: String {
        town
    }
}

public struct BlockedUser: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID { userID }
    public var userID: UUID
    public var handle: String
    public var displayName: String
    public var avatarURL: URL?
    public var blockedAt: Date?

    public init(
        userID: UUID,
        handle: String,
        displayName: String,
        avatarURL: URL? = nil,
        blockedAt: Date? = nil
    ) {
        self.userID = userID
        self.handle = handle
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.blockedAt = blockedAt
    }
}

public enum MegrumNotificationKind: String, Codable, Sendable, CaseIterable, Identifiable {
    case proposalReceived = "proposal_received"
    case proposalAccepted = "proposal_accepted"
    case proposalRejected = "proposal_rejected"
    case proposalRevised = "proposal_revised"
    case evidenceAdded = "evidence_added"
    case tradeCompleted = "trade_completed"
    case evaluationReceived = "evaluation_received"
    case disputeReceived = "dispute_received"
    case disputeResponded = "dispute_responded"
    case disputeClosed = "dispute_closed"
    case cancelRequested = "cancel_requested"
    case expiresSoon = "expires_soon"
    case groomReply = "groom_reply"
    case meguriMessage = "meguri_message"
    case meguriBoardReply = "meguri_board_reply"
    case meguriBoardMention = "meguri_board_mention"
    case unknown

    public var id: String { rawValue }
}

public struct MegrumNotification: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var kind: MegrumNotificationKind
    public var title: String
    public var body: String?
    public var linkPath: String?
    public var readAt: Date?
    public var createdAt: Date

    public init(
        id: UUID,
        kind: MegrumNotificationKind,
        title: String,
        body: String? = nil,
        linkPath: String? = nil,
        readAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.linkPath = linkPath
        self.readAt = readAt
        self.createdAt = createdAt
    }

    public var isUnread: Bool {
        readAt == nil
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

public enum GoodsEntryKind: String, Codable, Sendable, CaseIterable, Identifiable {
    case inventory
    case wish

    public var id: String { rawValue }

    public var inventoryKind: String {
        switch self {
        case .inventory:
            "for_trade"
        case .wish:
            "wanted"
        }
    }
}

public struct GoodsEntryInput: Equatable, Sendable {
    public var kind: GoodsEntryKind
    public var title: String
    public var groupID: UUID
    public var goodsTypeID: UUID
    public var quantity: Int

    public init(kind: GoodsEntryKind, title: String, groupID: UUID, goodsTypeID: UUID, quantity: Int = 1) {
        self.kind = kind
        self.title = title
        self.groupID = groupID
        self.goodsTypeID = goodsTypeID
        self.quantity = quantity
    }
}

public struct GoodsSearchInput: Equatable, Sendable {
    public var query: String
    public var groupID: UUID?
    public var goodsTypeID: UUID?
    public var limit: Int

    public init(query: String, groupID: UUID? = nil, goodsTypeID: UUID? = nil, limit: Int = 60) {
        self.query = query
        self.groupID = groupID
        self.goodsTypeID = goodsTypeID
        self.limit = limit
    }
}

public enum SearchMatchBucket: String, Codable, Sendable, CaseIterable, Identifiable {
    case matched
    case possible
    case none

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .matched:
            "マッチしてるよ！"
        case .possible:
            "交換できるかも？"
        case .none:
            "マッチなし"
        }
    }
}

public struct SearchResultItem: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var item: GoodsItem
    public var ownerUserID: UUID
    public var bucket: SearchMatchBucket

    public init(item: GoodsItem, ownerUserID: UUID, bucket: SearchMatchBucket) {
        self.id = item.id
        self.item = item
        self.ownerUserID = ownerUserID
        self.bucket = bucket
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

public enum ProposalMatchType: String, Codable, Sendable, CaseIterable, Identifiable {
    case perfect
    case forward
    case backward

    public var id: String { rawValue }
}

public struct ProposalCreateInput: Equatable, Sendable {
    public var receiverID: UUID
    public var senderGoodsIDs: [UUID]
    public var receiverGoodsIDs: [UUID]
    public var exchangeMethod: ExchangeMethod
    public var conditionTags: [String]
    public var message: String?
    public var matchType: ProposalMatchType
    public var status: ProposalStatus

    public init(
        receiverID: UUID,
        senderGoodsIDs: [UUID],
        receiverGoodsIDs: [UUID],
        exchangeMethod: ExchangeMethod = .mail,
        conditionTags: [String] = [],
        message: String? = nil,
        matchType: ProposalMatchType = .forward,
        status: ProposalStatus = .sent
    ) {
        self.receiverID = receiverID
        self.senderGoodsIDs = senderGoodsIDs
        self.receiverGoodsIDs = receiverGoodsIDs
        self.exchangeMethod = exchangeMethod
        self.conditionTags = conditionTags
        self.message = message
        self.matchType = matchType
        self.status = status
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
