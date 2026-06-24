import Foundation
import MegrumCore

struct HomeDiscoveryCandidateSorter: Sendable {
    var conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals]

    func areInCandidateOrder(_ lhs: GoodsItem, _ rhs: GoodsItem) -> Bool {
        sorted(lhs, rhs, rank: candidateRank)
    }

    func areInHavesOrder(_ lhs: GoodsItem, _ rhs: GoodsItem) -> Bool {
        sorted(lhs, rhs, rank: havesRank)
    }

    private func sorted(
        _ lhs: GoodsItem,
        _ rhs: GoodsItem,
        rank: (HomeCandidateConditionSignals?) -> [Int]
    ) -> Bool {
        let lhsRank = rank(conditionSignalsByItemID[lhs.id])
        let rhsRank = rank(conditionSignalsByItemID[rhs.id])
        if lhsRank != rhsRank {
            return rhsRank.lexicographicallyPrecedes(lhsRank)
        }
        return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
    }

    private func candidateRank(_ signals: HomeCandidateConditionSignals?) -> [Int] {
        [
            signals?.tagMatchCount ?? 0,
            goodsConditionRank(signals),
            exchangeConditionRank(signals),
            paymentConditionRank(signals),
            signals?.linkCounts.totalCount ?? 0
        ]
    }

    private func havesRank(_ signals: HomeCandidateConditionSignals?) -> [Int] {
        [
            signals?.linkCounts.listingCount ?? 0,
            signals?.linkCounts.wishCount ?? 0,
            signals?.tagMatchCount ?? 0,
            exchangeConditionRank(signals),
            paymentConditionRank(signals)
        ]
    }

    private func goodsConditionRank(_ signals: HomeCandidateConditionSignals?) -> Int {
        guard let signals else {
            return 0
        }
        switch HomeDiscoveryMatchPolicy.goodsCondition(for: signals.goods) {
        case .direct:
            return 3
        case .wish:
            return 2
        case .none:
            return 1
        }
    }

    private func exchangeConditionRank(_ signals: HomeCandidateConditionSignals?) -> Int {
        guard let signals else {
            return 0
        }
        switch HomeDiscoveryMatchPolicy.exchangeCondition(for: signals.exchange) {
        case .exact:
            return 3
        case .possible:
            return 2
        case .warning:
            return 1
        }
    }

    private func paymentConditionRank(_ signals: HomeCandidateConditionSignals?) -> Int {
        guard let signals else {
            return 0
        }
        switch HomeDiscoveryMatchPolicy.paymentCondition(for: signals.payment) {
        case .compatible:
            return 3
        case .unknown:
            return 2
        case .warning:
            return 1
        }
    }
}
