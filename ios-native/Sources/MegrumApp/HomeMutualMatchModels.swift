import Foundation
import MegrumCore

public enum HomeMutualMatchAttentionKind: String, Equatable, Sendable {
    case ready
    case tagMismatch
    case amountIncluded
    case amountInsufficient
    case exchangeMethodMismatch
    case prefectureNeedsDiscussion
    case dateNeedsDiscussion
    case prefectureUnset
    case shippingFeeNeedsDiscussion
    case paymentMethodMismatch
    case viewerPaymentUnset
    case partnerPaymentUnset
    case paymentUnset
    case paymentMethodNeedsDiscussion
}

public enum HomeMutualMatchDisplayItemKind: String, Equatable, Sendable {
    case goods
    case fixedPrice
    case cashAmount
}

public struct HomeMutualMatchDisplayItemData: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var kind: HomeMutualMatchDisplayItemKind
    public var title: String
    public var subtitle: String?
    public var goodsItem: GoodsItem?
    public var cashAmount: Int?

    public init(
        id: UUID,
        kind: HomeMutualMatchDisplayItemKind,
        title: String,
        subtitle: String? = nil,
        goodsItem: GoodsItem? = nil,
        cashAmount: Int? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.goodsItem = goodsItem
        self.cashAmount = cashAmount.map { max(0, $0) }
    }

    public static func goods(_ item: GoodsItem) -> HomeMutualMatchDisplayItemData {
        HomeMutualMatchDisplayItemData(
            id: item.id,
            kind: .goods,
            title: item.title,
            subtitle: item.kind?.inventoryKind,
            goodsItem: item
        )
    }

    public static func cash(id: UUID, amount: Int?) -> HomeMutualMatchDisplayItemData {
        if let amount {
            return HomeMutualMatchDisplayItemData(
                id: id,
                kind: .cashAmount,
                title: TradeAmountFormatter.compactYen(amount),
                subtitle: "金額指定",
                cashAmount: amount
            )
        }

        return HomeMutualMatchDisplayItemData(
            id: id,
            kind: .fixedPrice,
            title: "定価",
            subtitle: "金額条件"
        )
    }
}

public struct HomeMutualMatchCandidateData: Identifiable, Equatable, Sendable {
    public var id: UUID
    public var partnerID: UUID?
    public var partnerName: String
    public var partnerHandle: String
    public var partnerInitial: String
    public var partnerArea: String
    public var partnerOshiText: String
    public var partnerAgeRangeText: String?
    public var partnerEvaluationSummaryText: String?
    public var partnerGoodsItems: [GoodsItem]
    public var viewerGoodsItems: [GoodsItem]
    public var partnerDisplayItems: [HomeMutualMatchDisplayItemData]
    public var viewerDisplayItems: [HomeMutualMatchDisplayItemData]
    public var signals: HomeCandidateConditionSignals
    public var conditionSignalsByPartnerGoodsID: [UUID: HomeCandidateConditionSignals]
    public var attentionKinds: [HomeMutualMatchAttentionKind]

    public init(
        id: UUID,
        partnerID: UUID?,
        partnerName: String,
        partnerHandle: String,
        partnerInitial: String,
        partnerArea: String,
        partnerOshiText: String,
        partnerAgeRangeText: String? = nil,
        partnerEvaluationSummaryText: String? = nil,
        partnerGoodsItems: [GoodsItem],
        viewerGoodsItems: [GoodsItem],
        partnerDisplayItems: [HomeMutualMatchDisplayItemData] = [],
        viewerDisplayItems: [HomeMutualMatchDisplayItemData] = [],
        signals: HomeCandidateConditionSignals,
        conditionSignalsByPartnerGoodsID: [UUID: HomeCandidateConditionSignals] = [:],
        attentionKinds: [HomeMutualMatchAttentionKind]
    ) {
        self.id = id
        self.partnerID = partnerID
        self.partnerName = partnerName
        self.partnerHandle = partnerHandle
        self.partnerInitial = partnerInitial
        self.partnerArea = partnerArea
        self.partnerOshiText = partnerOshiText
        self.partnerAgeRangeText = partnerAgeRangeText
        self.partnerEvaluationSummaryText = partnerEvaluationSummaryText
        self.partnerGoodsItems = partnerGoodsItems
        self.viewerGoodsItems = viewerGoodsItems
        self.partnerDisplayItems = partnerDisplayItems.isEmpty
            ? partnerGoodsItems.map(HomeMutualMatchDisplayItemData.goods)
            : partnerDisplayItems
        self.viewerDisplayItems = viewerDisplayItems.isEmpty
            ? viewerGoodsItems.map(HomeMutualMatchDisplayItemData.goods)
            : viewerDisplayItems
        self.signals = signals
        self.conditionSignalsByPartnerGoodsID = conditionSignalsByPartnerGoodsID
        self.attentionKinds = attentionKinds
    }
}

struct HomeMutualMatchProposalItem: Identifiable, Equatable {
    var data: HomeMutualMatchDisplayItemData
    var goods: HomeMockGoods?

    var id: UUID { data.id }
    var title: String { data.title }
    var subtitle: String { data.subtitle ?? "" }
    var cashAmount: Int? { data.cashAmount }

    var isGoods: Bool {
        data.kind == .goods
    }

    static func goods(_ goods: HomeMockGoods) -> HomeMutualMatchProposalItem {
        HomeMutualMatchProposalItem(
            data: HomeMutualMatchDisplayItemData(
                id: goods.id,
                kind: .goods,
                title: goods.title,
                subtitle: goods.subtitle
            ),
            goods: goods
        )
    }
}

struct HomeMutualMatchCandidate: Identifiable, Equatable {
    var id: UUID
    var partnerID: UUID?
    var partnerName: String
    var partnerHandle: String
    var partnerInitial: String
    var partnerArea: String
    var partnerOshiText: String
    var partnerAgeRangeText: String?
    var partnerEvaluationSummaryText: String?
    var partnerGoodsItems: [GoodsItem]
    var viewerGoodsItems: [GoodsItem]
    var partnerDisplayItems: [HomeMutualMatchProposalItem]
    var viewerDisplayItems: [HomeMutualMatchProposalItem]
    var signals: HomeCandidateConditionSignals
    var conditionSignalsByPartnerGoodsID: [UUID: HomeCandidateConditionSignals] = [:]
    var attentionTags: [HomeMutualMatchAttentionTag]

    var requestedGoodsBadgeTitle: String? {
        HomeMutualMatchGoodsLogicBadgePolicy.badgeTitle(
            logic: signals.individualListingSelection?.offeredLogic ?? .all,
            itemCount: partnerGoodsItems.count
        )
    }

    var offeredGoodsBadgeTitle: String? {
        HomeMutualMatchGoodsLogicBadgePolicy.badgeTitle(
            logic: signals.individualListingSelection?.wantedLogic ?? .one,
            itemCount: viewerGoodsItems.count
        )
    }

    var partnerMetaText: String {
        [partnerArea, partnerAgeRangeText, partnerEvaluationSummaryText]
            .compactMap(Self.trimmed)
            .joined(separator: " ・ ")
    }

    private static func trimmed(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

enum HomeMutualMatchGoodsLogicBadgePolicy {
    static func badgeTitle(logic: ListingLogic, itemCount: Int) -> String? {
        guard itemCount > 1 else {
            return nil
        }

        switch logic {
        case .all:
            return "セット"
        case .one:
            return "どれか1つ"
        case .atLeast:
            return "複数"
        }
    }
}

struct HomeMutualMatchProposalPair: Identifiable, Equatable {
    var id: String
    var receiverGoods: HomeMockGoods
    var senderGoods: HomeMockGoods
    var receiverDisplayItem: HomeMutualMatchProposalItem
    var senderDisplayItem: HomeMutualMatchProposalItem
    var signals: HomeCandidateConditionSignals

    var sheet: HomeDiscoverySheet {
        .goodsHit(
            HomeDiscoverySheetPayload(
                goods: receiverGoods,
                signals: signals,
                preferredOfferGoodsID: senderGoods.id
            )
        )
    }

    var conditionTags: HomeConditionTagSet {
        HomeConditionTagSet(signals: signals)
    }

    var proposalCashAmount: Int? {
        senderDisplayItem.cashAmount
    }
}
