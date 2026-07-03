import Foundation
import MegrumCore

struct IndividualListingActiveSelectionState: Equatable {
    var activeListingID: UUID?

    mutating func reconcile(with listingIDs: [UUID]) {
        if let activeListingID, listingIDs.contains(activeListingID) {
            return
        }
        activeListingID = listingIDs.first
    }

    func activeListing(in listings: [IndividualListing]) -> IndividualListing? {
        if let activeListingID,
           let listing = listings.first(where: { $0.id == activeListingID }) {
            return listing
        }
        return listings.first
    }

    func activeListingIndex(in listings: [IndividualListing]) -> Int {
        guard let activeListingID,
              let index = listings.firstIndex(where: { $0.id == activeListingID })
        else {
            return 0
        }
        return index
    }
}
