import Foundation

public enum OshiKind: String, Codable, Sendable, CaseIterable, Identifiable {
    case box
    case specific
    case multi

    public var id: String { rawValue }
}

public enum OshiRequestKind: String, Codable, Sendable, CaseIterable, Identifiable {
    case group
    case work
    case solo

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .group:
            "グループ"
        case .work:
            "作品"
        case .solo:
            "ソロ活動"
        }
    }

    public var supportsMemberSelection: Bool {
        switch self {
        case .group, .work:
            true
        case .solo:
            false
        }
    }
}

public struct OshiGenre: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var kind: String?
    public var displayOrder: Int

    public init(id: UUID, name: String, kind: String? = nil, displayOrder: Int = 0) {
        self.id = id
        self.name = name
        self.kind = kind
        self.displayOrder = displayOrder
    }
}

public struct OshiRequestCreateInput: Equatable, Sendable {
    public var requestedName: String
    public var requestedKind: OshiRequestKind
    public var requestedGenreID: UUID?
    public var note: String?

    public init(
        requestedName: String,
        requestedKind: OshiRequestKind,
        requestedGenreID: UUID? = nil,
        note: String? = nil
    ) {
        self.requestedName = requestedName
        self.requestedKind = requestedKind
        self.requestedGenreID = requestedGenreID
        self.note = note
    }
}

public struct CharacterRequestCreateInput: Equatable, Sendable {
    public var groupID: UUID?
    public var oshiRequestID: UUID?
    public var requestedName: String
    public var note: String?

    public init(groupID: UUID?, oshiRequestID: UUID? = nil, requestedName: String, note: String? = nil) {
        self.groupID = groupID
        self.oshiRequestID = oshiRequestID
        self.requestedName = requestedName
        self.note = note
    }
}

public struct OshiGroup: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var aliases: [String]
    public var kind: OshiRequestKind
    public var genreID: UUID?
    public var genreName: String?
    public var displayOrder: Int

    public init(
        id: UUID,
        name: String,
        aliases: [String] = [],
        kind: OshiRequestKind = .group,
        genreID: UUID? = nil,
        genreName: String? = nil,
        displayOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.aliases = aliases
        self.kind = kind
        self.genreID = genreID
        self.genreName = genreName
        self.displayOrder = displayOrder
    }

    public var supportsMemberSelection: Bool {
        kind.supportsMemberSelection
    }
}

public struct OshiCharacter: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var groupID: UUID
    public var name: String
    public var aliases: [String]
    public var displayOrder: Int

    public init(
        id: UUID,
        groupID: UUID,
        name: String,
        aliases: [String] = [],
        displayOrder: Int = 0
    ) {
        self.id = id
        self.groupID = groupID
        self.name = name
        self.aliases = aliases
        self.displayOrder = displayOrder
    }
}
