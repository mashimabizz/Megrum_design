import Foundation
import MegrumCore

public enum IndividualListingStateReducer {
    public static func upserting(
        _ listing: IndividualListing,
        into listings: [IndividualListing]
    ) -> [IndividualListing] {
        var next = listings
        next.removeAll { $0.id == listing.id }
        next.insert(listing, at: 0)
        return next
    }

    public static func removing(
        listingID: UUID,
        from listings: [IndividualListing]
    ) -> [IndividualListing] {
        listings.filter { $0.id != listingID }
    }
}
