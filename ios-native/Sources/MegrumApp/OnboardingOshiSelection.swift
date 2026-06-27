import Foundation
import MegrumCore

struct OnboardingOshiDraft: Identifiable, Hashable, Sendable {
    var groupID: UUID?
    var groupName: String
    var characterID: UUID?
    var characterName: String?
    var oshiRequestID: UUID?
    var characterRequestID: UUID?
    var requestedKind: OshiRequestKind?

    var id: String {
        if let oshiRequestID, let characterRequestID {
            return "request:\(oshiRequestID.uuidString):member-request:\(characterRequestID.uuidString)"
        }
        if let oshiRequestID {
            return "request:\(oshiRequestID.uuidString)"
        }
        if let characterID {
            return "\(groupID?.uuidString ?? "groupless"):\(characterID.uuidString)"
        }
        return "\(groupID?.uuidString ?? "groupless"):\(groupName):box"
    }

    var kind: OshiKind {
        characterID == nil && characterRequestID == nil ? .box : .specific
    }

    var displayName: String {
        if oshiRequestID != nil, characterRequestID != nil {
            return "\(groupName) / \(characterName ?? "承認待ちメンバー")（申請中）"
        }
        if oshiRequestID != nil {
            return "\(groupName)（申請中）"
        }
        if characterRequestID != nil {
            return "\(groupName) / \(characterName ?? "承認待ちメンバー")（申請中）"
        }
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
            priority: priority,
            oshiRequestID: oshiRequestID,
            characterRequestID: characterRequestID
        )
    }

    init(
        groupID: UUID,
        groupName: String,
        characterID: UUID?,
        characterName: String?
    ) {
        self.groupID = groupID
        self.groupName = groupName
        self.characterID = characterID
        self.characterName = characterName
        self.oshiRequestID = nil
        self.characterRequestID = nil
        self.requestedKind = nil
    }

    init(
        oshiRequestID: UUID,
        requestedName: String,
        requestedKind: OshiRequestKind? = nil
    ) {
        self.groupID = nil
        self.groupName = requestedName
        self.characterID = nil
        self.characterName = nil
        self.oshiRequestID = oshiRequestID
        self.characterRequestID = nil
        self.requestedKind = requestedKind
    }

    init(
        oshiRequestID: UUID,
        requestedName: String,
        characterRequestID: UUID,
        requestedCharacterName: String,
        requestedKind: OshiRequestKind? = nil
    ) {
        self.groupID = nil
        self.groupName = requestedName
        self.characterID = nil
        self.characterName = requestedCharacterName
        self.oshiRequestID = oshiRequestID
        self.characterRequestID = characterRequestID
        self.requestedKind = requestedKind
    }

    init(
        groupID: UUID,
        groupName: String,
        characterRequestID: UUID,
        requestedCharacterName: String
    ) {
        self.groupID = groupID
        self.groupName = groupName
        self.characterID = nil
        self.characterName = requestedCharacterName
        self.oshiRequestID = nil
        self.characterRequestID = characterRequestID
        self.requestedKind = nil
    }
}

struct OnboardingOshiMemberTarget: Identifiable, Hashable, Sendable {
    var groupID: UUID?
    var oshiRequestID: UUID
    var name: String
    var pending: Bool

    var id: String {
        if let groupID {
            return "master:\(groupID.uuidString)"
        }
        return "request:\(oshiRequestID.uuidString)"
    }

    var requestContext: OshiMemberRequestContext {
        if let groupID {
            return OshiMemberRequestContext(
                groupKey: id,
                groupID: groupID,
                oshiRequestID: nil,
                groupName: name
            )
        }
        return OshiMemberRequestContext(
            group: OshiSettingsGroupDraft(
                requestID: oshiRequestID,
                name: name,
                pending: pending,
                priority: 1
            )
        )
    }

    init(group: OshiGroup) {
        self.groupID = group.id
        self.oshiRequestID = group.id
        self.name = group.name
        self.pending = false
    }

    init(oshiRequestID: UUID, name: String) {
        self.groupID = nil
        self.oshiRequestID = oshiRequestID
        self.name = name
        self.pending = true
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
