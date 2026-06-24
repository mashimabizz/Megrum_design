import Foundation
import MegrumCore

enum OshiMasterSelectionReducer {
    static func toggling(
        groupID: UUID,
        selectedIDs: Set<UUID>,
        lockedIDs: Set<UUID>
    ) -> Set<UUID> {
        guard !lockedIDs.contains(groupID) else {
            return selectedIDs
        }

        var next = selectedIDs
        if next.contains(groupID) {
            next.remove(groupID)
        } else {
            next.insert(groupID)
        }
        return next
    }

    static func selectedGroups(from groups: [OshiGroup], selectedIDs: Set<UUID>) -> [OshiGroup] {
        groups.filter { selectedIDs.contains($0.id) }
    }
}
