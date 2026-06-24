import Foundation

public enum SupabaseGoodsInventoryClientError: Error, Equatable, Sendable {
    case emptyTitle
    case invalidQuantity
    case emptyUpdate
    case emptyTag
    case imageTooLarge
    case unsupportedImageContentType
}

public enum GoodsInventoryStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case active
    case keep
    case reserved
    case traded
    case archived

    public var id: String { rawValue }
}

public struct GoodsInventoryUpdateInput: Equatable, Sendable {
    public var title: String?
    public var groupID: UUID?
    public var characterID: UUID?
    public var clearsCharacterID: Bool
    public var goodsTypeID: UUID?
    public var quantity: Int?
    public var status: GoodsInventoryStatus?
    public var photoURLs: [String]?
    public var tagNames: [String]?

    public init(
        title: String? = nil,
        groupID: UUID? = nil,
        characterID: UUID? = nil,
        clearsCharacterID: Bool = false,
        goodsTypeID: UUID? = nil,
        quantity: Int? = nil,
        status: GoodsInventoryStatus? = nil,
        photoURLs: [String]? = nil,
        tagNames: [String]? = nil
    ) {
        self.title = title
        self.groupID = groupID
        self.characterID = characterID
        self.clearsCharacterID = clearsCharacterID
        self.goodsTypeID = goodsTypeID
        self.quantity = quantity
        self.status = status
        self.photoURLs = photoURLs
        self.tagNames = tagNames
    }
}
