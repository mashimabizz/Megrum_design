import Foundation
import MegrumCore

struct ListingRow: Decodable, Sendable {
    static let select = "id,user_id,have_ids,have_qtys,have_logic,have_min_count,have_group_id,have_goods_type_id,status,note,created_at,updated_at"

    var id: UUID
    var userId: UUID
    var haveIds: [UUID]
    var haveQtys: [Int]
    var haveLogic: String
    var haveMinCount: Int?
    var haveGroupId: UUID?
    var haveGoodsTypeId: UUID?
    var status: String
    var note: String?
    var createdAt: Date?
    var updatedAt: Date?

    func listing(options: [IndividualListingWishOption]) -> IndividualListing {
        IndividualListing(
            id: id,
            ownerID: userId,
            haves: itemQuantities(ids: haveIds, quantities: haveQtys),
            haveLogic: ListingLogic(rawValue: haveLogic) ?? .all,
            haveMinimumCount: haveMinCount ?? 1,
            haveGroupID: haveGroupId,
            haveGoodsTypeID: haveGoodsTypeId,
            status: IndividualListingStatus(rawValue: status) ?? .active,
            note: note,
            options: options.sorted { $0.position < $1.position },
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct ListingWishOptionRow: Decodable, Sendable {
    static let select = "id,listing_id,position,wish_ids,wish_qtys,logic,min_count,exchange_type,is_cash_offer,cash_amount,wish_group_id,wish_goods_type_id,created_at,updated_at"

    var id: UUID
    var listingId: UUID
    var position: Int
    var wishIds: [UUID]
    var wishQtys: [Int]
    var logic: String
    var minCount: Int?
    var exchangeType: String
    var isCashOffer: Bool
    var cashAmount: Int?
    var wishGroupId: UUID?
    var wishGoodsTypeId: UUID?
    var createdAt: Date?
    var updatedAt: Date?

    var option: IndividualListingWishOption {
        IndividualListingWishOption(
            id: id,
            listingID: listingId,
            position: position,
            wishes: itemQuantities(ids: wishIds, quantities: wishQtys),
            logic: ListingLogic(rawValue: logic) ?? .one,
            minimumCount: minCount ?? 1,
            exchangeType: IndividualListingExchangeType(rawValue: exchangeType) ?? .any,
            isCashOffer: isCashOffer,
            cashAmount: cashAmount,
            wishGroupID: wishGroupId,
            wishGoodsTypeID: wishGoodsTypeId,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct ListingPayload: Encodable, Sendable {
    var userId: UUID
    var haveIds: [UUID]
    var haveQtys: [Int]
    var haveLogic: String
    var haveMinCount: Int
    var haveIsCashOffer: Bool
    var haveCashAmount: Int?
    var status: String
    var note: String?

    init(userID: UUID, input: IndividualListingCreateInput) {
        self.userId = userID
        self.haveIds = input.haveItems.map(\.itemID)
        self.haveQtys = input.haveItems.map { max(1, min($0.quantity, 99)) }
        self.haveLogic = input.haveLogic.rawValue
        self.haveMinCount = input.haveMinimumCount
        self.haveIsCashOffer = input.haveIsCashOffer
        self.haveCashAmount = input.haveCashAmount
        self.status = IndividualListingStatus.active.rawValue
        self.note = input.note
    }
}

struct ListingStatusPayload: Encodable, Sendable {
    var status: String
}

struct ListingUpdatePayload: Encodable, Sendable {
    private var haveIds: [UUID]?
    private var haveQtys: [Int]?
    private var haveLogic: String?
    private var haveMinCount: Int?
    private var haveIsCashOffer: Bool?
    private var haveCashAmount: Int??
    private var status: String?
    private var note: String??

    init(input: SupabaseListingUpdateInput) throws {
        if let haveItems = input.haveItems {
            self.haveIds = haveItems.map(\.itemID)
            self.haveQtys = haveItems.map { boundedListingQuantity($0.quantity) }
        }
        self.haveLogic = input.haveLogic?.rawValue
        self.haveMinCount = input.haveMinimumCount.map { max(1, $0) }
        self.haveIsCashOffer = input.haveIsCashOffer
        if let haveCashAmount = input.haveCashAmount {
            self.haveCashAmount = .some(max(0, haveCashAmount))
        } else if input.clearsHaveCashAmount {
            self.haveCashAmount = .some(nil)
        }
        self.status = input.status?.rawValue
        if let note = input.note {
            self.note = .some(SupabaseTextNormalizer.optional(note))
        } else if input.clearsNote {
            self.note = .some(nil)
        }

        guard haveIds != nil || haveLogic != nil || haveMinCount != nil || haveIsCashOffer != nil || haveCashAmount != nil || status != nil || note != nil else {
            throw SupabaseListingClientError.emptyUpdate
        }
    }

    enum CodingKeys: String, CodingKey {
        case haveIds
        case haveQtys
        case haveLogic
        case haveMinCount
        case haveIsCashOffer
        case haveCashAmount
        case status
        case note
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(haveIds, forKey: .haveIds)
        try container.encodeIfPresent(haveQtys, forKey: .haveQtys)
        try container.encodeIfPresent(haveLogic, forKey: .haveLogic)
        try container.encodeIfPresent(haveMinCount, forKey: .haveMinCount)
        try container.encodeIfPresent(haveIsCashOffer, forKey: .haveIsCashOffer)
        if let haveCashAmount {
            switch haveCashAmount {
            case let .some(value):
                try container.encode(value, forKey: .haveCashAmount)
            case .none:
                try container.encodeNil(forKey: .haveCashAmount)
            }
        }
        try container.encodeIfPresent(status, forKey: .status)
        if let note {
            switch note {
            case let .some(value):
                try container.encode(value, forKey: .note)
            case .none:
                try container.encodeNil(forKey: .note)
            }
        }
    }
}

struct ListingWishOptionPayload: Encodable, Sendable {
    var listingId: UUID
    var position: Int
    var wishIds: [UUID]
    var wishQtys: [Int]
    var logic: String
    var minCount: Int
    var exchangeType: String
    var isCashOffer: Bool
    var cashAmount: Int?
    var wishGroupId: UUID?
    var wishGoodsTypeId: UUID?

    init(listingID: UUID, position: Int, input: IndividualListingCreateInput) {
        self.init(listingID: listingID, position: position, option: input.primaryOption)
    }

    init(listingID: UUID, position: Int, option: IndividualListingOptionInput) {
        self.listingId = listingID
        self.position = max(1, min(position, 5))
        self.wishIds = option.wishItems.map(\.itemID)
        self.wishQtys = option.wishItems.map { max(1, min($0.quantity, 99)) }
        self.logic = option.wishLogic.rawValue
        self.minCount = option.wishMinimumCount
        self.exchangeType = option.exchangeType.rawValue
        self.isCashOffer = option.isCashOffer
        self.cashAmount = option.cashAmount
        self.wishGroupId = option.wishGroupID
        self.wishGoodsTypeId = option.wishGoodsTypeID
    }
}

struct ListingWishOptionUpdatePayload: Encodable, Sendable {
    private var wishIds: [UUID]?
    private var wishQtys: [Int]?
    private var logic: String?
    private var minCount: Int?
    private var exchangeType: String?
    private var isCashOffer: Bool?
    private var cashAmount: Int??
    private var wishGroupId: UUID??
    private var wishGoodsTypeId: UUID??

    init(input: SupabaseListingWishOptionUpdateInput) throws {
        if let wishItems = input.wishItems {
            self.wishIds = wishItems.map(\.itemID)
            self.wishQtys = wishItems.map { boundedListingQuantity($0.quantity) }
        }
        self.logic = input.logic?.rawValue
        self.minCount = input.minimumCount.map { max(1, $0) }
        self.exchangeType = input.exchangeType?.rawValue
        self.isCashOffer = input.isCashOffer
        if let cashAmount = input.cashAmount {
            self.cashAmount = .some(max(0, cashAmount))
        } else if input.clearsCashAmount {
            self.cashAmount = .some(nil)
        }
        if let wishGroupID = input.wishGroupID {
            self.wishGroupId = .some(wishGroupID)
        } else if input.clearsWishConditionIDs {
            self.wishGroupId = .some(nil)
        }
        if let wishGoodsTypeID = input.wishGoodsTypeID {
            self.wishGoodsTypeId = .some(wishGoodsTypeID)
        } else if input.clearsWishConditionIDs {
            self.wishGoodsTypeId = .some(nil)
        }

        guard wishIds != nil || logic != nil || minCount != nil || exchangeType != nil || isCashOffer != nil || cashAmount != nil || wishGroupId != nil || wishGoodsTypeId != nil else {
            throw SupabaseListingClientError.emptyUpdate
        }
    }

    enum CodingKeys: String, CodingKey {
        case wishIds
        case wishQtys
        case logic
        case minCount
        case exchangeType
        case isCashOffer
        case cashAmount
        case wishGroupId
        case wishGoodsTypeId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(wishIds, forKey: .wishIds)
        try container.encodeIfPresent(wishQtys, forKey: .wishQtys)
        try container.encodeIfPresent(logic, forKey: .logic)
        try container.encodeIfPresent(minCount, forKey: .minCount)
        try container.encodeIfPresent(exchangeType, forKey: .exchangeType)
        try container.encodeIfPresent(isCashOffer, forKey: .isCashOffer)
        if let cashAmount {
            switch cashAmount {
            case let .some(value):
                try container.encode(value, forKey: .cashAmount)
            case .none:
                try container.encodeNil(forKey: .cashAmount)
            }
        }
        if let wishGroupId {
            switch wishGroupId {
            case let .some(value):
                try container.encode(value, forKey: .wishGroupId)
            case .none:
                try container.encodeNil(forKey: .wishGroupId)
            }
        }
        if let wishGoodsTypeId {
            switch wishGoodsTypeId {
            case let .some(value):
                try container.encode(value, forKey: .wishGoodsTypeId)
            case .none:
                try container.encodeNil(forKey: .wishGoodsTypeId)
            }
        }
    }
}

private func itemQuantities(ids: [UUID], quantities: [Int]) -> [ListingItemQuantity] {
    ids.enumerated().map { index, id in
        ListingItemQuantity(itemID: id, quantity: quantities.indices.contains(index) ? quantities[index] : 1)
    }
}

private func boundedListingQuantity(_ quantity: Int) -> Int {
    max(1, min(quantity, 99))
}
