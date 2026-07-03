import Foundation
import MegrumCore
import MegrumData

struct HomeCandidateSectionsBuilder {
    private var matchedItems: [GoodsItem] = []
    private var possibleItems: [GoodsItem] = []
    private var conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals] = [:]

    mutating func addPartnerCandidate(
        _ candidate: SupabaseHomeGoodsRow,
        context: HomeCandidateCompositionContext
    ) {
        let evaluation = HomeCandidatePartnerOfferEvaluation(candidate: candidate, context: context)
        conditionSignalsByItemID[candidate.id] = evaluation.signals

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
        HomeCandidateSections(
            matchedItems: HomeCandidateComposer.deduplicated(matchedItems),
            possibleItems: HomeCandidateComposer.deduplicated(possibleItems),
            conditionSignalsByItemID: conditionSignalsByItemID,
            mutualMatchCandidates: mutualMatchCandidates
        )
    }
}
