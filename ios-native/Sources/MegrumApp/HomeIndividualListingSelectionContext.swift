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

/// 指名オプションの「相手のほしいもの1件」と、それに充てられる自分の候補グッズの対応。iter1226.373（候補シート再設計）。
/// 相手希望（相手のほしいもの画像）→ 譲る（自分の候補）を1対1で見せるための供給データ。
public struct HomeWantedNamedPairing: Identifiable, Equatable, Sendable {
    /// 相手のほしいもの（指名）のID。
    public var id: UUID
    public var title: String
    public var imageURL: URL?
    public var characterID: UUID?
    /// この指名を満たせる自分の候補グッズID（メンバー・種別・シリーズ一致で判定）。
    public var candidateGoodsIDs: [UUID]

    public init(
        id: UUID,
        title: String,
        imageURL: URL? = nil,
        characterID: UUID? = nil,
        candidateGoodsIDs: [UUID] = []
    ) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.characterID = characterID
        self.candidateGoodsIDs = candidateGoodsIDs
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
    /// matchingGoodsIDs のうち、シリーズ等が無記載で「確定」できない（＝不確定「？」）分。iter1226.363。
    public var tentativeGoodsIDs: [UUID]
    public var previewItems: [HomeIndividualListingWantedPreviewItem]
    public var groupID: UUID?
    public var goodsTypeID: UUID?
    public var cashAmount: Int?
    /// 条件指定型の選択肢の内容（例「TWICE / トレカ / #DICON…」）。マッチしたグッズ名ではなく募集の条件そのもの。iter1226.371。
    public var conditionSummary: String?
    /// 指名オプションの「相手のほしいもの1件 → 自分の候補」対応。条件/現金では空。iter1226.373。
    public var namedPairings: [HomeWantedNamedPairing]

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
        tentativeGoodsIDs: [UUID] = [],
        previewItems: [HomeIndividualListingWantedPreviewItem] = [],
        groupID: UUID? = nil,
        goodsTypeID: UUID? = nil,
        cashAmount: Int? = nil,
        conditionSummary: String? = nil,
        namedPairings: [HomeWantedNamedPairing] = []
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
        self.tentativeGoodsIDs = tentativeGoodsIDs
        self.previewItems = previewItems
        self.groupID = groupID
        self.goodsTypeID = goodsTypeID
        self.cashAmount = cashAmount.map { max(0, $0) }
        self.conditionSummary = conditionSummary
        self.namedPairings = namedPairings
    }

    public var isCashOffer: Bool {
        kind == .cash
    }
}
