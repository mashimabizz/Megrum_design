import Foundation
import MegrumCore

enum HomeMutualMatchCandidateFactory {
    static func candidates(
        mutualMatchData: [HomeMutualMatchCandidateData] = [],
        viewerID: UUID?,
        inventoryItems: [GoodsItem],
        matchedItems: [GoodsItem],
        possibleItems: [GoodsItem],
        goodsTypes: [GoodsType],
        conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals]
    ) -> [HomeMutualMatchCandidate] {
        if !mutualMatchData.isEmpty {
            return mutualMatchData.map { candidate(from: $0, goodsTypes: goodsTypes) }
        }
        return []
    }

    private static func candidate(
        from data: HomeMutualMatchCandidateData,
        goodsTypes: [GoodsType]
    ) -> HomeMutualMatchCandidate {
        HomeMutualMatchCandidate(
            id: data.id,
            partnerID: data.partnerID,
            partnerName: data.partnerName,
            partnerHandle: data.partnerHandle,
            partnerInitial: data.partnerInitial,
            partnerArea: data.partnerArea,
            partnerOshiText: data.partnerOshiText,
            partnerAgeRangeText: data.partnerAgeRangeText,
            partnerEvaluationSummaryText: data.partnerEvaluationSummaryText,
            partnerGoodsItems: data.partnerGoodsItems,
            viewerGoodsItems: data.viewerGoodsItems,
            partnerDisplayItems: displayItems(from: data.partnerDisplayItems, goodsTypes: goodsTypes),
            viewerDisplayItems: displayItems(from: data.viewerDisplayItems, goodsTypes: goodsTypes),
            signals: data.signals,
            conditionSignalsByPartnerGoodsID: data.conditionSignalsByPartnerGoodsID,
            attentionTags: attentionTags(for: data.attentionKinds)
        )
    }

    private static func displayItems(
        from data: [HomeMutualMatchDisplayItemData],
        goodsTypes: [GoodsType]
    ) -> [HomeMutualMatchProposalItem] {
        data.enumerated().map { index, item in
            HomeMutualMatchProposalItem(
                data: item,
                goods: item.goodsItem.map { HomeMockGoods.from(item: $0, index: index, goodsTypes: goodsTypes) }
            )
        }
    }

    private static func attentionTags(for kinds: [HomeMutualMatchAttentionKind]) -> [HomeMutualMatchAttentionTag] {
        var seen: Set<HomeMutualMatchAttentionKind> = []
        var tags: [HomeMutualMatchAttentionTag] = []
        for kind in kinds where seen.insert(kind).inserted {
            switch kind {
            case .ready:
                tags.append(.ready)
            case .tagMismatch:
                tags.append(.tagMismatch)
            case .amountIncluded:
                tags.append(.amountIncluded)
            case .amountInsufficient:
                tags.append(.amountInsufficient)
            case .exchangeMethodMismatch:
                tags.append(.exchangeMethodMismatch)
            case .prefectureNeedsDiscussion:
                tags.append(.prefectureNeedsDiscussion)
            case .dateNeedsDiscussion:
                tags.append(.dateNeedsDiscussion)
            case .prefectureUnset:
                tags.append(.prefectureUnset)
            case .shippingFeeNeedsDiscussion:
                tags.append(.shippingFeeNeedsDiscussion)
            case .paymentMethodMismatch:
                tags.append(.paymentMethodMismatch)
            case .viewerPaymentUnset:
                tags.append(.viewerPaymentUnset)
            case .partnerPaymentUnset:
                tags.append(.partnerPaymentUnset)
            case .paymentUnset:
                tags.append(.paymentUnset)
            case .paymentMethodNeedsDiscussion:
                tags.append(.paymentMethodNeedsDiscussion)
            }
        }
        return tags.isEmpty ? [.ready] : tags
    }
}

enum HomeMutualMatchProposalPairFactory {
    static func pairs(
        for candidate: HomeMutualMatchCandidate,
        in candidates: [HomeMutualMatchCandidate],
        goodsTypes: [GoodsType]
    ) -> [HomeMutualMatchProposalPair] {
        let relatedCandidates = Self.relatedCandidates(to: candidate, in: candidates)
        var seen: Set<String> = []
        var result: [HomeMutualMatchProposalPair] = []

        for relatedCandidate in relatedCandidates {
            for pair in pairs(for: relatedCandidate, goodsTypes: goodsTypes) where seen.insert(pair.id).inserted {
                result.append(pair)
            }
        }

        return result
    }

    private static func relatedCandidates(
        to candidate: HomeMutualMatchCandidate,
        in candidates: [HomeMutualMatchCandidate]
    ) -> [HomeMutualMatchCandidate] {
        let related = candidates.filter { other in
            if let partnerID = candidate.partnerID {
                return other.partnerID == partnerID
            }
            return other.partnerHandle == candidate.partnerHandle
        }
        return related.isEmpty ? [candidate] : related
    }

    private static func pairs(
        for candidate: HomeMutualMatchCandidate,
        goodsTypes: [GoodsType]
    ) -> [HomeMutualMatchProposalPair] {
        guard let fallbackReceiverItem = candidate.partnerGoodsItems.first,
              let fallbackSenderItem = candidate.viewerGoodsItems.first
        else {
            return []
        }

        let receiverFallbackGoods = HomeMockGoods.from(item: fallbackReceiverItem, index: 0, goodsTypes: goodsTypes)
        let senderFallbackGoods = HomeMockGoods.from(item: fallbackSenderItem, index: 20, goodsTypes: goodsTypes)
        let receiverItems = nonEmpty(candidate.partnerDisplayItems, fallback: [
            HomeMutualMatchProposalItem(
                data: .goods(fallbackReceiverItem),
                goods: receiverFallbackGoods
            )
        ])
        let senderItems = nonEmpty(candidate.viewerDisplayItems, fallback: [
            HomeMutualMatchProposalItem(
                data: .goods(fallbackSenderItem),
                goods: senderFallbackGoods
            )
        ])
        let pairCount = max(receiverItems.count, senderItems.count)

        return (0..<pairCount).compactMap { index in
            let receiverDisplayItem = receiverItems.indices.contains(index) ? receiverItems[index] : receiverItems[0]
            let senderDisplayItem = senderItems.indices.contains(index) ? senderItems[index] : senderItems[0]
            let receiverGoods = receiverDisplayItem.goods ?? receiverFallbackGoods
            let senderGoods = senderDisplayItem.goods ?? senderFallbackGoods
            let signals = candidate.conditionSignalsByPartnerGoodsID[receiverGoods.id] ?? candidate.signals
            return HomeMutualMatchProposalPair(
                id: "\(receiverDisplayItem.id.uuidString)-\(senderDisplayItem.id.uuidString)",
                receiverGoods: receiverGoods,
                senderGoods: senderGoods,
                receiverDisplayItem: receiverDisplayItem,
                senderDisplayItem: senderDisplayItem,
                signals: signals
            )
        }
    }

    private static func nonEmpty(
        _ items: [HomeMutualMatchProposalItem],
        fallback: [HomeMutualMatchProposalItem]
    ) -> [HomeMutualMatchProposalItem] {
        items.isEmpty ? fallback : items
    }
}
