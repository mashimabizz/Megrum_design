import Foundation

extension SupabaseHomeClient {
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

    public func makeLoadPartnerUserSummariesRequest(
        excludingUserID userID: UUID,
        limit: Int = 500
    ) throws -> URLRequest {
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

    public func makeLoadPartnerActivityWindowsRequest(
        excludingUserID userID: UUID,
        limit: Int = 500
    ) throws -> URLRequest {
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

    public func makeLoadMegrumPlusUserIDsRequest(userIDs: [UUID]) throws -> URLRequest {
        try client.makeRPCRequest(
            function: "list_megrum_plus_user_ids_for_viewer",
            payload: MegrumPlusUserIDsPayload(userIDs: userIDs)
        )
    }
}
