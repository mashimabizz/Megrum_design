import Foundation

public struct ListingItemQuantity: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID { itemID }
    public var itemID: UUID
    public var quantity: Int

    public init(itemID: UUID, quantity: Int = 1) {
        self.itemID = itemID
        self.quantity = max(1, quantity)
    }
}

public enum ListingLogic: String, Codable, Sendable, CaseIterable, Identifiable {
    case all = "and"
    case one = "or"
    case atLeast = "at_least"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .all:
            "すべてほしい"
        case .one:
            "どれか1つだけ"
        case .atLeast:
            "何個以上"
        }
    }

    public func displayName(minimumCount: Int) -> String {
        switch self {
        case .all, .one:
            displayName
        case .atLeast:
            Self.minimumCountTitle(minimumCount)
        }
    }

    public static func minimumCountTitle(_ count: Int) -> String {
        "\(max(1, count))個以上"
    }
}

public enum IndividualListingStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case active
    case paused
    case matched
    case closed

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .active:
            "公開中"
        case .paused:
            "一時停止"
        case .matched:
            "成立候補あり"
        case .closed:
            "終了"
        }
    }
}

public enum IndividualListingExchangeType: String, Codable, Sendable, CaseIterable, Identifiable {
    case sameKind = "same_kind"
    case crossKind = "cross_kind"
    case any

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sameKind:
            "同種"
        case .crossKind:
            "異種"
        case .any:
            "同異種OK"
        }
    }
}

public struct IndividualListingWishOption: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var listingID: UUID
    public var position: Int
    public var wishes: [ListingItemQuantity]
    public var logic: ListingLogic
    public var minimumCount: Int
    public var exchangeType: IndividualListingExchangeType
    public var isCashOffer: Bool
    public var cashAmount: Int?
    public var wishGroupID: UUID?
    public var wishGoodsTypeID: UUID?
    /// 条件指定型：対象メンバー（空なら全メンバー）。
    public var wishMemberIDs: [UUID]
    /// true の場合、wishMemberIDs は「これらのメンバー以外」を意味する。
    public var excludesWishMembers: Bool
    /// 条件指定型：対象シリーズ名（タグ）。
    public var wishSeriesNames: [String]
    /// 条件指定型：求める数量。
    public var wishQuantity: Int
    public var createdAt: Date?
    public var updatedAt: Date?

    public init(
        id: UUID,
        listingID: UUID,
        position: Int,
        wishes: [ListingItemQuantity],
        logic: ListingLogic = .one,
        minimumCount: Int = 1,
        exchangeType: IndividualListingExchangeType = .any,
        isCashOffer: Bool = false,
        cashAmount: Int? = nil,
        wishGroupID: UUID? = nil,
        wishGoodsTypeID: UUID? = nil,
        wishMemberIDs: [UUID] = [],
        excludesWishMembers: Bool = false,
        wishSeriesNames: [String] = [],
        wishQuantity: Int = 1,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.listingID = listingID
        self.position = position
        self.wishes = wishes
        self.logic = logic
        self.minimumCount = max(1, minimumCount)
        self.exchangeType = exchangeType
        self.isCashOffer = isCashOffer
        self.cashAmount = cashAmount
        self.wishGroupID = wishGroupID
        self.wishGoodsTypeID = wishGoodsTypeID
        self.wishMemberIDs = wishMemberIDs
        self.excludesWishMembers = excludesWishMembers
        self.wishSeriesNames = wishSeriesNames
        self.wishQuantity = max(1, wishQuantity)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct IndividualListing: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var ownerID: UUID
    public var haves: [ListingItemQuantity]
    public var haveLogic: ListingLogic
    public var haveMinimumCount: Int
    public var haveGroupID: UUID?
    public var haveGoodsTypeID: UUID?
    public var status: IndividualListingStatus
    public var note: String?
    public var options: [IndividualListingWishOption]
    public var createdAt: Date?
    public var updatedAt: Date?

    public init(
        id: UUID,
        ownerID: UUID,
        haves: [ListingItemQuantity],
        haveLogic: ListingLogic = .all,
        haveMinimumCount: Int = 1,
        haveGroupID: UUID? = nil,
        haveGoodsTypeID: UUID? = nil,
        status: IndividualListingStatus = .active,
        note: String? = nil,
        options: [IndividualListingWishOption] = [],
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.ownerID = ownerID
        self.haves = haves
        self.haveLogic = haveLogic
        self.haveMinimumCount = max(1, haveMinimumCount)
        self.haveGroupID = haveGroupID
        self.haveGoodsTypeID = haveGoodsTypeID
        self.status = status
        self.note = note
        self.options = options
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// 個別募集の「求めるもの」選択肢1件分の入力。
/// 先頭の選択肢は `IndividualListingCreateInput` の従来フィールドで表現し、
/// 2件目以降を `additionalOptions` として持つ。
public struct IndividualListingOptionInput: Equatable, Sendable {
    public var wishItems: [ListingItemQuantity]
    public var wishLogic: ListingLogic
    public var wishMinimumCount: Int
    public var exchangeType: IndividualListingExchangeType
    public var isCashOffer: Bool
    public var cashAmount: Int?
    public var wishGroupID: UUID?
    public var wishGoodsTypeID: UUID?
    public var wishMemberIDs: [UUID]
    public var excludesWishMembers: Bool
    public var wishSeriesNames: [String]
    public var wishQuantity: Int

    public init(
        wishItems: [ListingItemQuantity] = [],
        wishLogic: ListingLogic = .one,
        wishMinimumCount: Int = 1,
        exchangeType: IndividualListingExchangeType = .any,
        isCashOffer: Bool = false,
        cashAmount: Int? = nil,
        wishGroupID: UUID? = nil,
        wishGoodsTypeID: UUID? = nil,
        wishMemberIDs: [UUID] = [],
        excludesWishMembers: Bool = false,
        wishSeriesNames: [String] = [],
        wishQuantity: Int = 1
    ) {
        self.wishItems = wishItems
        self.wishLogic = wishLogic
        self.wishMinimumCount = max(1, wishMinimumCount)
        self.exchangeType = exchangeType
        self.isCashOffer = isCashOffer
        self.cashAmount = cashAmount.map { max(0, $0) }
        self.wishGroupID = wishGroupID
        self.wishGoodsTypeID = wishGoodsTypeID
        self.wishMemberIDs = wishMemberIDs
        self.excludesWishMembers = excludesWishMembers
        self.wishSeriesNames = wishSeriesNames
        self.wishQuantity = max(1, wishQuantity)
    }

    public init(option: IndividualListingWishOption) {
        self.init(
            wishItems: option.wishes,
            wishLogic: option.logic,
            wishMinimumCount: option.minimumCount,
            exchangeType: option.exchangeType,
            isCashOffer: option.isCashOffer,
            cashAmount: option.cashAmount,
            wishGroupID: option.wishGroupID,
            wishGoodsTypeID: option.wishGoodsTypeID,
            wishMemberIDs: option.wishMemberIDs,
            excludesWishMembers: option.excludesWishMembers,
            wishSeriesNames: option.wishSeriesNames,
            wishQuantity: option.wishQuantity
        )
    }
}

public struct IndividualListingCreateInput: Equatable, Sendable {
    public var haveItems: [ListingItemQuantity]
    public var haveLogic: ListingLogic
    public var haveMinimumCount: Int
    public var haveIsCashOffer: Bool
    public var haveCashAmount: Int?
    public var wishItems: [ListingItemQuantity]
    public var wishLogic: ListingLogic
    public var wishMinimumCount: Int
    public var exchangeType: IndividualListingExchangeType
    public var isCashOffer: Bool
    public var cashAmount: Int?
    public var wishGroupID: UUID?
    public var wishGoodsTypeID: UUID?
    public var wishMemberIDs: [UUID]
    public var excludesWishMembers: Bool
    public var wishSeriesNames: [String]
    public var wishQuantity: Int
    /// 2件目以降の選択肢（先頭は上の従来フィールド）。
    public var additionalOptions: [IndividualListingOptionInput]
    public var note: String?

    public init(
        haveItems: [ListingItemQuantity],
        haveLogic: ListingLogic = .all,
        haveMinimumCount: Int = 1,
        haveIsCashOffer: Bool = false,
        haveCashAmount: Int? = nil,
        wishItems: [ListingItemQuantity],
        wishLogic: ListingLogic = .one,
        wishMinimumCount: Int = 1,
        exchangeType: IndividualListingExchangeType = .any,
        isCashOffer: Bool = false,
        cashAmount: Int? = nil,
        wishGroupID: UUID? = nil,
        wishGoodsTypeID: UUID? = nil,
        wishMemberIDs: [UUID] = [],
        excludesWishMembers: Bool = false,
        wishSeriesNames: [String] = [],
        wishQuantity: Int = 1,
        additionalOptions: [IndividualListingOptionInput] = [],
        note: String? = nil
    ) {
        self.haveItems = haveItems
        self.haveLogic = haveLogic
        self.haveMinimumCount = max(1, haveMinimumCount)
        self.haveIsCashOffer = haveIsCashOffer
        self.haveCashAmount = haveCashAmount.map { max(0, $0) }
        self.wishItems = wishItems
        self.wishLogic = wishLogic
        self.wishMinimumCount = max(1, wishMinimumCount)
        self.exchangeType = exchangeType
        self.isCashOffer = isCashOffer
        self.cashAmount = cashAmount.map { max(0, $0) }
        self.wishGroupID = wishGroupID
        self.wishGoodsTypeID = wishGoodsTypeID
        self.wishMemberIDs = wishMemberIDs
        self.excludesWishMembers = excludesWishMembers
        self.wishSeriesNames = wishSeriesNames
        self.wishQuantity = max(1, wishQuantity)
        self.additionalOptions = additionalOptions
        self.note = note
    }

    /// 先頭の選択肢を `IndividualListingOptionInput` として取り出す。
    public var primaryOption: IndividualListingOptionInput {
        IndividualListingOptionInput(
            wishItems: wishItems,
            wishLogic: wishLogic,
            wishMinimumCount: wishMinimumCount,
            exchangeType: exchangeType,
            isCashOffer: isCashOffer,
            cashAmount: cashAmount,
            wishGroupID: wishGroupID,
            wishGoodsTypeID: wishGoodsTypeID,
            wishMemberIDs: wishMemberIDs,
            excludesWishMembers: excludesWishMembers,
            wishSeriesNames: wishSeriesNames,
            wishQuantity: wishQuantity
        )
    }
}
