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
            queryItems: SupabaseHomeQueryItems.localMode(userID: userID)
        )
        async let viewerUsers = loadViewerUsers(userID: userID)
        async let viewerInventory = loadGoodsRows(queryItems: SupabaseHomeQueryItems.viewerTradeGoods(userID: userID))
        async let viewerWishes = loadGoodsRows(queryItems: SupabaseHomeQueryItems.viewerWishes(userID: userID))
        async let viewerListings: [SupabaseHomeListingRow] = client.fetchRows(
            from: "listings",
            select: SupabaseHomeListingRow.select,
            queryItems: SupabaseHomeQueryItems.viewerListings(userID: userID)
        )
        async let partnerInventory = loadGoodsRows(
            queryItems: SupabaseHomeQueryItems.partnerTradeGoods(excludingUserID: userID, limit: partnerLimit)
        )
        async let partnerWishes = loadGoodsRows(
            queryItems: SupabaseHomeQueryItems.partnerWishes(excludingUserID: userID, limit: partnerLimit)
        )
        async let partnerUsers = loadPartnerUsers(excludingUserID: userID, limit: partnerLimit)
        async let partnerListings: [SupabaseHomeListingRow] = client.fetchRows(
            from: "listings",
            select: SupabaseHomeListingRow.select,
            queryItems: SupabaseHomeQueryItems.partnerListings(excludingUserID: userID, limit: partnerLimit)
        )
        async let viewerActivityWindows: [SupabaseHomeActivityWindowRow] = client.fetchRows(
            from: "activity_windows",
            select: SupabaseHomeActivityWindowRow.select,
            queryItems: SupabaseHomeQueryItems.viewerActivityWindows(userID: userID)
        )
        async let partnerActivityWindows: [SupabaseHomeActivityWindowRow] = client.fetchRows(
            from: "activity_windows",
            select: SupabaseHomeActivityWindowRow.select,
            queryItems: SupabaseHomeQueryItems.partnerActivityWindows(excludingUserID: userID, limit: partnerLimit)
        )
        async let unreadNotificationIDs: [SupabaseHomeNotificationIDRow] = client.fetchRows(
            from: "notifications",
            select: SupabaseHomeNotificationIDRow.select,
            queryItems: SupabaseHomeQueryItems.unreadNotifications(userID: userID, limit: 1_000)
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
                + SupabaseHomeQueryItems.localMode(userID: userID)
        )
    }

    public func makeLoadViewerTradeGoodsRequest(userID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/goods_inventory",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeGoodsRow.select)]
                + SupabaseHomeQueryItems.viewerTradeGoods(userID: userID)
        )
    }

    public func makeLoadViewerWishesRequest(userID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/goods_inventory",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeGoodsRow.select)]
                + SupabaseHomeQueryItems.viewerWishes(userID: userID)
        )
    }

    public func makeLoadPartnerTradeGoodsRequest(excludingUserID userID: UUID, limit: Int = 500) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/goods_inventory",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeGoodsRow.select)]
                + SupabaseHomeQueryItems.partnerTradeGoods(excludingUserID: userID, limit: limit)
        )
    }

    public func makeLoadPartnerWishesRequest(excludingUserID userID: UUID, limit: Int = 500) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/goods_inventory",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeGoodsRow.select)]
                + SupabaseHomeQueryItems.partnerWishes(excludingUserID: userID, limit: limit)
        )
    }

    public func makeLoadPartnerUsersRequest(excludingUserID userID: UUID, limit: Int = 500) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/users",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeUserRow.select)]
                + SupabaseHomeQueryItems.partnerUsers(excludingUserID: userID, limit: limit)
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
                + SupabaseHomeQueryItems.viewerListings(userID: userID)
        )
    }

    public func makeLoadPartnerListingsRequest(excludingUserID userID: UUID, limit: Int = 500) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/listings",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeListingRow.select)]
                + SupabaseHomeQueryItems.partnerListings(excludingUserID: userID, limit: limit)
        )
    }

    public func makeLoadListingWishOptionsRequest(listingIDs: [UUID]) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/listing_wish_options",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeListingWishOptionRow.select)]
                + SupabaseHomeQueryItems.listingWishOptions(listingIDs: listingIDs)
        )
    }

    public func makeLoadViewerActivityWindowsRequest(userID: UUID) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/activity_windows",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeActivityWindowRow.select)]
                + SupabaseHomeQueryItems.viewerActivityWindows(userID: userID)
        )
    }

    public func makeLoadPartnerActivityWindowsRequest(excludingUserID userID: UUID, limit: Int = 500) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/activity_windows",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeActivityWindowRow.select)]
                + SupabaseHomeQueryItems.partnerActivityWindows(excludingUserID: userID, limit: limit)
        )
    }

    public func makeLoadInventoryTagsRequest(inventoryIDs: [UUID]) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/goods_inventory_tags",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeInventoryTagRow.select)]
                + SupabaseHomeQueryItems.inventoryTags(inventoryIDs: inventoryIDs)
        )
    }

    public func makeLoadUnreadNotificationsRequest(userID: UUID, limit: Int = 1_000) throws -> URLRequest {
        try client.makeRequest(
            path: "/rest/v1/notifications",
            queryItems: [URLQueryItem(name: "select", value: SupabaseHomeNotificationIDRow.select)]
                + SupabaseHomeQueryItems.unreadNotifications(userID: userID, limit: limit)
        )
    }

    private func loadListingWishOptionsIfNeeded(listingIDs: [UUID]) async throws -> [SupabaseHomeListingWishOptionRow] {
        guard !listingIDs.isEmpty else {
            return []
        }
        return try await client.fetchRows(
            from: "listing_wish_options",
            select: SupabaseHomeListingWishOptionRow.select,
            queryItems: try SupabaseHomeQueryItems.listingWishOptions(listingIDs: listingIDs)
        )
    }

    private func loadInventoryTagsIfNeeded(inventoryIDs: [UUID]) async throws -> [SupabaseHomeInventoryTagRow] {
        guard !inventoryIDs.isEmpty else {
            return []
        }
        return try await client.fetchRows(
            from: "goods_inventory_tags",
            select: SupabaseHomeInventoryTagRow.select,
            queryItems: try SupabaseHomeQueryItems.inventoryTags(inventoryIDs: inventoryIDs)
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
            return try await loadUsersLegacy(queryItems: SupabaseHomeQueryItems.viewerUser(userID: userID))
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
            return try await loadUsersLegacy(
                queryItems: SupabaseHomeQueryItems.partnerUsers(excludingUserID: userID, limit: limit)
            )
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

}
