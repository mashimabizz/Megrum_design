import Foundation
import MegrumCore
import SwiftUI

struct OshiMasterCandidateGrid: View {
    var groups: [OshiGroup]
    var selectedGroupIDs: Set<UUID>
    var isSelected: (OshiGroup) -> Bool
    var onSelect: (OshiGroup) -> Void

    var body: some View {
        WrappingTagFlow(
            spacing: OshiMasterSelectLayoutMetrics.candidateTagSpacing,
            rowSpacing: OshiMasterSelectLayoutMetrics.candidateTagRowSpacing
        ) {
            ForEach(groups) { group in
                OshiMasterCandidateTag(
                    title: group.name,
                    isSelected: isSelected(group),
                    isLocked: selectedGroupIDs.contains(group.id),
                    action: { onSelect(group) }
                )
            }
        }
        .padding(.horizontal, 18)
    }
}
