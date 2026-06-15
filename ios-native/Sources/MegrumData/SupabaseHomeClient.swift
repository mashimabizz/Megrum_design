import Foundation

public enum SupabaseHomeClientError: Error, Equatable, Sendable {
    case emptyIdentifierList
}

public enum SupabaseHomeCandidateBucket: String, Codable, Sendable, CaseIterable, Identifiable {
    case matched
    case possible
    case noMatch = "no_match"

    public var id: String { rawValue }
}

public struct SupabaseHomeComposition: Equatable, Sendable {
    public var localMode: SupabaseHomeLocalModeRow?
    public var viewerUser: SupabaseHomeUserRow?
    public var viewerInventory: [SupabaseHomeGoodsRow]
    public var viewerWishes: [SupabaseHomeGoodsRow]
    public var viewerListings: [SupabaseHomeListingRow]
    public var partnerInventory: [SupabaseHomeGoodsRow]
    public var partnerWishes: [SupabaseHomeGoodsRow]
    public var partnerUsers: [SupabaseHomeUserRow]
    public var partnerListings: [SupabaseHomeListingRow]
    public var listingWishOptions: [SupabaseHomeListingWishOptionRow]
    public var viewerActivityWindows: [SupabaseHomeActivityWindowRow]
    public var partnerActivityWindows: [SupabaseHomeActivityWindowRow]
    public var inventoryTags: [SupabaseHomeInventoryTagRow]
    public var unreadNotificationIDs: [UUID]

    public init(
        localMode: SupabaseHomeLocalModeRow?,
        viewerUser: SupabaseHomeUserRow? = nil,
        viewerInventory: [SupabaseHomeGoodsRow],
        viewerWishes: [SupabaseHomeGoodsRow],
        viewerListings: [SupabaseHomeListingRow],
        partnerInventory: [SupabaseHomeGoodsRow],
        partnerWishes: [SupabaseHomeGoodsRow],
        partnerUsers: [SupabaseHomeUserRow],
        partnerListings: [SupabaseHomeListingRow],
        listingWishOptions: [SupabaseHomeListingWishOptionRow],
        viewerActivityWindows: [SupabaseHomeActivityWindowRow],
        partnerActivityWindows: [SupabaseHomeActivityWindowRow],
        inventoryTags: [SupabaseHomeInventoryTagRow],
        unreadNotificationIDs: [UUID]
    ) {
        self.localMode = localMode
        self.viewerUser = viewerUser
        self.viewerInventory = viewerInventory
        self.viewerWishes = viewerWishes
        self.viewerListings = viewerListings
        self.partnerInventory = partnerInventory
        self.partnerWishes = partnerWishes
        self.partnerUsers = partnerUsers
        self.partnerListings = partnerListings
        self.listingWishOptions = listingWishOptions
        self.viewerActivityWindows = viewerActivityWindows
        self.partnerActivityWindows = partnerActivityWindows
        self.inventoryTags = inventoryTags
        self.unreadNotificationIDs = unreadNotificationIDs
    }

    public var unreadNotificationCount: Int {
        unreadNotificationIDs.count
    }
}

public struct SupabaseHomeLocalModeRow: Decodable, Equatable, Sendable {
    public var userId: UUID?
    public var enabled: Bool?
    public var awId: UUID?
    public var radiusM: Int?
    public var selectedCarryingIds: [UUID]?
    public var selectedWishIds: [UUID]?
    public var lastLat: Double?
    public var lastLng: Double?
    public var updatedAt: Date?

    enum CodingKeys: CodingKey {
        case userId
        case enabled
        case awId
        case radiusM
        case selectedCarryingIds
        case selectedWishIds
        case lastLat
        case lastLng
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)
        self.awId = try container.decodeIfPresent(UUID.self, forKey: .awId)
        self.radiusM = try container.decodeIfPresent(Int.self, forKey: .radiusM)
        self.selectedCarryingIds = try container.decodeIfPresent([UUID].self, forKey: .selectedCarryingIds)
        self.selectedWishIds = try container.decodeIfPresent([UUID].self, forKey: .selectedWishIds)
        self.lastLat = try container.decodeIfPresent(SupabaseHomeFlexibleDouble.self, forKey: .lastLat)?.value
        self.lastLng = try container.decodeIfPresent(SupabaseHomeFlexibleDouble.self, forKey: .lastLng)?.value
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

public struct SupabaseHomeGoodsRow: Decodable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var userId: UUID
    public var kind: String?
    public var groupId: UUID?
    public var characterId: UUID?
    public var characterRequestId: UUID?
    public var goodsTypeId: UUID?
    public var title: String
    public var photoUrls: [String]
    public var quantity: Int?
    public var lockedQty: Int?
    public var marketAvailableQty: Int?
    public var exchangeType: String?
    public var hue: String?
    public var status: String?
    public var groupName: String?
    public var characterName: String?
    public var goodsTypeName: String?
    public var updatedAt: Date?

    enum CodingKeys: CodingKey {
        case id
        case userId
        case kind
        case groupId
        case characterId
        case characterRequestId
        case goodsTypeId
        case title
        case photoUrls
        case quantity
        case lockedQty
        case marketAvailableQty
        case exchangeType
        case hue
        case status
        case group
        case character
        case goodsType
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.userId = try container.decode(UUID.self, forKey: .userId)
        self.kind = try container.decodeIfPresent(String.self, forKey: .kind)
        self.groupId = try container.decodeIfPresent(UUID.self, forKey: .groupId)
        self.characterId = try container.decodeIfPresent(UUID.self, forKey: .characterId)
        self.characterRequestId = try container.decodeIfPresent(UUID.self, forKey: .characterRequestId)
        self.goodsTypeId = try container.decodeIfPresent(UUID.self, forKey: .goodsTypeId)
        self.title = try container.decode(String.self, forKey: .title)
        self.photoUrls = try container.decodeIfPresent([String].self, forKey: .photoUrls) ?? []
        self.quantity = try container.decodeIfPresent(Int.self, forKey: .quantity)
        self.lockedQty = try container.decodeIfPresent(Int.self, forKey: .lockedQty)
        self.marketAvailableQty = try container.decodeIfPresent(Int.self, forKey: .marketAvailableQty)
        self.exchangeType = try container.decodeIfPresent(String.self, forKey: .exchangeType)
        self.hue = try container.decodeIfPresent(SupabaseHomeFlexibleString.self, forKey: .hue)?.value
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
        self.groupName = try container.decodeIfPresent(SupabaseHomeRelation.self, forKey: .group)?.name
        self.characterName = try container.decodeIfPresent(SupabaseHomeRelation.self, forKey: .character)?.name
        self.goodsTypeName = try container.decodeIfPresent(SupabaseHomeRelation.self, forKey: .goodsType)?.name
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

public struct SupabaseHomeUserRow: Decodable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var handle: String?
    public var displayName: String?
    public var primaryArea: String?
    public var avatarUrl: String?
    public var paymentMethods: [String]
    public var paymentNote: String?

    enum CodingKeys: CodingKey {
        case id
        case handle
        case displayName
        case primaryArea
        case avatarUrl
        case paymentMethods
        case paymentNote
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.handle = try container.decodeIfPresent(String.self, forKey: .handle)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        self.primaryArea = try container.decodeIfPresent(String.self, forKey: .primaryArea)
        self.avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        self.paymentMethods = try container.decodeIfPresent([String].self, forKey: .paymentMethods) ?? []
        self.paymentNote = try container.decodeIfPresent(String.self, forKey: .paymentNote)
    }
}

public struct SupabaseHomeListingRow: Decodable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var userId: UUID
    public var haveIds: [UUID]
    public var haveQtys: [Int]
    public var haveLogic: String?
    public var haveGroupId: UUID?
    public var haveGoodsTypeId: UUID?
    public var status: String?
    public var note: String?
    public var createdAt: Date?
    public var updatedAt: Date?

    enum CodingKeys: CodingKey {
        case id
        case userId
        case haveIds
        case haveQtys
        case haveLogic
        case haveGroupId
        case haveGoodsTypeId
        case status
        case note
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.userId = try container.decode(UUID.self, forKey: .userId)
        self.haveIds = try container.decodeIfPresent([UUID].self, forKey: .haveIds) ?? []
        self.haveQtys = try container.decodeIfPresent([Int].self, forKey: .haveQtys) ?? []
        self.haveLogic = try container.decodeIfPresent(String.self, forKey: .haveLogic)
        self.haveGroupId = try container.decodeIfPresent(UUID.self, forKey: .haveGroupId)
        self.haveGoodsTypeId = try container.decodeIfPresent(UUID.self, forKey: .haveGoodsTypeId)
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
        self.note = try container.decodeIfPresent(String.self, forKey: .note)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

public struct SupabaseHomeListingWishOptionRow: Decodable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var listingId: UUID
    public var position: Int
    public var wishIds: [UUID]
    public var wishQtys: [Int]
    public var logic: String?
    public var exchangeType: String?
    public var isCashOffer: Bool?
    public var cashAmount: Int?
    public var wishGroupId: UUID?
    public var wishGoodsTypeId: UUID?
    public var createdAt: Date?
    public var updatedAt: Date?

    enum CodingKeys: CodingKey {
        case id
        case listingId
        case position
        case wishIds
        case wishQtys
        case logic
        case exchangeType
        case isCashOffer
        case cashAmount
        case wishGroupId
        case wishGoodsTypeId
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.listingId = try container.decode(UUID.self, forKey: .listingId)
        self.position = try container.decode(Int.self, forKey: .position)
        self.wishIds = try container.decodeIfPresent([UUID].self, forKey: .wishIds) ?? []
        self.wishQtys = try container.decodeIfPresent([Int].self, forKey: .wishQtys) ?? []
        self.logic = try container.decodeIfPresent(String.self, forKey: .logic)
        self.exchangeType = try container.decodeIfPresent(String.self, forKey: .exchangeType)
        self.isCashOffer = try container.decodeIfPresent(Bool.self, forKey: .isCashOffer)
        self.cashAmount = try container.decodeIfPresent(Int.self, forKey: .cashAmount)
        self.wishGroupId = try container.decodeIfPresent(UUID.self, forKey: .wishGroupId)
        self.wishGoodsTypeId = try container.decodeIfPresent(UUID.self, forKey: .wishGoodsTypeId)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

public struct SupabaseHomeActivityWindowRow: Decodable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var userId: UUID
    public var venue: String?
    public var startAt: Date
    public var endAt: Date
    public var radiusM: Int?
    public var centerLat: Double?
    public var centerLng: Double?
    public var status: String?

    enum CodingKeys: CodingKey {
        case id
        case userId
        case venue
        case startAt
        case endAt
        case radiusM
        case centerLat
        case centerLng
        case status
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.userId = try container.decode(UUID.self, forKey: .userId)
        self.venue = try container.decodeIfPresent(String.self, forKey: .venue)
        self.startAt = try container.decode(Date.self, forKey: .startAt)
        self.endAt = try container.decode(Date.self, forKey: .endAt)
        self.radiusM = try container.decodeIfPresent(Int.self, forKey: .radiusM)
        self.centerLat = try container.decodeIfPresent(SupabaseHomeFlexibleDouble.self, forKey: .centerLat)?.value
        self.centerLng = try container.decodeIfPresent(SupabaseHomeFlexibleDouble.self, forKey: .centerLng)?.value
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
    }
}

public struct SupabaseHomeInventoryTagRow: Decodable, Equatable, Sendable {
    public var inventoryId: UUID
    public var tagId: UUID
    public var label: String?

    enum CodingKeys: CodingKey {
        case inventoryId
        case tagId
        case tag
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.inventoryId = try container.decode(UUID.self, forKey: .inventoryId)
        self.tagId = try container.decode(UUID.self, forKey: .tagId)
        self.label = try container.decodeIfPresent(SupabaseHomeRelation.self, forKey: .tag)?.name
    }
}

public struct SupabaseHomeNotificationIDRow: Decodable, Equatable, Sendable, Identifiable {
    public var id: UUID
}

public final class SupabaseHomeClient: @unchecked Sendable {
    private let client: SupabaseRESTClient

    public init(configuration: SupabaseConfiguration, session: URLSession = .shared) {
        self.client = SupabaseRESTClient(configuration: configuration, session: session)
    }

    public init(client: SupabaseRESTClient) {
        self.client = client
    }

    public func loadHomeComposition(userID: UUID, partnerLimit: Int = 500) async throws -> SupabaseHomeComposition {
        async let localModeRows: [SupabaseHomeLocalModeRow] = client.fetchRows(
            from: "user_local_mode_settings",
            select: SupabaseHomeLocalModeRow.select,
            queryItems: localModeQueryItems(userID: userID)
        )
        async let viewerUsers: [SupabaseHomeUserRow] = client.fetchRows(
            from: "users",
            select: SupabaseHomeUserRow.select,
            queryItems: viewerUserQueryItems(userID: userID)
        )
        async let viewerInventory: [SupabaseHomeGoodsRow] = client.fetchRows(
            from: "goods_inventory",
            select: SupabaseHomeGoodsRow.select,
            queryItems: viewerTradeGoodsQueryItems(userID: userID)
        )
        async let viewerWishes: [SupabaseHomeGoodsRow] = client.fetchRows(
            from: "goods_inventory",
            select: SupabaseHomeGoodsRow.select,
            queryItems: viewerWishesQueryItems(userID: userID)
        )
        async let viewerListings: [SupabaseHomeListingRow] = client.fetchRows(
            from: "listings",
            select: SupabaseHomeListingRow.select,
            queryItems: viewerListingsQueryItems(userID: userID)
        )
        async let partnerInventory: [SupabaseHomeGoodsRow] = client.fetchRows(
            from: "goods_inventory",
            select: SupabaseHomeGoodsRow.select,
            queryItems: partnerTradeGoodsQueryItems(excludingUserID: userID, limit: partnerLimit)
        )
        async let partnerWishes: [SupabaseHomeGoodsRow] = client.fetchRows(
            from: "goods_inventory",
            select: SupabaseHomeGoodsRow.select,
            queryItems: partnerWishesQueryItems(excludingUserID: userID, limit: partnerLimit)
        )
        async let partnerUsers: [SupabaseHomeUserRow] = client.fetchRows(
            from: "users",
            select: SupabaseHomeUserRow.select,
            queryItems: partnerUsersQueryItems(excludingUserID: userID, limit: partnerLimit)
        )
        async let partnerListings: [SupabaseHomeListingRow] = client.fetchRows(
            from: "listings",
            select: SupabaseHomeListingRow.select,
            queryItems: partnerListingsQueryItems(excludingUserID: userID, limit: partnerLimit)
        )
        async let viewerActivityWindows: [SupabaseHomeActivityWindowRow] = client.fetchRows(
            from: "activity_windows",
            select: SupabaseHomeActivityWindowRow.select,
            queryItems: viewerActivityWindowsQueryItems(userID: userID)
        )
        async let partnerActivityWindows: [SupabaseHomeActivityWindowRow] = client.fetchRows(
            from: "activity_windows",
            select: SupabaseHomeActivityWindowRow.select,
            queryItems: partnerActivityWindowsQueryItems(excludingUserID: userID, limit: partnerLimit)
        )
        async let unreadNotificationIDs: [SupabaseHomeNotificationIDRow] = client.fetchRows(
            from: "notifications",
            select: SupabaseHomeNotificationIDRow.select,
            queryItems: unreadNotificationsQueryItems(userID: userID, limit: 1_000)
        )

        let initialRows = try await (
            localModeRows,
            viewerUsers,
            viewerInventory,
            viewerWishes,
            viewerListings,
            partnerInventory,
            partnerWishes,
            partnerUsers,
            partnerListings,
            viewerActivityWindows,
            partnerActivityWindows,
            unreadNotificationIDs
        )

        async let listingWishOptions = loadListingWishOptionsIfNeeded(
            listingIDs: (initialRows.4 + initialRows.8).map(\.id)
        )
        async let inventoryTags = loadInventoryTagsIfNeeded(
            inventoryIDs: (initialRows.2 + initialRows.3 + initialRows.5 + initialRows.6).map(\.id)
        )

        return try await SupabaseHomeComposition(
            localMode: initialRows.0.first,
            viewerUser: initialRows.1.first,
            viewerInventory: initialRows.2,
            viewerWishes: initialRows.3,
            viewerListings: initialRows.4,
            partnerInventory: initialRows.5,
            partnerWishes: initialRows.6,
            partnerUsers: initialRows.7,
            partnerListings: initialRows.8,
            listingWishOptions: listingWishOptions,
            viewerActivityWindows: initialRows.9,
            partnerActivityWindows: initialRows.10,
            inventoryTags: inventoryTags,
            unreadNotificationIDs: initialRows.11.map(\.id)
        )
    }

    public func makeLoadLocalModeRequest(userID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/user_local_mode_settings",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeLocalModeRow.select)]
                + localModeQueryItems(userID: userID)
        )
    }

    public func makeLoadViewerTradeGoodsRequest(userID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/goods_inventory",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeGoodsRow.select)]
                + viewerTradeGoodsQueryItems(userID: userID)
        )
    }

    public func makeLoadViewerWishesRequest(userID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/goods_inventory",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeGoodsRow.select)]
                + viewerWishesQueryItems(userID: userID)
        )
    }

    public func makeLoadPartnerTradeGoodsRequest(excludingUserID userID: UUID, limit: Int = 500) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/goods_inventory",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeGoodsRow.select)]
                + partnerTradeGoodsQueryItems(excludingUserID: userID, limit: limit)
        )
    }

    public func makeLoadPartnerWishesRequest(excludingUserID userID: UUID, limit: Int = 500) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/goods_inventory",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeGoodsRow.select)]
                + partnerWishesQueryItems(excludingUserID: userID, limit: limit)
        )
    }

    public func makeLoadPartnerUsersRequest(excludingUserID userID: UUID, limit: Int = 500) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/users",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeUserRow.select)]
                + partnerUsersQueryItems(excludingUserID: userID, limit: limit)
        )
    }

    public func makeLoadViewerListingsRequest(userID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/listings",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeListingRow.select)]
                + viewerListingsQueryItems(userID: userID)
        )
    }

    public func makeLoadPartnerListingsRequest(excludingUserID userID: UUID, limit: Int = 500) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/listings",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeListingRow.select)]
                + partnerListingsQueryItems(excludingUserID: userID, limit: limit)
        )
    }

    public func makeLoadListingWishOptionsRequest(listingIDs: [UUID]) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/listing_wish_options",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeListingWishOptionRow.select)]
                + listingWishOptionsQueryItems(listingIDs: listingIDs)
        )
    }

    public func makeLoadViewerActivityWindowsRequest(userID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/activity_windows",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeActivityWindowRow.select)]
                + viewerActivityWindowsQueryItems(userID: userID)
        )
    }

    public func makeLoadPartnerActivityWindowsRequest(excludingUserID userID: UUID, limit: Int = 500) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/activity_windows",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeActivityWindowRow.select)]
                + partnerActivityWindowsQueryItems(excludingUserID: userID, limit: limit)
        )
    }

    public func makeLoadInventoryTagsRequest(inventoryIDs: [UUID]) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/goods_inventory_tags",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeInventoryTagRow.select)]
                + inventoryTagsQueryItems(inventoryIDs: inventoryIDs)
        )
    }

    public func makeLoadUnreadNotificationsRequest(userID: UUID, limit: Int = 1_000) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/notifications",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeNotificationIDRow.select)]
                + unreadNotificationsQueryItems(userID: userID, limit: limit)
        )
    }

    private func loadListingWishOptionsIfNeeded(listingIDs: [UUID]) async throws -> [SupabaseHomeListingWishOptionRow] {
        guard !listingIDs.isEmpty else {
            return []
        }
        return try await client.fetchRows(
            from: "listing_wish_options",
            select: SupabaseHomeListingWishOptionRow.select,
            queryItems: try listingWishOptionsQueryItems(listingIDs: listingIDs)
        )
    }

    private func loadInventoryTagsIfNeeded(inventoryIDs: [UUID]) async throws -> [SupabaseHomeInventoryTagRow] {
        guard !inventoryIDs.isEmpty else {
            return []
        }
        return try await client.fetchRows(
            from: "goods_inventory_tags",
            select: SupabaseHomeInventoryTagRow.select,
            queryItems: try inventoryTagsQueryItems(inventoryIDs: inventoryIDs)
        )
    }

    private func localModeQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.lowercaseString)"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    private func viewerUserQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(userID.lowercaseString)"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    private func viewerTradeGoodsQueryItems(userID: UUID) -> [URLQueryItem] {
        goodsQueryItems(userID: userID, userFilter: "eq", kind: "for_trade", statusFilter: "eq.active")
    }

    private func viewerWishesQueryItems(userID: UUID) -> [URLQueryItem] {
        goodsQueryItems(userID: userID, userFilter: "eq", kind: "wanted", statusFilter: "neq.archived")
    }

    private func partnerTradeGoodsQueryItems(excludingUserID userID: UUID, limit: Int) -> [URLQueryItem] {
        goodsQueryItems(
            userID: userID,
            userFilter: "neq",
            kind: "for_trade",
            statusFilter: "eq.active",
            limit: limit
        )
    }

    private func partnerWishesQueryItems(excludingUserID userID: UUID, limit: Int) -> [URLQueryItem] {
        goodsQueryItems(
            userID: userID,
            userFilter: "neq",
            kind: "wanted",
            statusFilter: "neq.archived",
            limit: limit
        )
    }

    private func goodsQueryItems(
        userID: UUID,
        userFilter: String,
        kind: String,
        statusFilter: String,
        limit: Int? = nil
    ) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: "user_id", value: "\(userFilter).\(userID.lowercaseString)"),
            URLQueryItem(name: "kind", value: "eq.\(kind)"),
            URLQueryItem(name: "status", value: statusFilter)
        ]
        if let limit {
            queryItems.append(URLQueryItem(name: "limit", value: "\(boundedLimit(limit))"))
        }
        return queryItems
    }

    private func partnerUsersQueryItems(excludingUserID userID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "neq.\(userID.lowercaseString)"),
            URLQueryItem(name: "limit", value: "\(boundedLimit(limit))")
        ]
    }

    private func viewerListingsQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.lowercaseString)"),
            URLQueryItem(name: "status", value: "eq.active")
        ]
    }

    private func partnerListingsQueryItems(excludingUserID userID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "neq.\(userID.lowercaseString)"),
            URLQueryItem(name: "status", value: "eq.active"),
            URLQueryItem(name: "limit", value: "\(boundedLimit(limit))")
        ]
    }

    private func listingWishOptionsQueryItems(listingIDs: [UUID]) throws -> [URLQueryItem] {
        [
            URLQueryItem(name: "listing_id", value: try uuidInFilter(listingIDs)),
            URLQueryItem(name: "order", value: "position.asc")
        ]
    }

    private func viewerActivityWindowsQueryItems(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.lowercaseString)"),
            URLQueryItem(name: "status", value: "eq.enabled")
        ]
    }

    private func partnerActivityWindowsQueryItems(excludingUserID userID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "neq.\(userID.lowercaseString)"),
            URLQueryItem(name: "status", value: "eq.enabled"),
            URLQueryItem(name: "limit", value: "\(boundedLimit(limit))")
        ]
    }

    private func inventoryTagsQueryItems(inventoryIDs: [UUID]) throws -> [URLQueryItem] {
        [
            URLQueryItem(name: "inventory_id", value: try uuidInFilter(inventoryIDs))
        ]
    }

    private func unreadNotificationsQueryItems(userID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.lowercaseString)"),
            URLQueryItem(name: "read_at", value: "is.null"),
            URLQueryItem(name: "limit", value: "\(boundedLimit(limit, upperBound: 1_000))")
        ]
    }

    private func uuidInFilter(_ ids: [UUID]) throws -> String {
        let values = ids.uniqueLowercaseStrings()
        guard !values.isEmpty else {
            throw SupabaseHomeClientError.emptyIdentifierList
        }
        return "in.(\(values.joined(separator: ",")))"
    }

    private func boundedLimit(_ limit: Int, upperBound: Int = 500) -> Int {
        max(1, min(limit, upperBound))
    }
}

extension SupabaseHomeLocalModeRow {
    static let select = "user_id,enabled,aw_id,radius_m,selected_carrying_ids,selected_wish_ids,last_lat,last_lng,updated_at"
}

extension SupabaseHomeGoodsRow {
    static let select = "id,user_id,kind,group_id,character_id,character_request_id,goods_type_id,title,photo_urls,quantity,locked_qty,market_available_qty,exchange_type,hue,status,group:groups_master(name),character:characters_master(name),goods_type:goods_types_master(name),updated_at"
}

extension SupabaseHomeUserRow {
    static let select = "id,handle,display_name,primary_area,avatar_url,payment_methods,payment_note"
}

extension SupabaseHomeListingRow {
    static let select = "id,user_id,have_ids,have_qtys,have_logic,have_group_id,have_goods_type_id,status,note,created_at,updated_at"
}

extension SupabaseHomeListingWishOptionRow {
    static let select = "id,listing_id,position,wish_ids,wish_qtys,logic,exchange_type,is_cash_offer,cash_amount,wish_group_id,wish_goods_type_id,created_at,updated_at"
}

extension SupabaseHomeActivityWindowRow {
    static let select = "id,user_id,venue,start_at,end_at,radius_m,center_lat,center_lng,status"
}

extension SupabaseHomeInventoryTagRow {
    static let select = "inventory_id,tag_id,tag:tags_master(label)"
}

extension SupabaseHomeNotificationIDRow {
    static let select = "id"
}

private struct SupabaseHomeRelation: Decodable, Equatable, Sendable {
    var name: String?

    enum CodingKeys: CodingKey {
        case name
        case label
    }

    init(from decoder: Decoder) throws {
        if var unkeyed = try? decoder.unkeyedContainer() {
            self = try unkeyed.decodeIfPresent(SupabaseHomeRelation.self) ?? SupabaseHomeRelation(name: nil)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
            ?? container.decodeIfPresent(String.self, forKey: .label)
    }

    init(name: String?) {
        self.name = name
    }
}

private struct SupabaseHomeFlexibleDouble: Decodable, Equatable, Sendable {
    var value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Double.self) {
            self.value = value
            return
        }
        let rawValue = try container.decode(String.self)
        guard let value = Double(rawValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected a Double-compatible value"
            )
        }
        self.value = value
    }
}

private struct SupabaseHomeFlexibleString: Decodable, Equatable, Sendable {
    var value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self.value = value
            return
        }
        if let value = try? container.decode(Int.self) {
            self.value = "\(value)"
            return
        }
        let value = try container.decode(Double.self)
        self.value = "\(value)"
    }
}

private extension UUID {
    var lowercaseString: String {
        uuidString.lowercased()
    }
}

private extension Array where Element == UUID {
    func uniqueLowercaseStrings() -> [String] {
        var seen = Set<UUID>()
        return filter { seen.insert($0).inserted }.map(\.lowercaseString)
    }
}
