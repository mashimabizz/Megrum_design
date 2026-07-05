import Foundation

public struct SupabaseHomeListingRow: Decodable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var userId: UUID
    public var haveIds: [UUID]
    public var haveQtys: [Int]
    public var haveLogic: String?
    public var haveMinCount: Int?
    public var haveGroupId: UUID?
    public var haveGoodsTypeId: UUID?
    public var status: String?
    public var note: String?
    public var createdAt: Date?
    public var updatedAt: Date?

    enum CodingKeys: CodingKey {
        case id
        case userId
        case haveIds
        case haveQtys
        case haveLogic
        case haveMinCount
        case haveGroupId
        case haveGoodsTypeId
        case status
        case note
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.userId = try container.decode(UUID.self, forKey: .userId)
        self.haveIds = try container.decodeIfPresent([UUID].self, forKey: .haveIds) ?? []
        self.haveQtys = try container.decodeIfPresent([Int].self, forKey: .haveQtys) ?? []
        self.haveLogic = try container.decodeIfPresent(String.self, forKey: .haveLogic)
        self.haveMinCount = try container.decodeIfPresent(Int.self, forKey: .haveMinCount)
        self.haveGroupId = try container.decodeIfPresent(UUID.self, forKey: .haveGroupId)
        self.haveGoodsTypeId = try container.decodeIfPresent(UUID.self, forKey: .haveGoodsTypeId)
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
        self.note = try container.decodeIfPresent(String.self, forKey: .note)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

public struct SupabaseHomeListingWishOptionRow: Decodable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var listingId: UUID
    public var position: Int
    public var wishIds: [UUID]
    public var wishQtys: [Int]
    public var logic: String?
    public var minCount: Int?
    public var exchangeType: String?
    public var isCashOffer: Bool?
    public var cashAmount: Int?
    public var wishGroupId: UUID?
    public var wishGoodsTypeId: UUID?
    public var wishMemberIds: [UUID]
    public var excludesWishMembers: Bool
    public var wishSeriesNames: [String]
    public var wishQuantity: Int
    public var createdAt: Date?
    public var updatedAt: Date?

    enum CodingKeys: CodingKey {
        case id
        case listingId
        case position
        case wishIds
        case wishQtys
        case logic
        case minCount
        case exchangeType
        case isCashOffer
        case cashAmount
        case wishGroupId
        case wishGoodsTypeId
        case wishMemberIds
        case excludesWishMembers
        case wishSeriesNames
        case wishQuantity
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.listingId = try container.decode(UUID.self, forKey: .listingId)
        self.position = try container.decode(Int.self, forKey: .position)
        self.wishIds = try container.decodeIfPresent([UUID].self, forKey: .wishIds) ?? []
        self.wishQtys = try container.decodeIfPresent([Int].self, forKey: .wishQtys) ?? []
        self.logic = try container.decodeIfPresent(String.self, forKey: .logic)
        self.minCount = try container.decodeIfPresent(Int.self, forKey: .minCount)
        self.exchangeType = try container.decodeIfPresent(String.self, forKey: .exchangeType)
        self.isCashOffer = try container.decodeIfPresent(Bool.self, forKey: .isCashOffer)
        self.cashAmount = try container.decodeIfPresent(Int.self, forKey: .cashAmount)
        self.wishGroupId = try container.decodeIfPresent(UUID.self, forKey: .wishGroupId)
        self.wishGoodsTypeId = try container.decodeIfPresent(UUID.self, forKey: .wishGoodsTypeId)
        self.wishMemberIds = try container.decodeIfPresent([UUID].self, forKey: .wishMemberIds) ?? []
        self.excludesWishMembers = try container.decodeIfPresent(Bool.self, forKey: .excludesWishMembers) ?? false
        self.wishSeriesNames = try container.decodeIfPresent([String].self, forKey: .wishSeriesNames) ?? []
        self.wishQuantity = try container.decodeIfPresent(Int.self, forKey: .wishQuantity) ?? 1
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

extension SupabaseHomeListingRow {
    static let select = "id,user_id,have_ids,have_qtys,have_logic,have_min_count,have_group_id,have_goods_type_id,status,note,created_at,updated_at"
}

extension SupabaseHomeListingWishOptionRow {
    static let select = "id,listing_id,position,wish_ids,wish_qtys,logic,min_count,exchange_type,is_cash_offer,cash_amount,wish_group_id,wish_goods_type_id,wish_member_ids,excludes_wish_members,wish_series_names,wish_quantity,created_at,updated_at"
}
