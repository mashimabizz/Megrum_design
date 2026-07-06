import Foundation

public struct GoodsSearchInput: Equatable, Sendable {
    public var query: String
    /// 複数選択（項目内OR）。空 = 指定なし。
    public var groupIDs: [UUID]
    public var memberIDs: [UUID]
    public var goodsTypeIDs: [UUID]
    public var limit: Int

    public init(
        query: String,
        groupIDs: [UUID],
        memberIDs: [UUID] = [],
        goodsTypeIDs: [UUID] = [],
        limit: Int = 60
    ) {
        self.query = query
        self.groupIDs = groupIDs
        self.memberIDs = memberIDs
        self.goodsTypeIDs = goodsTypeIDs
        self.limit = limit
    }

    public init(query: String, groupID: UUID? = nil, memberID: UUID? = nil, goodsTypeID: UUID? = nil, limit: Int = 60) {
        self.init(
            query: query,
            groupIDs: groupID.map { [$0] } ?? [],
            memberIDs: memberID.map { [$0] } ?? [],
            goodsTypeIDs: goodsTypeID.map { [$0] } ?? [],
            limit: limit
        )
    }

    public var groupID: UUID? { groupIDs.first }
    public var memberID: UUID? { memberIDs.first }
    public var goodsTypeID: UUID? { goodsTypeIDs.first }
}

public enum SearchMatchBucket: String, Codable, Sendable, CaseIterable, Identifiable {
    case matched
    case possible
    case none

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .matched:
            "マッチしてるよ！"
        case .possible:
            "交換できるかも？"
        case .none:
            "マッチなし"
        }
    }
}

public struct SearchResultItem: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var item: GoodsItem
    public var ownerUserID: UUID
    public var bucket: SearchMatchBucket

    public init(item: GoodsItem, ownerUserID: UUID, bucket: SearchMatchBucket) {
        self.id = item.id
        self.item = item
        self.ownerUserID = ownerUserID
        self.bucket = bucket
    }
}

public struct WishItem: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var ownerID: UUID
    public var groupID: UUID?
    public var memberID: UUID?
    public var goodsTypeID: UUID?
    public var title: String
    public var imageURL: URL?
    public var tags: [GoodsTag]
    public var quantity: Int

    public init(
        id: UUID,
        ownerID: UUID,
        groupID: UUID? = nil,
        memberID: UUID? = nil,
        goodsTypeID: UUID? = nil,
        title: String,
        imageURL: URL? = nil,
        tags: [GoodsTag] = [],
        quantity: Int = 1
    ) {
        self.id = id
        self.ownerID = ownerID
        self.groupID = groupID
        self.memberID = memberID
        self.goodsTypeID = goodsTypeID
        self.title = title
        self.imageURL = imageURL
        self.tags = tags
        self.quantity = quantity
    }
}
