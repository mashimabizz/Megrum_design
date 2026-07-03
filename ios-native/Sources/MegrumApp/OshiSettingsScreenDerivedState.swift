import MegrumCore

extension OshiSettingsScreen {
    func availableCharacters(for group: OshiSettingsGroupDraft) -> [OshiCharacter] {
        presentationState.availableCharacters(for: group)
    }
}
