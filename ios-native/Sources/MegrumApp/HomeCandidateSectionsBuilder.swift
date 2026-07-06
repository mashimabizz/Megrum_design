import Foundation
import MegrumCore
import MegrumData

struct HomeCandidateSectionsBuilder {
    private var matchedItems: [GoodsItem] = []
    private var possibleItems: [GoodsItem] = []
    private var allPartnerItems: [GoodsItem] = []
    private var conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals] = [:]

    mutating func addPartnerCandidate(
        _ candidate: SupabaseHomeGoodsRow,
        context: HomeCandidateCompositionContext
    ) {
        let evaluation = HomeCandidatePartnerOfferEvaluation(candidate: candidate, context: context)
        conditionSignalsByItemID[candidate.id] = evaluation.signals
        allPartnerItems.append(evaluation.candidateItem)

        switch evaluation.bucket {
        case .matched:
            matchedItems.append(evaluation.candidateItem)
        case .possible:
            possibleItems.append(evaluation.candidateItem)
        case .none:
            break
        }
    }

    mutating func addViewerItem(
        _ viewerItem: SupabaseHomeGoodsRow,
        context: HomeCandidateCompositionContext
    ) {
        conditionSignalsByItemID[viewerItem.id] = HomeCandidateViewerOfferSignalsBuilder.signals(
            viewerItem: viewerItem,
            context: context
        )
    }

    func sections(mutualMatchCandidates: [HomeMutualMatchCandidateData]) -> HomeCandidateSections {
        let recentPartnerItems = Array(
            HomeCandidateComposer.deduplicated(allPartnerItems)
                .sorted { ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast) }
                .prefix(12)
        )
        return HomeCandidateSections(
            matchedItems: HomeCandidateComposer.deduplicated(matchedItems),
            possibleItems: HomeCandidateComposer.deduplicated(possibleItems),
            conditionSignalsByItemID: conditionSignalsByItemID,
            mutualMatchCandidates: mutualMatchCandidates,
            recentPartnerItems: recentPartnerItems
        )
    }
}
