import Foundation

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
