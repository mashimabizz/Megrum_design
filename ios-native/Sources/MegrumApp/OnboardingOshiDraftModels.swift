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
