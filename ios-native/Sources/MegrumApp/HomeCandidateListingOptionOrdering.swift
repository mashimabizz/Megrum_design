import Foundation
import MegrumData

enum HomeCandidateListingOptionOrdering {
    static func sorted(
        _ options: [SupabaseHomeListingWishOptionRow]
    ) -> [SupabaseHomeListingWishOptionRow] {
        options.sorted { lhs, rhs in
            if lhs.position == rhs.position {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return lhs.position < rhs.position
        }
    }
}
