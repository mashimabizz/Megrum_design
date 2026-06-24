import Foundation
import MegrumCore

struct HomeDiscoveryProposalSelection: Equatable, Sendable {
    var receiverGoodsID: UUID
    var receiverGoodsIDs: [UUID]
    var senderGoodsIDs: [UUID]
    var matchType: ProposalMatchType
    var receiverGoods: HomeMockGoods?
    var senderGoods: [HomeMockGoods]
    var exchangeMethod: ExchangeMethod?
    var cashAmount: Int?

    init(
        receiverGoodsID: UUID,
        receiverGoodsIDs: [UUID]? = nil,
        senderGoodsIDs: [UUID],
        matchType: ProposalMatchType,
        receiverGoods: HomeMockGoods? = nil,
        senderGoods: [HomeMockGoods] = [],
        exchangeMethod: ExchangeMethod? = nil,
        cashAmount: Int? = nil
    ) {
        self.receiverGoodsID = receiverGoodsID
        self.receiverGoodsIDs = Self.orderedUnique(receiverGoodsIDs ?? [receiverGoodsID])
        self.senderGoodsIDs = senderGoodsIDs
        self.matchType = matchType
        self.receiverGoods = receiverGoods
        self.senderGoods = senderGoods
        self.exchangeMethod = exchangeMethod
        self.cashAmount = cashAmount.map { max(0, $0) }
    }

    func includingExtraSelections(_ extras: [HomeDiscoveryProposalSelection]) -> HomeDiscoveryProposalSelection {
        guard !extras.isEmpty else {
            return self
        }

        var merged = self
        merged.receiverGoodsIDs = Self.orderedUnique(receiverGoodsIDs + extras.flatMap(\.receiverGoodsIDs))
        merged.senderGoodsIDs = Self.orderedUnique(senderGoodsIDs + extras.flatMap(\.senderGoodsIDs))
        merged.senderGoods = Self.orderedUniqueGoods(senderGoods + extras.flatMap(\.senderGoods))
        if merged.cashAmount == nil {
            merged.cashAmount = extras.first(where: { $0.cashAmount != nil })?.cashAmount
        }
        return merged
    }

    private static func orderedUnique(_ ids: [UUID]) -> [UUID] {
        var seen: Set<UUID> = []
        var result: [UUID] = []
        for id in ids where seen.insert(id).inserted {
            result.append(id)
        }
        return result
    }

    private static func orderedUniqueGoods(_ goods: [HomeMockGoods]) -> [HomeMockGoods] {
        var seen: Set<UUID> = []
        var result: [HomeMockGoods] = []
        for item in goods where seen.insert(item.id).inserted {
            result.append(item)
        }
        return result
    }
}
