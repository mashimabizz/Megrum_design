import Foundation

public struct UserOshiSelection: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var userID: UUID
    public var groupID: UUID?
    public var characterID: UUID?
    public var oshiRequestID: UUID?
    public var characterRequestID: UUID?
    public var groupName: String?
    public var characterName: String?
    public var oshiRequestName: String?
    public var characterRequestName: String?
    public var kind: OshiKind
    public var priority: Int

    public init(
        id: UUID,
        userID: UUID,
        groupID: UUID?,
        characterID: UUID?,
        kind: OshiKind,
        priority: Int,
        oshiRequestID: UUID? = nil,
        characterRequestID: UUID? = nil,
        groupName: String? = nil,
        characterName: String? = nil,
        oshiRequestName: String? = nil,
        characterRequestName: String? = nil
    ) {
        self.id = id
        self.userID = userID
        self.groupID = groupID
        self.characterID = characterID
        self.oshiRequestID = oshiRequestID
        self.characterRequestID = characterRequestID
        self.groupName = groupName
        self.characterName = characterName
        self.oshiRequestName = oshiRequestName
        self.characterRequestName = characterRequestName
        self.kind = kind
        self.priority = priority
    }
}
