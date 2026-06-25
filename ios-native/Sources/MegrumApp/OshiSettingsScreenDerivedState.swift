import MegrumCore

extension OshiSettingsScreen {
    func availableCharacters(for group: OshiSettingsGroupDraft) -> [OshiCharacter] {
        guard let groupID = group.groupID else {
            return []
        }
        let selectedIDs = Set(group.members.compactMap(\.characterID))
        return (charactersByGroupID[groupID] ?? [])
            .filter { !selectedIDs.contains($0.id) }
            .sorted { $0.displayOrder == $1.displayOrder ? $0.name < $1.name : $0.displayOrder < $1.displayOrder }
    }
}
