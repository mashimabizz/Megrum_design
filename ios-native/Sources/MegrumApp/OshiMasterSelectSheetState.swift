import Foundation
import MegrumCore

struct OshiMasterSelectSheetState: Equatable {
    var searchText = ""
    var selectedGenreID: UUID?
    var pendingSelectedGroupIDs: Set<UUID> = []

    var requestSearchText: String? {
        searchText.nilIfBlank
    }

    var pendingSelectionCount: Int {
        pendingSelectedGroupIDs.count
    }

    var hasPendingSelection: Bool {
        !pendingSelectedGroupIDs.isEmpty
    }

    func filteredGroups(from groups: [OshiGroup]) -> [OshiGroup] {
        let normalized = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return groups.filter { group in
            if let selectedGenreID, group.genreID != selectedGenreID {
                return false
            }
            guard !normalized.isEmpty else {
                return true
            }
            return ([group.name] + group.aliases).contains { $0.localizedCaseInsensitiveContains(normalized) }
        }
    }

    func pendingSelectedGroups(from groups: [OshiGroup]) -> [OshiGroup] {
        OshiMasterSelectionReducer.selectedGroups(from: groups, selectedIDs: pendingSelectedGroupIDs)
    }

    func isSelected(_ group: OshiGroup, selectedGroupIDs: Set<UUID>) -> Bool {
        selectedGroupIDs.contains(group.id) || pendingSelectedGroupIDs.contains(group.id)
    }

    mutating func togglePendingGroup(_ groupID: UUID, lockedIDs: Set<UUID>) {
        pendingSelectedGroupIDs = OshiMasterSelectionReducer.toggling(
            groupID: groupID,
            selectedIDs: pendingSelectedGroupIDs,
            lockedIDs: lockedIDs
        )
    }

    mutating func removeLockedPendingSelection(selectedGroupIDs: Set<UUID>) {
        pendingSelectedGroupIDs.subtract(selectedGroupIDs)
    }

    mutating func clearPendingSelection() {
        pendingSelectedGroupIDs = []
    }
}
