import Foundation

enum SupabaseHomeQueryItems {
    static func localMode(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.lowercaseString)"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    static func viewerUser(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "eq.\(userID.lowercaseString)"),
            URLQueryItem(name: "limit", value: "1")
        ]
    }

    static func viewerTradeGoods(userID: UUID) -> [URLQueryItem] {
        goods(userID: userID, userFilter: "eq", kind: "for_trade", statusFilter: "eq.active")
    }

    static func viewerWishes(userID: UUID) -> [URLQueryItem] {
        goods(userID: userID, userFilter: "eq", kind: "wanted", statusFilter: "neq.archived")
    }

    static func partnerTradeGoods(excludingUserID userID: UUID, limit: Int) -> [URLQueryItem] {
        goods(
            userID: userID,
            userFilter: "neq",
            kind: "for_trade",
            statusFilter: "eq.active",
            limit: limit
        )
    }

    static func partnerWishes(excludingUserID userID: UUID, limit: Int) -> [URLQueryItem] {
        goods(
            userID: userID,
            userFilter: "neq",
            kind: "wanted",
            statusFilter: "neq.archived",
            limit: limit
        )
    }

    static func partnerUsers(excludingUserID userID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "id", value: "neq.\(userID.lowercaseString)"),
            URLQueryItem(name: "limit", value: "\(boundedLimit(limit))")
        ]
    }

    static func viewerListings(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.lowercaseString)"),
            URLQueryItem(name: "status", value: "eq.active")
        ]
    }

    static func partnerListings(excludingUserID userID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "neq.\(userID.lowercaseString)"),
            URLQueryItem(name: "status", value: "eq.active"),
            URLQueryItem(name: "limit", value: "\(boundedLimit(limit))")
        ]
    }

    static func listingWishOptions(listingIDs: [UUID]) throws -> [URLQueryItem] {
        [
            URLQueryItem(name: "listing_id", value: try uuidInFilter(listingIDs)),
            URLQueryItem(name: "order", value: "position.asc")
        ]
    }

    static func viewerActivityWindows(userID: UUID) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.lowercaseString)"),
            URLQueryItem(name: "status", value: "eq.enabled")
        ]
    }

    static func partnerActivityWindows(excludingUserID userID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "neq.\(userID.lowercaseString)"),
            URLQueryItem(name: "status", value: "eq.enabled"),
            URLQueryItem(name: "limit", value: "\(boundedLimit(limit))")
        ]
    }

    static func inventoryTags(inventoryIDs: [UUID]) throws -> [URLQueryItem] {
        [
            URLQueryItem(name: "inventory_id", value: try uuidInFilter(inventoryIDs))
        ]
    }

    static func unreadNotifications(userID: UUID, limit: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "user_id", value: "eq.\(userID.lowercaseString)"),
            URLQueryItem(name: "read_at", value: "is.null"),
            URLQueryItem(name: "limit", value: "\(boundedLimit(limit, upperBound: 1_000))")
        ]
    }

    static func boundedLimit(_ limit: Int, upperBound: Int = 500) -> Int {
        max(1, min(limit, upperBound))
    }

    private static func goods(
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

    private static func uuidInFilter(_ ids: [UUID]) throws -> String {
        let values = ids.uniqueLowercaseStrings()
        guard !values.isEmpty else {
            throw SupabaseHomeClientError.emptyIdentifierList
        }
        return "in.(\(values.joined(separator: ",")))"
    }
}

struct HomeUserSummaryPayload: Encodable, Sendable {
    var pUserId: UUID?
    var pExcludedUserId: UUID?
    var pLimit: Int

    init(userID: UUID? = nil, excludingUserID: UUID? = nil, limit: Int) {
        self.pUserId = userID
        self.pExcludedUserId = excludingUserID
        self.pLimit = SupabaseHomeQueryItems.boundedLimit(limit)
    }
}
