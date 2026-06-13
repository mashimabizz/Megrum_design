import Foundation
import MegrumCore

enum GoodsEditorWishPhotoRemovalPolicy {
    static func isRemovalLocked(
        itemID: UUID?,
        entryKind: GoodsEntryKind,
        listings: [IndividualListing]
    ) -> Bool {
        guard entryKind == .wish,
              let itemID
        else {
            return false
        }

        return listings.contains { listing in
            switch listing.status {
            case .active, .paused, .matched:
                return listing.options.contains { option in
                    option.wishes.contains { $0.itemID == itemID }
                }
            case .closed:
                return false
            }
        }
    }
}
