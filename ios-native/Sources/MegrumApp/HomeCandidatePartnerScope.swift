import Foundation
import MegrumCore
import MegrumData

struct HomeCandidatePartnerScope {
    let users: [SupabaseHomeUserRow]
    let inventory: [SupabaseHomeGoodsRow]
    let wishes: [SupabaseHomeGoodsRow]
    let listings: [SupabaseHomeListingRow]
    let activityWindows: [SupabaseHomeActivityWindowRow]
    let wishesByUser: [UUID: [SupabaseHomeGoodsRow]]
    let listingsByUser: [UUID: [SupabaseHomeListingRow]]
    let usersByID: [UUID: SupabaseHomeUserRow]
    let activityWindowsByUser: [UUID: [SupabaseHomeActivityWindowRow]]

    init(composition: SupabaseHomeComposition) {
        let viewerIsTestAccount = composition.viewerUser.map(HomeCandidateRowMapper.isTestUser) ?? false
        let excludedTestPartnerUserIDs: Set<UUID> = viewerIsTestAccount
            ? []
            : Set(composition.partnerUsers.filter(HomeCandidateRowMapper.isTestUser).map(\.id))

        users = composition.partnerUsers.filter { !excludedTestPartnerUserIDs.contains($0.id) }
        inventory = viewerIsTestAccount
            ? composition.partnerInventory
            : composition.partnerInventory.filter { !excludedTestPartnerUserIDs.contains($0.userId) }
        wishes = viewerIsTestAccount
            ? composition.partnerWishes
            : composition.partnerWishes.filter { !excludedTestPartnerUserIDs.contains($0.userId) }
        listings = viewerIsTestAccount
            ? composition.partnerListings
            : composition.partnerListings.filter { !excludedTestPartnerUserIDs.contains($0.userId) }
        activityWindows = viewerIsTestAccount
            ? composition.partnerActivityWindows
            : composition.partnerActivityWindows.filter { !excludedTestPartnerUserIDs.contains($0.userId) }
        wishesByUser = Dictionary(grouping: wishes, by: \.userId)
        listingsByUser = Dictionary(grouping: listings, by: \.userId)
        usersByID = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })
        activityWindowsByUser = Dictionary(grouping: activityWindows, by: \.userId)
    }

    func filteredComposition(from composition: SupabaseHomeComposition) -> SupabaseHomeComposition {
        SupabaseHomeComposition(
            localMode: composition.localMode,
            viewerUser: composition.viewerUser,
            viewerInventory: composition.viewerInventory,
            viewerWishes: composition.viewerWishes,
            viewerListings: composition.viewerListings,
            partnerInventory: inventory,
            partnerWishes: wishes,
            partnerUsers: users,
            partnerListings: listings,
            listingWishOptions: composition.listingWishOptions,
            viewerActivityWindows: composition.viewerActivityWindows,
            partnerActivityWindows: activityWindows,
            inventoryTags: composition.inventoryTags,
            unreadNotificationIDs: composition.unreadNotificationIDs,
            megrumPlusUserIDs: composition.megrumPlusUserIDs
        )
    }
}
