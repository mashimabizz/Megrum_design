import Foundation
import MegrumCore

struct OshiSettingsPresentationState: Equatable {
    var groups: [OshiSettingsGroupDraft] = []
    var charactersByGroupID: [UUID: [OshiCharacter]] = [:]
    var expandedGroupKey: String?
    var activeRemoveConfirmationGroupKey: String?
    var isSaving = false
    var isLoading = false
    var noticeMessage: String?
    var errorMessage: String?
    var showsMasterSheet = false
    var requestSheet: OshiRequestSheetState?

    mutating func toggleExpandedGroup(_ group: OshiSettingsGroupDraft) {
        guard group.supportsMemberSelection else {
            return
        }
        expandedGroupKey = expandedGroupKey == group.key ? nil : group.key
    }

    mutating func applyPreparedGroups(
        selections: [UserOshiSelection],
        masterGroups: [OshiGroup]
    ) {
        groups = OshiSettingsGroupDraft.build(
            selections: selections,
            masterGroups: masterGroups
        )
    }

    mutating func setCharacters(_ characters: [OshiCharacter], for groupID: UUID) {
        charactersByGroupID[groupID] = characters
    }

    mutating func setPersistedGroups(_ nextGroups: [OshiSettingsGroupDraft], success: String) {
        groups = nextGroups.reprioritized()
        noticeMessage = success
    }

    func availableCharacters(for group: OshiSettingsGroupDraft) -> [OshiCharacter] {
        guard group.supportsMemberSelection,
              let groupID = group.groupID
        else {
            return []
        }
        let selectedIDs = Set(group.members.compactMap(\.characterID))
        return (charactersByGroupID[groupID] ?? [])
            .filter { !selectedIDs.contains($0.id) }
            .sorted { $0.displayOrder == $1.displayOrder ? $0.name < $1.name : $0.displayOrder < $1.displayOrder }
    }
}
