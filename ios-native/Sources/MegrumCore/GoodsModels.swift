import Foundation

public struct GoodsType: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var category: String?
    public var displayOrder: Int

    public init(id: UUID, name: String, category: String? = nil, displayOrder: Int = 0) {
        self.id = id
        self.name = name
        self.category = category
        self.displayOrder = displayOrder
    }
}

public struct GoodsTag: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String

    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}

public struct GoodsItem: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var ownerID: UUID
    public var kind: GoodsEntryKind?
    public var status: GoodsEntryStatus?
    public var groupID: UUID?
    public var memberID: UUID?
    public var goodsTypeID: UUID?
    public var groupName: String?
    public var memberName: String?
    public var goodsTypeName: String?
    public var title: String
    public var imageURL: URL?
    public var tags: [GoodsTag]
    public var quantity: Int
    public var lockedQuantity: Int
    public var marketAvailableQuantity: Int
    public var exchangeMethod: ExchangeMethod?
    public var ownerPrefecture: String?
    public var ownerDisplayName: String?
    public var ownerHandle: String?
    public var ownerAvatarURL: URL?
    public var ownerGender: UserGender?
    public var ownerAge: Int?
    public var ownerAverageStars: Double?
    public var ownerEvaluationCount: Int?
    public var ownerCompletedTradeCount: Int?
    public var ownerPaymentMethods: [UserPaymentMethod]
    public var ownerPaymentNote: String?
    public var ownerHasMegrumPlus: Bool?
    /// 譲グッズの登録・更新日（ホーム候補シートの日時表示用）。
    public var updatedAt: Date?

    public init(
        id: UUID,
        ownerID: UUID,
        kind: GoodsEntryKind? = nil,
        status: GoodsEntryStatus? = nil,
        groupID: UUID? = nil,
        memberID: UUID? = nil,
        goodsTypeID: UUID? = nil,
        groupName: String? = nil,
        memberName: String? = nil,
        goodsTypeName: String? = nil,
        title: String,
        imageURL: URL? = nil,
        tags: [GoodsTag] = [],
        quantity: Int = 1,
        lockedQuantity: Int = 0,
        marketAvailableQuantity: Int? = nil,
        exchangeMethod: ExchangeMethod? = nil,
        ownerPrefecture: String? = nil,
        ownerDisplayName: String? = nil,
        ownerHandle: String? = nil,
        ownerAvatarURL: URL? = nil,
        ownerGender: UserGender? = nil,
        ownerAge: Int? = nil,
        ownerAverageStars: Double? = nil,
        ownerEvaluationCount: Int? = nil,
        ownerCompletedTradeCount: Int? = nil,
        ownerPaymentMethods: [UserPaymentMethod] = [],
        ownerPaymentNote: String? = nil,
        ownerHasMegrumPlus: Bool? = nil,
        updatedAt: Date? = nil
    ) {
        let normalizedQuantity = max(0, quantity)
        let normalizedLockedQuantity = max(0, lockedQuantity)
        self.id = id
        self.ownerID = ownerID
        self.kind = kind
        self.status = status
        self.groupID = groupID
        self.memberID = memberID
        self.goodsTypeID = goodsTypeID
        self.groupName = groupName
        self.memberName = memberName
        self.goodsTypeName = goodsTypeName
        self.title = title
        self.imageURL = imageURL
        self.tags = tags
        self.quantity = normalizedQuantity
        self.lockedQuantity = normalizedLockedQuantity
        self.marketAvailableQuantity = max(0, marketAvailableQuantity ?? (normalizedQuantity - normalizedLockedQuantity))
        self.exchangeMethod = exchangeMethod
        self.ownerPrefecture = ownerPrefecture
        self.ownerDisplayName = ownerDisplayName
        self.ownerHandle = ownerHandle
        self.ownerAvatarURL = ownerAvatarURL
        self.ownerGender = ownerGender
        self.ownerAge = ownerAge
        self.ownerAverageStars = ownerAverageStars
        self.ownerEvaluationCount = ownerEvaluationCount
        self.ownerCompletedTradeCount = ownerCompletedTradeCount
        self.ownerPaymentMethods = UserPaymentMethod.normalized(ownerPaymentMethods)
        self.ownerPaymentNote = ownerPaymentNote
        self.ownerHasMegrumPlus = ownerHasMegrumPlus
        self.updatedAt = updatedAt
    }

    public var masterDisplayName: String? {
        if memberID != nil, let memberName = normalizedMasterName(memberName) {
            return memberName
        }
        if let groupName = normalizedMasterName(groupName) {
            return groupName
        }
        return nil
    }

    public var masterGoodsTitle: String? {
        let names = [
            masterDisplayName,
            normalizedMasterName(goodsTypeName)
        ].compactMap { $0 }
        return names.isEmpty ? nil : names.joined(separator: " ")
    }

    private func normalizedMasterName(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

public struct GoodsPhotoUpload: Equatable, Sendable {
    public var data: Data
    public var contentType: String

    public init(data: Data, contentType: String = "image/jpeg") {
        self.data = data
        self.contentType = contentType
    }
}

public enum GoodsEntryKind: String, Codable, Sendable, CaseIterable, Identifiable {
    case inventory
    case wish

    public var id: String { rawValue }

    public var inventoryKind: String {
        switch self {
        case .inventory:
            "for_trade"
        case .wish:
            "wanted"
        }
    }

    public init?(inventoryKind: String?) {
        switch inventoryKind {
        case "for_trade":
            self = .inventory
        case "wanted":
            self = .wish
        default:
            return nil
        }
    }
}

public enum GoodsEntryStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case active
    case keep
    case reserved
    case traded
    case archived

    public var id: String { rawValue }

    public var inventoryTabTitle: String {
        switch self {
        case .active, .reserved:
            "譲る候補"
        case .keep:
            "自分用キープ"
        case .traded:
            "過去に譲った"
        case .archived:
            "非表示"
        }
    }
}

public struct GoodsEntryInput: Equatable, Sendable {
    public var kind: GoodsEntryKind
    public var title: String
    public var groupID: UUID
    public var memberID: UUID?
    public var goodsTypeID: UUID
    public var quantity: Int
    public var status: GoodsEntryStatus?
    public var tagNames: [String]
    public var photoURLs: [String]
    public var photoUpload: GoodsPhotoUpload?

    public init(
        kind: GoodsEntryKind,
        title: String,
        groupID: UUID,
        memberID: UUID? = nil,
        goodsTypeID: UUID,
        quantity: Int = 1,
        status: GoodsEntryStatus? = nil,
        tagNames: [String] = [],
        photoURLs: [String] = [],
        photoUpload: GoodsPhotoUpload? = nil
    ) {
        self.kind = kind
        self.title = title
        self.groupID = groupID
        self.memberID = memberID
        self.goodsTypeID = goodsTypeID
        self.quantity = quantity
        self.status = status
        self.tagNames = tagNames
        self.photoURLs = photoURLs
        self.photoUpload = photoUpload
    }
}

public struct GoodsEntryUpdateInput: Equatable, Sendable {
    public var title: String
    public var groupID: UUID
    public var memberID: UUID?
    public var clearsMemberID: Bool
    public var goodsTypeID: UUID
    public var quantity: Int
    public var status: GoodsEntryStatus
    public var photoURLs: [String]?
    public var tagNames: [String]?
    public var photoUpload: GoodsPhotoUpload?

    public init(
        title: String,
        groupID: UUID,
        memberID: UUID? = nil,
        clearsMemberID: Bool = false,
        goodsTypeID: UUID,
        quantity: Int = 1,
        status: GoodsEntryStatus = .active,
        photoURLs: [String]? = nil,
        tagNames: [String]? = nil,
        photoUpload: GoodsPhotoUpload? = nil
    ) {
        self.title = title
        self.groupID = groupID
        self.memberID = memberID
        self.clearsMemberID = clearsMemberID
        self.goodsTypeID = goodsTypeID
        self.quantity = quantity
        self.status = status
        self.photoURLs = photoURLs
        self.tagNames = tagNames
        self.photoUpload = photoUpload
    }
}
