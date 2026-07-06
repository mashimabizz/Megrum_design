import Foundation
import MegrumCore

public struct HomeIndividualListingOfferedItem: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var imageURL: URL?
    public var quantity: Int

    public init(
        id: UUID,
        title: String,
        imageURL: URL? = nil,
        quantity: Int = 1
    ) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank ?? "グッズ"
        self.imageURL = imageURL
        self.quantity = max(1, quantity)
    }
}

public struct HomeIndividualListingDetailContext: Identifiable, Equatable, Sendable {
    public var listingID: UUID
    public var wantedLogic: ListingLogic
    public var offeredLogic: ListingLogic
    public var wantedMinimumCount: Int
    public var offeredMinimumCount: Int
    public var wantedOptions: [HomeIndividualListingWantedOption]
    public var offeredItems: [HomeIndividualListingOfferedItem]
    public var offeredCashAmount: Int?

    public var id: UUID { listingID }

    public init(
        listingID: UUID,
        wantedLogic: ListingLogic = .one,
        offeredLogic: ListingLogic = .all,
        wantedMinimumCount: Int = 1,
        offeredMinimumCount: Int = 1,
        wantedOptions: [HomeIndividualListingWantedOption] = [],
        offeredItems: [HomeIndividualListingOfferedItem] = [],
        offeredCashAmount: Int? = nil
    ) {
        self.listingID = listingID
        self.wantedLogic = wantedLogic
        self.offeredLogic = offeredLogic
        self.wantedMinimumCount = max(1, wantedMinimumCount)
        self.offeredMinimumCount = max(1, offeredMinimumCount)
        self.wantedOptions = wantedOptions
        self.offeredItems = offeredItems
        self.offeredCashAmount = offeredCashAmount.map { max(0, $0) }
    }
}

public struct HomeIndividualListingWantedPreviewItem: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var imageURL: URL?
    public var rawTagNames: [String]

    public init(
        id: UUID,
        title: String,
        imageURL: URL? = nil,
        rawTagNames: [String] = []
    ) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank ?? "グッズ"
        self.imageURL = imageURL
        self.rawTagNames = rawTagNames
    }
}

public struct HomeIndividualListingSelectionContext: Equatable, Sendable {
    public var wantedLogic: ListingLogic
    public var offeredLogic: ListingLogic
    public var wantedMinimumCount: Int
    public var offeredMinimumCount: Int
    public var wantedOptions: [HomeIndividualListingWantedOption]
    public var listingNote: String?
    public var detail: HomeIndividualListingDetailContext?
    /// 個別募集の更新日（候補シートの日時表示用）。
    public var listingUpdatedAt: Date?

    public init(
        wantedLogic: ListingLogic = .one,
        offeredLogic: ListingLogic = .all,
        wantedMinimumCount: Int = 1,
        offeredMinimumCount: Int = 1,
        wantedOptions: [HomeIndividualListingWantedOption] = [],
        listingNote: String? = nil,
        detail: HomeIndividualListingDetailContext? = nil,
        listingUpdatedAt: Date? = nil
    ) {
        self.wantedLogic = wantedLogic
        self.offeredLogic = offeredLogic
        self.wantedMinimumCount = max(1, wantedMinimumCount)
        self.offeredMinimumCount = max(1, offeredMinimumCount)
        self.wantedOptions = wantedOptions
        self.listingNote = listingNote?.nilIfBlank
        self.detail = detail
        self.listingUpdatedAt = listingUpdatedAt
    }

    public static var defaultSelection: HomeIndividualListingSelectionContext {
        HomeIndividualListingSelectionContext()
    }
}

public struct HomeIndividualListingWantedOption: Identifiable, Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case goods
        case condition
        case cash
    }

    public var id: UUID
    public var listingID: UUID
    public var position: Int
    public var title: String
    public var subtitle: String?
    public var logic: ListingLogic
    public var minimumCount: Int
    public var kind: Kind
    public var goodsIDs: [UUID]
    public var matchingGoodsIDs: [UUID]
    public var previewItems: [HomeIndividualListingWantedPreviewItem]
    public var groupID: UUID?
    public var goodsTypeID: UUID?
    public var cashAmount: Int?

    public init(
        id: UUID,
        listingID: UUID,
        position: Int,
        title: String,
        subtitle: String? = nil,
        logic: ListingLogic = .one,
        minimumCount: Int = 1,
        kind: Kind,
        goodsIDs: [UUID] = [],
        matchingGoodsIDs: [UUID] = [],
        previewItems: [HomeIndividualListingWantedPreviewItem] = [],
        groupID: UUID? = nil,
        goodsTypeID: UUID? = nil,
        cashAmount: Int? = nil
    ) {
        self.id = id
        self.listingID = listingID
        self.position = position
        self.title = title
        self.subtitle = subtitle
        self.logic = logic
        self.minimumCount = max(1, minimumCount)
        self.kind = kind
        self.goodsIDs = goodsIDs
        self.matchingGoodsIDs = matchingGoodsIDs
        self.previewItems = previewItems
        self.groupID = groupID
        self.goodsTypeID = goodsTypeID
        self.cashAmount = cashAmount.map { max(0, $0) }
    }

    public var isCashOffer: Bool {
        kind == .cash
    }
}
