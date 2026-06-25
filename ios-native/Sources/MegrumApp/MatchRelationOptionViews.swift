import MegrumCore
import MegrumDesign
import SwiftUI

struct MatchRelationOwnerLabel: View {
    var title: String
    var color: Color

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(2)
    }
}

struct MatchRelationOptionList: View {
    var detail: MatchRelationListingDetail
    var viewpoint: MatchRelationViewpoint
    var partnerHandle: String
    var highlightedItemID: UUID
    var selectedCandidateIDs: Set<UUID>
    var onOpenPopup: (MatchRelationWishPopupTarget) -> Void

    private var visibleOptions: [MatchRelationOption] {
        detail.options
            .filter { !$0.option.isCashOffer }
            .filter { option in option.wishes.contains { !$0.candidates.isEmpty } }
            .sorted { lhs, rhs in
                if lhs.matched != rhs.matched {
                    return lhs.matched && !rhs.matched
                }
                return lhs.option.position < rhs.option.position
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if visibleOptions.isEmpty {
                Text("候補なし")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .padding(.vertical, 14)
            } else {
                ForEach(visibleOptions) { option in
                    MatchRelationOptionGroup(
                        listingID: detail.id,
                        viewpoint: viewpoint,
                        partnerHandle: partnerHandle,
                        option: option,
                        fallbackHave: MatchRelationComposer.defaultFallbackHave(
                            for: detail,
                            highlightedItemID: highlightedItemID
                        ),
                        highlightedItemID: highlightedItemID,
                        selectedCandidateIDs: selectedCandidateIDs,
                        onOpenPopup: onOpenPopup
                    )
                }
            }
        }
    }
}
