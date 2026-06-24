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
        async let viewerUsers = loadViewerUsers(userID: userID)
        async let viewerInventory = loadGoodsRows(queryItems: viewerTradeGoodsQueryItems(userID: userID))
        async let viewerWishes = loadGoodsRows(queryItems: viewerWishesQueryItems(userID: userID))
        async let viewerListings: [SupabaseHomeListingRow] = client.fetchRows(
            from: "listings",
            select: SupabaseHomeListingRow.select,
            queryItems: viewerListingsQueryItems(userID: userID)
        )
        async let partnerInventory = loadGoodsRows(
            queryItems: partnerTradeGoodsQueryItems(excludingUserID: userID, limit: partnerLimit)
        )
        async let partnerWishes = loadGoodsRows(
            queryItems: partnerWishesQueryItems(excludingUserID: userID, limit: partnerLimit)
        )
        async let partnerUsers = loadPartnerUsers(excludingUserID: userID, limit: partnerLimit)
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

    public func makeLoadPartnerUserSummariesRequest(excludingUserID userID: UUID, limit: Int = 500) throws -> URLRequest {
        try client.makeRPCRequest(
            function: "list_home_user_summaries_for_viewer",
            payload: HomeUserSummaryPayload(excludingUserID: userID, limit: limit)
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

    private func loadGoodsRows(queryItems: [URLQueryItem]) async throws -> [SupabaseHomeGoodsRow] {
        do {
            return try await client.fetchRows(
                from: "goods_inventory",
                select: SupabaseHomeGoodsRow.select,
                queryItems: queryItems
            )
        } catch let error as SupabaseRESTError where error == .unexpectedStatus(400) {
            return try await client.fetchRows(
                from: "goods_inventory",
                select: SupabaseHomeGoodsRow.legacySelect,
                queryItems: queryItems
            )
        }
    }

    private func loadViewerUsers(userID: UUID) async throws -> [SupabaseHomeUserRow] {
        do {
            return try await client.rpcRows(
                function: "list_home_user_summaries_for_viewer",
                payload: HomeUserSummaryPayload(userID: userID, limit: 1)
            )
        } catch let error as SupabaseRESTError where error == .unexpectedStatus(400) || error == .unexpectedStatus(404) {
            return try await loadUsersLegacy(queryItems: viewerUserQueryItems(userID: userID))
        } catch {
            throw error
        }
    }

    private func loadPartnerUsers(excludingUserID userID: UUID, limit: Int) async throws -> [SupabaseHomeUserRow] {
        do {
            return try await client.rpcRows(
                function: "list_home_user_summaries_for_viewer",
                payload: HomeUserSummaryPayload(excludingUserID: userID, limit: limit)
            )
        } catch let error as SupabaseRESTError where error == .unexpectedStatus(400) || error == .unexpectedStatus(404) {
            return try await loadUsersLegacy(queryItems: partnerUsersQueryItems(excludingUserID: userID, limit: limit))
        } catch {
            throw error
        }
    }

    private func loadUsersLegacy(queryItems: [URLQueryItem]) async throws -> [SupabaseHomeUserRow] {
        do {
            return try await client.fetchRows(
                from: "users",
                select: SupabaseHomeUserRow.select,
                queryItems: queryItems
            )
        } catch let error as SupabaseRESTError where error == .unexpectedStatus(400) {
            return try await client.fetchRows(
                from: "users",
                select: SupabaseHomeUserRow.legacySelect,
                queryItems: queryItems
            )
        }
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

private struct HomeUserSummaryPayload: Encodable, Sendable {
    var pUserId: UUID?
    var pExcludedUserId: UUID?
    var pLimit: Int

    init(userID: UUID? = nil, excludingUserID: UUID? = nil, limit: Int) {
        self.pUserId = userID
        self.pExcludedUserId = excludingUserID
        self.pLimit = max(1, min(limit, 500))
    }
}
