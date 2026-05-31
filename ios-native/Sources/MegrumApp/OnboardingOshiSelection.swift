import Foundation
import MegrumCore

struct OnboardingOshiDraft: Identifiable, Hashable, Sendable {
    var groupID: UUID
    var groupName: String
    var characterID: UUID?
    var characterName: String?

    var id: String {
        if let characterID {
            return "\(groupID.uuidString):\(characterID.uuidString)"
        }
        return "\(groupID.uuidString):box"
    }

    var kind: OshiKind {
        characterID == nil ? .box : .specific
    }

    var displayName: String {
        if let characterName {
            return "\(groupName) / \(characterName)"
        }
        return "\(groupName) 全体"
    }

    func accountSetupInput(priority: Int) -> AccountSetupOshiInput {
        AccountSetupOshiInput(
            groupID: groupID,
            characterID: characterID,
            kind: kind,
            priority: priority
        )
    }
}

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
            guard let groupID = selection.groupID else {
                return nil
            }

            let groupName = groupsByID[groupID]?.name ?? "選択済みグループ"
            let characterName: String?
            if let characterID = selection.characterID {
                characterName = charactersByID[characterID]?.name ?? "選択済みメンバー"
            } else {
                characterName = nil
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
