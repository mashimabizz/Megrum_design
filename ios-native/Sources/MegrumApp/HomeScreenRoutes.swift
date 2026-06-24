import Foundation
import MegrumCore

enum HomeMatchShelfKind: Equatable {
    case matched
    case possible
}

enum HomeGoodsPanelDestination: Equatable {
    case relation(ProposalMatchType)
}

enum HomeGoodsPanelRouteResolver {
    static func destination(for shelfKind: HomeMatchShelfKind) -> HomeGoodsPanelDestination {
        switch shelfKind {
        case .matched:
            .relation(.perfect)
        case .possible:
            .relation(.forward)
        }
    }
}

enum HomeGroomRailPolicy {
    static let isVisibleOnHome = false
}

enum HomeRelationVisualQARouteResolver {
    static func targetItem(candidates: [GoodsItem], viewerID: UUID?) -> GoodsItem? {
        candidates.first { item in
            guard let viewerID else {
                return false
            }
            return item.ownerID != viewerID
        } ?? candidates.first
    }
}

struct HomeRelationRoute: Identifiable, Equatable {
    var item: GoodsItem
    var matchType: ProposalMatchType

    var id: UUID { item.id }
}

struct HomeProposalRoute: Identifiable, Equatable {
    var id = UUID()
    var item: GoodsItem
    var receiverGoodsIDs: [UUID]
    var senderGoodsIDs: [UUID]
    var matchType: ProposalMatchType
    var initialExchangeMethod: ExchangeMethod?
    var initialCashAmount: Int?
    var initialStep: ProposalCreateStep
}

enum HomeDiscoveryProposalRouteResolver {
    static func route(
        selection: HomeDiscoveryProposalSelection,
        viewerID: UUID?,
        matchedItems: [GoodsItem],
        possibleItems: [GoodsItem],
        inventoryItems: [GoodsItem]
    ) -> HomeProposalRoute? {
        guard let targetItem = proposalTargetItem(
            for: selection,
            viewerID: viewerID,
            matchedItems: matchedItems,
            possibleItems: possibleItems
        ) else {
            return nil
        }

        return HomeProposalRoute(
            item: targetItem,
            receiverGoodsIDs: receiverGoodsIDs(for: selection, targetItem: targetItem),
            senderGoodsIDs: validSenderGoodsIDs(
                selection.senderGoodsIDs,
                viewerID: viewerID,
                inventoryItems: inventoryItems
            ),
            matchType: selection.matchType,
            initialExchangeMethod: selection.exchangeMethod,
            initialCashAmount: selection.cashAmount,
            initialStep: .give
        )
    }

    private static func proposalTargetItem(
        for selection: HomeDiscoveryProposalSelection,
        viewerID: UUID?,
        matchedItems: [GoodsItem],
        possibleItems: [GoodsItem]
    ) -> GoodsItem? {
        let selectedGoodsItem = selection.receiverGoods.flatMap { goodsItem(from: $0) }
        let candidates = MatchRelationComposer.deduplicatedGoods(
            [selectedGoodsItem].compactMap(\.self) + matchedItems + possibleItems
        )
        if let target = candidates.first(where: { item in
            item.id == selection.receiverGoodsID && item.ownerID != viewerID
        }) {
            return target
        }
        return candidates.first { $0.ownerID != viewerID }
    }

    private static func receiverGoodsIDs(
        for selection: HomeDiscoveryProposalSelection,
        targetItem: GoodsItem
    ) -> [UUID] {
        var seen: Set<UUID> = []
        var result: [UUID] = []
        for id in [targetItem.id] + selection.receiverGoodsIDs where seen.insert(id).inserted {
            result.append(id)
        }
        return result
    }

    private static func validSenderGoodsIDs(
        _ ids: [UUID],
        viewerID: UUID?,
        inventoryItems: [GoodsItem]
    ) -> [UUID] {
        let validIDs = Set(
            MatchRelationComposer
                .selectableSenderGoods(from: inventoryItems)
                .filter { item in
                    guard let viewerID else {
                        return true
                    }
                    return item.ownerID == viewerID
                }
                .map(\.id)
        )
        return ids.filter { validIDs.contains($0) }
    }

    private static func goodsItem(from goods: HomeMockGoods) -> GoodsItem? {
        let ownerID = goods.ownerID ?? HomeDiscoveryFixtures.ownerID
        return GoodsItem(
            id: goods.id,
            ownerID: ownerID,
            groupID: goods.groupID,
            memberID: goods.memberID,
            goodsTypeID: goods.goodsTypeID,
            title: goods.title,
            imageURL: goods.imageURL,
            tags: goods.rawTagNames.map { GoodsTag(id: stableTagID(for: $0), name: $0) },
            quantity: 1,
            ownerPrefecture: goods.ownerPrefecture,
            ownerDisplayName: goods.ownerDisplayName,
            ownerHandle: goods.ownerHandle,
            ownerAvatarURL: goods.ownerAvatarURL,
            ownerGender: goods.ownerGender,
            ownerAge: goods.ownerAge,
            ownerAverageStars: goods.ownerAverageStars,
            ownerEvaluationCount: goods.ownerEvaluationCount,
            ownerCompletedTradeCount: goods.ownerCompletedTradeCount,
            ownerPaymentMethods: goods.ownerPaymentMethods,
            ownerPaymentNote: goods.ownerPaymentNote
        )
    }

    private static func stableTagID(for name: String) -> UUID {
        let hash = name
            .lowercased()
            .utf8
            .reduce(UInt64(14_695_981_039_346_656_037)) { partial, byte in
                (partial ^ UInt64(byte)).multipliedReportingOverflow(by: 1_099_511_628_211).partialValue
            }
        let tail = String(format: "%012llu", hash % 1_000_000_000_000)
        return UUID(uuidString: "00000000-0000-0000-0000-\(tail)") ?? UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    }
}

private extension ExchangeMethod {
    var requiresMeetupBeforeProposal: Bool {
        self == .hand || self == .both
    }
}
