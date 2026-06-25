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
    let client: SupabaseRESTClient

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
}
