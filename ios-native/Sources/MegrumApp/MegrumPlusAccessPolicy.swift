import Foundation
import MegrumCore

public enum MegrumPlusAccessPolicy {
    public static func activeIndividualListingCount(_ listings: [IndividualListing]) -> Int {
        listings.filter(isCountedIndividualListing).count
    }

    public static func canCreateIndividualListing(
        listings: [IndividualListing],
        subscriptionState: UserSubscriptionState
    ) -> Bool {
        subscriptionState.hasUnlimitedIndividualListings
            || activeIndividualListingCount(listings) < MegrumPlusLimits.freeIndividualListingLimit
    }

    public static func individualListingLimitMessage(listings: [IndividualListing]) -> String {
        let count = activeIndividualListingCount(listings)
        return "無料プランでは個別募集は\(MegrumPlusLimits.freeIndividualListingLimit)件までです。現在\(count)件作成中です。"
    }

    public static func groomArchiveRequestLimit(
        requestedLimit: Int,
        subscriptionState: UserSubscriptionState
    ) -> Int {
        if subscriptionState.hasUnlimitedGroomArchive {
            return requestedLimit
        }
        return min(requestedLimit, MegrumPlusLimits.freeGroomArchiveLimit)
    }

    public static func isGroomArchiveLimited(subscriptionState: UserSubscriptionState) -> Bool {
        !subscriptionState.hasUnlimitedGroomArchive
    }

    private static func isCountedIndividualListing(_ listing: IndividualListing) -> Bool {
        switch listing.status {
        case .active, .paused, .matched:
            true
        case .closed:
            false
        }
    }
}
