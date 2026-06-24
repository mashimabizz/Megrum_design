import Foundation
import MegrumCore

struct OshiSettingsGroupDraft: Identifiable, Hashable, Sendable {
    var groupID: UUID?
    var requestID: UUID?
    var name: String
    var pending: Bool
    var priority: Int
    var members: [OshiSettingsMemberDraft]

    var key: String {
        if let groupID {
            return "master:\(groupID.uuidString)"
        }
        return "request:\(requestID?.uuidString ?? name)"
    }

    var id: String { key }

    init(masterGroup: OshiGroup, priority: Int) {
        self.groupID = masterGroup.id
        self.requestID = nil
        self.name = masterGroup.name
        self.pending = false
        self.priority = priority
        self.members = []
    }

    init(requestID: UUID, name: String, pending: Bool, priority: Int, members: [OshiSettingsMemberDraft] = []) {
        self.groupID = nil
        self.requestID = requestID
        self.name = name
        self.pending = pending
        self.priority = priority
        self.members = members
    }

    static func build(selections: [UserOshiSelection], masterGroups: [OshiGroup]) -> [OshiSettingsGroupDraft] {
        let groupsByID = Dictionary(uniqueKeysWithValues: masterGroups.map { ($0.id, $0) })
        var result: [String: OshiSettingsGroupDraft] = [:]

        for selection in selections.sorted(by: { $0.priority < $1.priority }) {
            let groupKey: String
            let baseGroup: OshiSettingsGroupDraft
            if let groupID = selection.groupID {
                groupKey = "master:\(groupID.uuidString)"
                baseGroup = OshiSettingsGroupDraft(
                    groupID: groupID,
                    requestID: nil,
                    name: selection.groupName ?? groupsByID[groupID]?.name ?? "選択済みグループ",
                    pending: false,
                    priority: selection.priority,
                    members: []
                )
            } else if let requestID = selection.oshiRequestID {
                groupKey = "request:\(requestID.uuidString)"
                baseGroup = OshiSettingsGroupDraft(
                    groupID: nil,
                    requestID: requestID,
                    name: selection.oshiRequestName ?? "承認待ちの推し",
                    pending: true,
                    priority: selection.priority,
                    members: []
                )
            } else {
                continue
            }

            var group = result[groupKey] ?? baseGroup
            group.priority = min(group.priority, selection.priority)
            if let characterID = selection.characterID {
                group.members.append(
                    OshiSettingsMemberDraft(
                        characterID: characterID,
                        name: selection.characterName ?? "選択済みメンバー",
                        pending: false
                    )
                )
            } else if let characterRequestID = selection.characterRequestID {
                group.members.append(
                    OshiSettingsMemberDraft(
                        characterRequestID: characterRequestID,
                        name: selection.characterRequestName ?? "承認待ちメンバー",
                        pending: true
                    )
                )
            }
            result[groupKey] = group
        }

        return Array(result.values).sorted { lhs, rhs in
            lhs.priority == rhs.priority ? lhs.name.localizedCompare(rhs.name) == .orderedAscending : lhs.priority < rhs.priority
        }
    }

    static func accountSetupInputs(from groups: [OshiSettingsGroupDraft]) -> [AccountSetupOshiInput] {
        groups.reprioritized().flatMap { group -> [AccountSetupOshiInput] in
            if group.members.isEmpty {
                return [
                    AccountSetupOshiInput(
                        groupID: group.groupID,
                        characterID: nil,
                        kind: .box,
                        priority: group.priority,
                        oshiRequestID: group.requestID,
                        characterRequestID: nil
                    )
                ]
            }
            return group.members.enumerated().map { memberOffset, member in
                AccountSetupOshiInput(
                    groupID: group.groupID,
                    characterID: member.characterID,
                    kind: .specific,
                    priority: group.priority * 1_000 + memberOffset,
                    oshiRequestID: group.requestID,
                    characterRequestID: member.characterRequestID
                )
            }
        }
    }

    private init(
        groupID: UUID?,
        requestID: UUID?,
        name: String,
        pending: Bool,
        priority: Int,
        members: [OshiSettingsMemberDraft]
    ) {
        self.groupID = groupID
        self.requestID = requestID
        self.name = name
        self.pending = pending
        self.priority = priority
        self.members = members
    }
}

struct OshiSettingsMemberDraft: Identifiable, Hashable, Sendable {
    var characterID: UUID?
    var characterRequestID: UUID?
    var name: String
    var pending: Bool

    var id: String {
        if let characterID {
            return "master:\(characterID.uuidString)"
        }
        return "request:\(characterRequestID?.uuidString ?? name)"
    }

    init(character: OshiCharacter) {
        self.characterID = character.id
        self.characterRequestID = nil
        self.name = character.name
        self.pending = false
    }

    init(characterID: UUID? = nil, characterRequestID: UUID? = nil, name: String, pending: Bool) {
        self.characterID = characterID
        self.characterRequestID = characterRequestID
        self.name = name
        self.pending = pending
    }
}

struct OshiMemberRequestContext: Identifiable, Hashable, Sendable {
    var groupKey: String
    var groupID: UUID?
    var oshiRequestID: UUID?
    var groupName: String
    var initialName: String?

    var id: String { groupKey }

    init(group: OshiSettingsGroupDraft, initialName: String? = nil) {
        self.groupKey = group.key
        self.groupID = group.groupID
        self.oshiRequestID = group.requestID
        self.groupName = group.name
        self.initialName = initialName
    }

    var canCreateCharacterRequest: Bool {
        groupID != nil || oshiRequestID != nil
    }
}

extension Array where Element == OshiSettingsGroupDraft {
    func reprioritized() -> [OshiSettingsGroupDraft] {
        enumerated().map { offset, group in
            var next = group
            next.priority = offset + 1
            return next
        }
    }
}
