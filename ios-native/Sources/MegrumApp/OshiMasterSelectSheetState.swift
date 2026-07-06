import Foundation
import MegrumCore

struct OshiMasterSelectSheetState: Equatable {
    /// 「自分の推し」カテゴリの sentinel ID（ジャンルIDと衝突しない固定値）。
    static let myOshiCategoryID = UUID(uuidString: "00000000-0000-0000-0000-0000000A1510")!

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

    func filteredGroups(
        from groups: [OshiGroup],
        myOshiGroupIDs: Set<UUID> = [],
        characterHitGroupIDs: Set<UUID> = []
    ) -> [OshiGroup] {
        let normalized = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        // 検索中は選択中カテゴリを無視して、L1全体＋L2名ヒットの親L1から探す。
        if !normalized.isEmpty {
            return groups.filter { group in
                characterHitGroupIDs.contains(group.id)
                    || ([group.name] + group.aliases).contains { $0.localizedCaseInsensitiveContains(normalized) }
            }
        }
        return groups.filter { group in
            if selectedGenreID == Self.myOshiCategoryID {
                if !myOshiGroupIDs.contains(group.id) {
                    return false
                }
            } else if let selectedGenreID, group.genreID != selectedGenreID {
                return false
            }
            return true
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
