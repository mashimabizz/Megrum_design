import Foundation
import MegrumCore

enum OnboardingOshiSelectionLogic {
    static func isWholeGroupSelected(_ group: OshiGroup, in drafts: [OnboardingOshiDraft]) -> Bool {
        drafts.contains { $0.groupID == group.id && $0.characterID == nil }
    }

    static func isCharacterSelected(_ character: OshiCharacter, in drafts: [OnboardingOshiDraft]) -> Bool {
        drafts.contains { $0.groupID == character.groupID && $0.characterID == character.id }
    }

    static func groupHasSelection(_ group: OshiGroup, in drafts: [OnboardingOshiDraft]) -> Bool {
        drafts.contains { $0.groupID == group.id }
    }

    static func targetHasSelection(_ target: OnboardingOshiMemberTarget, in drafts: [OnboardingOshiDraft]) -> Bool {
        if let groupID = target.groupID {
            return drafts.contains { $0.groupID == groupID }
        }
        return drafts.contains { $0.oshiRequestID == target.oshiRequestID }
    }

    static func toggleWholeGroup(_ group: OshiGroup, in drafts: [OnboardingOshiDraft]) -> [OnboardingOshiDraft] {
        if isWholeGroupSelected(group, in: drafts) {
            return drafts.filter { !($0.groupID == group.id && $0.characterID == nil) }
        }

        var updated = drafts.filter { $0.groupID != group.id }
        updated.append(
            OnboardingOshiDraft(
                groupID: group.id,
                groupName: group.name,
                characterID: nil,
                characterName: nil
            )
        )
        return updated
    }

    static func toggleCharacter(
        _ character: OshiCharacter,
        group: OshiGroup,
        in drafts: [OnboardingOshiDraft]
    ) -> [OnboardingOshiDraft] {
        if isCharacterSelected(character, in: drafts) {
            return drafts.filter { !($0.groupID == character.groupID && $0.characterID == character.id) }
        }

        var updated = drafts.filter { !($0.groupID == character.groupID && $0.characterID == nil) }
        updated.append(
            OnboardingOshiDraft(
                groupID: group.id,
                groupName: group.name,
                characterID: character.id,
                characterName: character.name
            )
        )
        return updated
    }

    static func accountSetupInputs(from drafts: [OnboardingOshiDraft]) -> [AccountSetupOshiInput] {
        drafts.enumerated().map { offset, draft in
            draft.accountSetupInput(priority: offset + 1)
        }
    }

    static func memberRequestDrafts(
        for target: OnboardingOshiMemberTarget,
        in drafts: [OnboardingOshiDraft]
    ) -> [OnboardingOshiDraft] {
        drafts.filter { draft in
            if let groupID = target.groupID {
                return draft.groupID == groupID && draft.characterRequestID != nil
            }
            return draft.oshiRequestID == target.oshiRequestID && draft.characterRequestID != nil
        }
    }

    static func requestedMemberTargets(from drafts: [OnboardingOshiDraft]) -> [OnboardingOshiMemberTarget] {
        var seenRequestIDs = Set<UUID>()
        return drafts.compactMap { draft in
            guard let requestID = draft.oshiRequestID,
                  draft.requestedKind?.supportsMemberSelection ?? true,
                  seenRequestIDs.insert(requestID).inserted
            else {
                return nil
            }
            return OnboardingOshiMemberTarget(oshiRequestID: requestID, name: draft.groupName)
        }
    }

    static func draftsAfterSeedingWholeGroupSelections(
        selectedGroups: [OshiGroup],
        currentDrafts: [OnboardingOshiDraft]
    ) -> [OnboardingOshiDraft] {
        let selectedIDs = Set(selectedGroups.map(\.id))
        var updatedDrafts = currentDrafts.filter { draft in
            guard let groupID = draft.groupID else {
                return true
            }
            return selectedIDs.contains(groupID)
        }

        for group in selectedGroups where !group.supportsMemberSelection {
            guard !isWholeGroupSelected(group, in: updatedDrafts) else {
                continue
            }
            updatedDrafts = toggleWholeGroup(group, in: updatedDrafts)
        }

        return updatedDrafts
    }

    static func drafts(
        from selections: [UserOshiSelection],
        groups: [OshiGroup],
        characters: [OshiCharacter]
    ) -> [OnboardingOshiDraft] {
        let groupsByID = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, $0) })
        let charactersByID = Dictionary(uniqueKeysWithValues: characters.map { ($0.id, $0) })

        return selections.sorted { lhs, rhs in
            lhs.priority < rhs.priority
        }.compactMap { selection in
            if let requestID = selection.oshiRequestID {
                if let characterRequestID = selection.characterRequestID {
                    return OnboardingOshiDraft(
                        oshiRequestID: requestID,
                        requestedName: selection.oshiRequestName ?? "承認待ちの推し",
                        characterRequestID: characterRequestID,
                        requestedCharacterName: selection.characterRequestName ?? "承認待ちメンバー"
                    )
                }
                return OnboardingOshiDraft(
                    oshiRequestID: requestID,
                    requestedName: selection.oshiRequestName ?? "承認待ちの推し"
                )
            }

            guard let groupID = selection.groupID else {
                return nil
            }
            let groupName = groupsByID[groupID]?.name ?? "選択済みグループ"
            let characterName: String?
            if let characterID = selection.characterID {
                characterName = charactersByID[characterID]?.name ?? "選択済みメンバー"
            } else if selection.characterRequestID != nil {
                characterName = selection.characterRequestName ?? "承認待ちメンバー"
            } else {
                characterName = nil
            }

            if let characterRequestID = selection.characterRequestID {
                return OnboardingOshiDraft(
                    groupID: groupID,
                    groupName: groupName,
                    characterRequestID: characterRequestID,
                    requestedCharacterName: characterName ?? "承認待ちメンバー"
                )
            }

            return OnboardingOshiDraft(
                groupID: groupID,
                groupName: groupName,
                characterID: selection.characterID,
                characterName: characterName
            )
        }
    }
}
