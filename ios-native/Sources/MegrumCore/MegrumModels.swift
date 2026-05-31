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
    case cancelled
    case completed

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

public struct PublicUserProfile: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID { profile.id }
    public var profile: UserProfile
    public var averageStars: Double?
    public var evaluationCount: Int
    public var completedTradeCount: Int

    public init(
        profile: UserProfile,
        averageStars: Double? = nil,
        evaluationCount: Int = 0,
        completedTradeCount: Int = 0
    ) {
        self.profile = profile
        self.averageStars = averageStars
        self.evaluationCount = evaluationCount
        self.completedTradeCount = completedTradeCount
    }

    public var ratingSummary: String {
        guard let averageStars else {
            return "評価なし"
        }
        return String(format: "★ %.1f", averageStars)
    }
}

public struct UserEvaluation: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var raterID: UUID
    public var raterHandle: String
    public var raterDisplayName: String
    public var raterAvatarURL: URL?
    public var stars: Int
    public var comment: String?
    public var createdAt: Date

    public init(
        id: UUID,
        raterID: UUID,
        raterHandle: String,
        raterDisplayName: String,
        raterAvatarURL: URL? = nil,
        stars: Int,
        comment: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.raterID = raterID
        self.raterHandle = raterHandle
        self.raterDisplayName = raterDisplayName
        self.raterAvatarURL = raterAvatarURL
        self.stars = stars
        self.comment = comment
        self.createdAt = createdAt
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

public enum GoodsEntryStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case active
    case keep
    case reserved
    case traded
    case archived

    public var id: String { rawValue }
}

public struct GoodsEntryInput: Equatable, Sendable {
    public var kind: GoodsEntryKind
    public var title: String
    public var groupID: UUID
    public var memberID: UUID?
    public var goodsTypeID: UUID
    public var quantity: Int
    public var status: GoodsEntryStatus?

    public init(
        kind: GoodsEntryKind,
        title: String,
        groupID: UUID,
        memberID: UUID? = nil,
        goodsTypeID: UUID,
        quantity: Int = 1,
        status: GoodsEntryStatus? = nil
    ) {
        self.kind = kind
        self.title = title
        self.groupID = groupID
        self.memberID = memberID
        self.goodsTypeID = goodsTypeID
        self.quantity = quantity
        self.status = status
    }
}

public struct GoodsEntryUpdateInput: Equatable, Sendable {
    public var title: String
    public var groupID: UUID
    public var memberID: UUID?
    public var clearsMemberID: Bool
    public var goodsTypeID: UUID
    public var quantity: Int
    public var status: GoodsEntryStatus
    public var photoURLs: [String]?

    public init(
        title: String,
        groupID: UUID,
        memberID: UUID? = nil,
        clearsMemberID: Bool = false,
        goodsTypeID: UUID,
        quantity: Int = 1,
        status: GoodsEntryStatus = .active,
        photoURLs: [String]? = nil
    ) {
        self.title = title
        self.groupID = groupID
        self.memberID = memberID
        self.clearsMemberID = clearsMemberID
        self.goodsTypeID = goodsTypeID
        self.quantity = quantity
        self.status = status
        self.photoURLs = photoURLs
    }
}

public struct GoodsSearchInput: Equatable, Sendable {
    public var query: String
    public var groupID: UUID?
    public var memberID: UUID?
    public var goodsTypeID: UUID?
    public var limit: Int

    public init(query: String, groupID: UUID? = nil, memberID: UUID? = nil, goodsTypeID: UUID? = nil, limit: Int = 60) {
        self.query = query
        self.groupID = groupID
        self.memberID = memberID
        self.goodsTypeID = goodsTypeID
        self.limit = limit
    }
}

public enum GoodsReportReason: String, Codable, Sendable, CaseIterable, Identifiable {
    case spam
    case harassment
    case fakeItem = "fake_item"
    case privacy
    case unsafe
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .spam:
            "スパム・宣伝"
        case .harassment:
            "嫌がらせ"
        case .fakeItem:
            "偽物・説明と違う"
        case .privacy:
            "個人情報が含まれる"
        case .unsafe:
            "危険・不適切"
        case .other:
            "その他"
        }
    }
}

public struct GoodsReportCreateInput: Equatable, Sendable {
    public var goodsItemID: UUID
    public var reportedUserID: UUID
    public var reason: GoodsReportReason
    public var note: String?

    public init(goodsItemID: UUID, reportedUserID: UUID, reason: GoodsReportReason, note: String? = nil) {
        self.goodsItemID = goodsItemID
        self.reportedUserID = reportedUserID
        self.reason = reason
        self.note = note
    }
}

public struct GoodsReportTicket: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var goodsItemID: UUID
    public var status: String
    public var submittedAt: Date

    public init(id: UUID, goodsItemID: UUID, status: String, submittedAt: Date = .now) {
        self.id = id
        self.goodsItemID = goodsItemID
        self.status = status
        self.submittedAt = submittedAt
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

public struct ListingItemQuantity: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID { itemID }
    public var itemID: UUID
    public var quantity: Int

    public init(itemID: UUID, quantity: Int = 1) {
        self.itemID = itemID
        self.quantity = max(1, quantity)
    }
}

public enum ListingLogic: String, Codable, Sendable, CaseIterable, Identifiable {
    case all = "and"
    case one = "or"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .all:
            "すべてほしい"
        case .one:
            "どれか1つだけ"
        }
    }
}

public enum IndividualListingStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case active
    case paused
    case matched
    case closed

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .active:
            "公開中"
        case .paused:
            "一時停止"
        case .matched:
            "成立候補あり"
        case .closed:
            "終了"
        }
    }
}

public enum IndividualListingExchangeType: String, Codable, Sendable, CaseIterable, Identifiable {
    case sameKind = "same_kind"
    case crossKind = "cross_kind"
    case any

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sameKind:
            "同種"
        case .crossKind:
            "異種"
        case .any:
            "同異種OK"
        }
    }
}

public struct IndividualListingWishOption: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var listingID: UUID
    public var position: Int
    public var wishes: [ListingItemQuantity]
    public var logic: ListingLogic
    public var exchangeType: IndividualListingExchangeType
    public var isCashOffer: Bool
    public var cashAmount: Int?
    public var wishGroupID: UUID?
    public var wishGoodsTypeID: UUID?
    public var createdAt: Date?
    public var updatedAt: Date?

    public init(
        id: UUID,
        listingID: UUID,
        position: Int,
        wishes: [ListingItemQuantity],
        logic: ListingLogic = .one,
        exchangeType: IndividualListingExchangeType = .any,
        isCashOffer: Bool = false,
        cashAmount: Int? = nil,
        wishGroupID: UUID? = nil,
        wishGoodsTypeID: UUID? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.listingID = listingID
        self.position = position
        self.wishes = wishes
        self.logic = logic
        self.exchangeType = exchangeType
        self.isCashOffer = isCashOffer
        self.cashAmount = cashAmount
        self.wishGroupID = wishGroupID
        self.wishGoodsTypeID = wishGoodsTypeID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct IndividualListing: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var ownerID: UUID
    public var haves: [ListingItemQuantity]
    public var haveLogic: ListingLogic
    public var haveGroupID: UUID?
    public var haveGoodsTypeID: UUID?
    public var status: IndividualListingStatus
    public var note: String?
    public var options: [IndividualListingWishOption]
    public var createdAt: Date?
    public var updatedAt: Date?

    public init(
        id: UUID,
        ownerID: UUID,
        haves: [ListingItemQuantity],
        haveLogic: ListingLogic = .all,
        haveGroupID: UUID? = nil,
        haveGoodsTypeID: UUID? = nil,
        status: IndividualListingStatus = .active,
        note: String? = nil,
        options: [IndividualListingWishOption] = [],
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.ownerID = ownerID
        self.haves = haves
        self.haveLogic = haveLogic
        self.haveGroupID = haveGroupID
        self.haveGoodsTypeID = haveGoodsTypeID
        self.status = status
        self.note = note
        self.options = options
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct IndividualListingCreateInput: Equatable, Sendable {
    public var haveItems: [ListingItemQuantity]
    public var haveLogic: ListingLogic
    public var wishItems: [ListingItemQuantity]
    public var wishLogic: ListingLogic
    public var exchangeType: IndividualListingExchangeType
    public var note: String?

    public init(
        haveItems: [ListingItemQuantity],
        haveLogic: ListingLogic = .all,
        wishItems: [ListingItemQuantity],
        wishLogic: ListingLogic = .one,
        exchangeType: IndividualListingExchangeType = .any,
        note: String? = nil
    ) {
        self.haveItems = haveItems
        self.haveLogic = haveLogic
        self.wishItems = wishItems
        self.wishLogic = wishLogic
        self.exchangeType = exchangeType
        self.note = note
    }
}

public enum ProposalMatchType: String, Codable, Sendable, CaseIterable, Identifiable {
    case perfect
    case forward
    case backward

    public var id: String { rawValue }
}

public struct ProposalMeetupInput: Equatable, Sendable {
    public var startAt: Date
    public var endAt: Date
    public var placeName: String
    public var latitude: Double
    public var longitude: Double

    public init(
        startAt: Date,
        endAt: Date,
        placeName: String,
        latitude: Double,
        longitude: Double
    ) {
        self.startAt = startAt
        self.endAt = endAt
        self.placeName = placeName
        self.latitude = latitude
        self.longitude = longitude
    }

    public var normalizedPlaceName: String {
        placeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var isValid: Bool {
        startAt < endAt
            && !normalizedPlaceName.isEmpty
            && latitude.isFinite
            && longitude.isFinite
            && (-90...90).contains(latitude)
            && (-180...180).contains(longitude)
    }
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
    public var meetup: ProposalMeetupInput?
    public var listingID: UUID?

    public init(
        receiverID: UUID,
        senderGoodsIDs: [UUID],
        receiverGoodsIDs: [UUID],
        exchangeMethod: ExchangeMethod = .mail,
        conditionTags: [String] = [],
        message: String? = nil,
        matchType: ProposalMatchType = .forward,
        status: ProposalStatus = .sent,
        meetup: ProposalMeetupInput? = nil,
        listingID: UUID? = nil
    ) {
        self.receiverID = receiverID
        self.senderGoodsIDs = senderGoodsIDs
        self.receiverGoodsIDs = receiverGoodsIDs
        self.exchangeMethod = exchangeMethod
        self.conditionTags = conditionTags
        self.message = message
        self.matchType = matchType
        self.status = status
        self.meetup = meetup
        self.listingID = listingID
    }

    public var requiresMeetupBeforeSending: Bool {
        status != .draft && (exchangeMethod == .hand || exchangeMethod == .both)
    }
}

public struct TradeProposal: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var senderID: UUID
    public var receiverID: UUID
    public var listingID: UUID?
    public var status: ProposalStatus
    public var exchangeMethod: ExchangeMethod
    public var senderGoodsIDs: [UUID]
    public var receiverGoodsIDs: [UUID]
    public var conditionTags: [String]
    public var agreedBySender: Bool
    public var agreedByReceiver: Bool
    public var evidencePhotoURL: URL?
    public var evidenceTakenAt: Date?
    public var evidenceTakenBy: UUID?
    public var approvedBySender: Bool
    public var approvedByReceiver: Bool
    public var completedAt: Date?
    public var createdAt: Date

    public init(
        id: UUID,
        senderID: UUID,
        receiverID: UUID,
        listingID: UUID? = nil,
        status: ProposalStatus,
        exchangeMethod: ExchangeMethod,
        senderGoodsIDs: [UUID],
        receiverGoodsIDs: [UUID],
        conditionTags: [String] = [],
        agreedBySender: Bool = false,
        agreedByReceiver: Bool = false,
        evidencePhotoURL: URL? = nil,
        evidenceTakenAt: Date? = nil,
        evidenceTakenBy: UUID? = nil,
        approvedBySender: Bool = false,
        approvedByReceiver: Bool = false,
        completedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.senderID = senderID
        self.receiverID = receiverID
        self.listingID = listingID
        self.status = status
        self.exchangeMethod = exchangeMethod
        self.senderGoodsIDs = senderGoodsIDs
        self.receiverGoodsIDs = receiverGoodsIDs
        self.conditionTags = conditionTags
        self.agreedBySender = agreedBySender
        self.agreedByReceiver = agreedByReceiver
        self.evidencePhotoURL = evidencePhotoURL
        self.evidenceTakenAt = evidenceTakenAt
        self.evidenceTakenBy = evidenceTakenBy
        self.approvedBySender = approvedBySender
        self.approvedByReceiver = approvedByReceiver
        self.completedAt = completedAt
        self.createdAt = createdAt
    }

    public func isParticipant(_ userID: UUID) -> Bool {
        senderID == userID || receiverID == userID
    }

    public func isSender(_ userID: UUID) -> Bool {
        senderID == userID
    }

    public func agreementBy(_ userID: UUID) -> Bool {
        isSender(userID) ? agreedBySender : agreedByReceiver
    }

    public func partnerAgreement(for userID: UUID) -> Bool {
        isSender(userID) ? agreedByReceiver : agreedBySender
    }

    public func approvedBy(_ userID: UUID) -> Bool {
        isSender(userID) ? approvedBySender : approvedByReceiver
    }

    public func partnerApproved(for userID: UUID) -> Bool {
        isSender(userID) ? approvedByReceiver : approvedBySender
    }

    public func partnerID(for userID: UUID) -> UUID? {
        if senderID == userID {
            return receiverID
        }
        if receiverID == userID {
            return senderID
        }
        return nil
    }

    public func goodsOffered(by userID: UUID) -> [UUID]? {
        if senderID == userID {
            return senderGoodsIDs
        }
        if receiverID == userID {
            return receiverGoodsIDs
        }
        return nil
    }

    public func goodsRequested(by userID: UUID) -> [UUID]? {
        if senderID == userID {
            return receiverGoodsIDs
        }
        if receiverID == userID {
            return senderGoodsIDs
        }
        return nil
    }

    public var allowsCounterProposal: Bool {
        [.sent, .negotiating, .agreementOneSide].contains(status)
    }

    public func canCreateCounterProposal(from userID: UUID?) -> Bool {
        guard
            let userID,
            isParticipant(userID),
            allowsCounterProposal,
            let senderGoodsIDs = goodsOffered(by: userID),
            let receiverGoodsIDs = goodsRequested(by: userID)
        else {
            return false
        }

        return !senderGoodsIDs.isEmpty && !receiverGoodsIDs.isEmpty
    }

    public func counterProposalInput(
        from userID: UUID,
        exchangeMethod: ExchangeMethod,
        conditionTags: [String],
        message: String?
    ) -> ProposalCreateInput? {
        guard
            canCreateCounterProposal(from: userID),
            let receiverID = partnerID(for: userID),
            let senderGoodsIDs = goodsOffered(by: userID),
            let receiverGoodsIDs = goodsRequested(by: userID)
        else {
            return nil
        }

        return ProposalCreateInput(
            receiverID: receiverID,
            senderGoodsIDs: senderGoodsIDs,
            receiverGoodsIDs: receiverGoodsIDs,
            exchangeMethod: exchangeMethod,
            conditionTags: conditionTags,
            message: message,
            status: .negotiating,
            listingID: listingID
        )
    }
}

public struct PersonalSchedule: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var userID: UUID
    public var title: String
    public var placeName: String?
    public var startAt: Date
    public var endAt: Date
    public var allDay: Bool
    public var note: String?

    public init(
        id: UUID,
        userID: UUID,
        title: String,
        placeName: String? = nil,
        startAt: Date,
        endAt: Date,
        allDay: Bool = false,
        note: String? = nil
    ) {
        self.id = id
        self.userID = userID
        self.title = title
        self.placeName = placeName
        self.startAt = startAt
        self.endAt = endAt
        self.allDay = allDay
        self.note = note
    }

    public var durationInterval: DateInterval {
        if endAt > startAt {
            return DateInterval(start: startAt, end: endAt)
        }
        return DateInterval(start: startAt, duration: 60)
    }

    public func overlaps(start: Date, end: Date) -> Bool {
        startAt < end && endAt > start
    }
}

public struct PersonalScheduleCreateInput: Equatable, Sendable {
    public var title: String
    public var placeName: String?
    public var startAt: Date
    public var endAt: Date
    public var allDay: Bool
    public var note: String?

    public init(
        title: String,
        placeName: String? = nil,
        startAt: Date,
        endAt: Date,
        allDay: Bool = false,
        note: String? = nil
    ) {
        self.title = title
        self.placeName = placeName
        self.startAt = startAt
        self.endAt = endAt
        self.allDay = allDay
        self.note = note
    }

    public var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var normalizedPlaceName: String? {
        placeName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
    }

    public var normalizedNote: String? {
        note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
    }

    public var isValid: Bool {
        !normalizedTitle.isEmpty && startAt < endAt
    }
}

private extension String {
    var nilIfBlank: String? {
        isEmpty ? nil : self
    }
}

public struct TradeEvidenceCreateInput: Equatable, Sendable {
    public var proposalID: UUID
    public var imageData: Data
    public var imageContentType: String

    public init(proposalID: UUID, imageData: Data, imageContentType: String) {
        self.proposalID = proposalID
        self.imageData = imageData
        self.imageContentType = imageContentType
    }
}

public struct TradeEvaluationCreateInput: Equatable, Sendable {
    public var proposalID: UUID
    public var stars: Int
    public var comment: String?

    public init(proposalID: UUID, stars: Int, comment: String? = nil) {
        self.proposalID = proposalID
        self.stars = stars
        self.comment = comment
    }
}

public enum TradeDisputeCategory: String, Codable, Sendable, CaseIterable, Identifiable {
    case short
    case wrong
    case noshow
    case cancel
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .short:
            "受け取った点数が少ない"
        case .wrong:
            "グッズが違う・状態が悪い"
        case .noshow:
            "相手が現れなかった"
        case .cancel:
            "合意済みのキャンセル"
        case .other:
            "その他"
        }
    }
}

public struct TradeDisputeCreateInput: Equatable, Sendable {
    public var proposalID: UUID
    public var category: TradeDisputeCategory
    public var factMemo: String

    public init(proposalID: UUID, category: TradeDisputeCategory, factMemo: String) {
        self.proposalID = proposalID
        self.category = category
        self.factMemo = factMemo
    }
}

public struct TradeDisputeTicket: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var proposalID: UUID
    public var ticketNo: String
    public var status: String
    public var submittedAt: Date

    public init(
        id: UUID,
        proposalID: UUID,
        ticketNo: String,
        status: String,
        submittedAt: Date = .now
    ) {
        self.id = id
        self.proposalID = proposalID
        self.ticketNo = ticketNo
        self.status = status
        self.submittedAt = submittedAt
    }
}

public enum TradeMessageType: String, Codable, Sendable, CaseIterable, Identifiable {
    case text
    case photo
    case outfitPhoto = "outfit_photo"
    case location
    case arrivalStatus = "arrival_status"
    case system

    public var id: String { rawValue }
}

public enum TradeArrivalStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case enroute
    case arrived
    case left

    public var id: String { rawValue }

    public var defaultBody: String {
        switch self {
        case .enroute:
            "向かっています"
        case .arrived:
            "到着しました"
        case .left:
            "離れました"
        }
    }
}

public struct TradeMessage: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var proposalID: UUID
    public var senderID: UUID
    public var messageType: TradeMessageType
    public var body: String?
    public var photoURL: URL?
    public var locationLatitude: Double?
    public var locationLongitude: Double?
    public var locationLabel: String?
    public var meta: [String: String]
    public var createdAt: Date

    public init(
        id: UUID,
        proposalID: UUID,
        senderID: UUID,
        messageType: TradeMessageType,
        body: String? = nil,
        photoURL: URL? = nil,
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        locationLabel: String? = nil,
        meta: [String: String] = [:],
        createdAt: Date = .now
    ) {
        self.id = id
        self.proposalID = proposalID
        self.senderID = senderID
        self.messageType = messageType
        self.body = body
        self.photoURL = photoURL
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.locationLabel = locationLabel
        self.meta = meta
        self.createdAt = createdAt
    }
}

public struct TradeMessageCreateInput: Equatable, Sendable {
    public var proposalID: UUID
    public var body: String

    public init(proposalID: UUID, body: String) {
        self.proposalID = proposalID
        self.body = body
    }
}

public struct TradePhotoMessageCreateInput: Equatable, Sendable {
    public var proposalID: UUID
    public var imageData: Data
    public var imageContentType: String
    public var messageType: TradeMessageType
    public var body: String?

    public init(
        proposalID: UUID,
        imageData: Data,
        imageContentType: String,
        messageType: TradeMessageType = .photo,
        body: String? = nil
    ) {
        self.proposalID = proposalID
        self.imageData = imageData
        self.imageContentType = imageContentType
        self.messageType = messageType
        self.body = body
    }
}

public struct GroomPost: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var authorID: UUID
    public var imageURL: URL
    public var latitude: Double
    public var longitude: Double
    public var createdAt: Date
    public var liked: Bool

    public init(
        id: UUID,
        authorID: UUID,
        imageURL: URL,
        latitude: Double,
        longitude: Double,
        createdAt: Date = .now,
        liked: Bool = false
    ) {
        self.id = id
        self.authorID = authorID
        self.imageURL = imageURL
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
        self.liked = liked
    }
}

public struct GroomPostCreateInput: Equatable, Sendable {
    public var authorID: UUID
    public var imageData: Data
    public var imageContentType: String
    public var caption: String?
    public var latitude: Double?
    public var longitude: Double?
    public var placeHint: String?

    public init(
        authorID: UUID,
        imageData: Data,
        imageContentType: String,
        caption: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        placeHint: String? = nil
    ) {
        self.authorID = authorID
        self.imageData = imageData
        self.imageContentType = imageContentType
        self.caption = caption
        self.latitude = latitude
        self.longitude = longitude
        self.placeHint = placeHint
    }
}

public struct GroomReply: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var groomPostID: UUID
    public var senderID: UUID
    public var recipientID: UUID
    public var body: String
    public var groomImageURL: URL?
    public var readAt: Date?
    public var createdAt: Date

    public init(
        id: UUID,
        groomPostID: UUID,
        senderID: UUID,
        recipientID: UUID,
        body: String,
        groomImageURL: URL? = nil,
        readAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.groomPostID = groomPostID
        self.senderID = senderID
        self.recipientID = recipientID
        self.body = body
        self.groomImageURL = groomImageURL
        self.readAt = readAt
        self.createdAt = createdAt
    }
}

public struct GroomReplyCreateInput: Equatable, Sendable {
    public var groomPostID: UUID
    public var senderID: UUID
    public var recipientID: UUID
    public var body: String
    public var groomImageURL: URL?

    public init(
        groomPostID: UUID,
        senderID: UUID,
        recipientID: UUID,
        body: String,
        groomImageURL: URL? = nil
    ) {
        self.groomPostID = groomPostID
        self.senderID = senderID
        self.recipientID = recipientID
        self.body = body
        self.groomImageURL = groomImageURL
    }
}

public enum MeguriMessageType: String, Codable, Sendable {
    case text
    case image
}

public struct MeguriMessage: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var senderID: UUID
    public var recipientID: UUID
    public var sourceGroomReplyID: UUID?
    public var messageType: MeguriMessageType
    public var body: String?
    public var imageURL: URL?
    public var imagePath: String?
    public var readAt: Date?
    public var createdAt: Date
    public var locked: Bool
    public var senderDisplayName: String?
    public var senderHandle: String?
    public var recipientDisplayName: String?
    public var recipientHandle: String?

    public init(
        id: UUID,
        senderID: UUID,
        recipientID: UUID,
        sourceGroomReplyID: UUID? = nil,
        messageType: MeguriMessageType = .text,
        body: String? = nil,
        imageURL: URL? = nil,
        imagePath: String? = nil,
        readAt: Date? = nil,
        createdAt: Date = .now,
        locked: Bool = false,
        senderDisplayName: String? = nil,
        senderHandle: String? = nil,
        recipientDisplayName: String? = nil,
        recipientHandle: String? = nil
    ) {
        self.id = id
        self.senderID = senderID
        self.recipientID = recipientID
        self.sourceGroomReplyID = sourceGroomReplyID
        self.messageType = messageType
        self.body = body
        self.imageURL = imageURL
        self.imagePath = imagePath
        self.readAt = readAt
        self.createdAt = createdAt
        self.locked = locked
        self.senderDisplayName = senderDisplayName
        self.senderHandle = senderHandle
        self.recipientDisplayName = recipientDisplayName
        self.recipientHandle = recipientHandle
    }
}

public struct MeguriMessageCreateInput: Equatable, Sendable {
    public var senderID: UUID
    public var recipientID: UUID
    public var sourceGroomReplyID: UUID?
    public var body: String

    public init(
        senderID: UUID,
        recipientID: UUID,
        sourceGroomReplyID: UUID? = nil,
        body: String
    ) {
        self.senderID = senderID
        self.recipientID = recipientID
        self.sourceGroomReplyID = sourceGroomReplyID
        self.body = body
    }
}

public struct BoardThread: Identifiable, Codable, Hashable, Sendable {
    public enum Audience: String, Codable, Sendable, CaseIterable, Identifiable {
        case nearby3km = "nearby_3km"
        case samePrefecture = "same_prefecture"
        case sameSpot = "same_spot"
        case global

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

public struct BoardThreadCreateInput: Equatable, Sendable {
    public var authorID: UUID
    public var title: String
    public var body: String
    public var audience: BoardThread.Audience
    public var latitude: Double?
    public var longitude: Double?
    public var prefecture: String?

    public init(
        authorID: UUID,
        title: String,
        body: String,
        audience: BoardThread.Audience = .nearby3km,
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil
    ) {
        self.authorID = authorID
        self.title = title
        self.body = body
        self.audience = audience
        self.latitude = latitude
        self.longitude = longitude
        self.prefecture = prefecture
    }
}

public struct BoardReply: Identifiable, Codable, Hashable, Sendable {
    public enum Status: String, Codable, Sendable, CaseIterable, Identifiable {
        case visible
        case deleted

        public var id: String { rawValue }
    }

    public var id: UUID
    public var threadID: UUID
    public var authorID: UUID
    public var body: String
    public var status: Status
    public var createdAt: Date

    public init(
        id: UUID,
        threadID: UUID,
        authorID: UUID,
        body: String,
        status: Status = .visible,
        createdAt: Date = .now
    ) {
        self.id = id
        self.threadID = threadID
        self.authorID = authorID
        self.body = body
        self.status = status
        self.createdAt = createdAt
    }
}

public struct BoardReplyCreateInput: Equatable, Sendable {
    public var threadID: UUID
    public var body: String
    public var latitude: Double?
    public var longitude: Double?
    public var prefecture: String?
    public var scope: BoardThread.Audience

    public init(
        threadID: UUID,
        body: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        prefecture: String? = nil,
        scope: BoardThread.Audience = .nearby3km
    ) {
        self.threadID = threadID
        self.body = body
        self.latitude = latitude
        self.longitude = longitude
        self.prefecture = prefecture
        self.scope = scope
    }
}
