import Foundation
import MegrumCore
import MegrumData

struct HomeMutualMatchExchangeEvaluation: Equatable {
    var signals: HomeExchangeConditionSignals
    var attentionKinds: [HomeMutualMatchAttentionKind]
}

enum HomeMutualMatchConditionPolicy {
    static func exchangeEvaluation(
        viewerListing: SupabaseHomeListingRow,
        viewerUser: SupabaseHomeUserRow?,
        partnerListing: SupabaseHomeListingRow,
        partnerUser: SupabaseHomeUserRow?
    ) -> HomeMutualMatchExchangeEvaluation {
        let viewerSummary = exchangeSummary(for: viewerListing, user: viewerUser)
        let partnerSummary = exchangeSummary(for: partnerListing, user: partnerUser)
        let routeEvaluations = commonRoutes(viewerSummary.handoffMethod, partnerSummary.handoffMethod)
            .map { route in
                switch route {
                case .local:
                    localEvaluation(viewerSummary: viewerSummary, partnerSummary: partnerSummary)
                case .mail:
                    mailEvaluation(viewerSummary: viewerSummary, partnerSummary: partnerSummary)
                }
            }
        let localRouteEvaluation = routeEvaluations.first { $0.route == .local }

        guard let best = routeEvaluations.sorted(by: routeEvaluationSorter).first else {
            return HomeMutualMatchExchangeEvaluation(
                signals: HomeExchangeConditionSignals(
                    postalAcceptedByBoth: false,
                    localExchangeSelected: false,
                    prefectureMatches: false,
                    dateMatches: false,
                    viewerExchangeMethodTitle: viewerSummary.handoffMethod.title,
                    partnerExchangeMethodTitle: partnerSummary.handoffMethod.title,
                    viewerLocalConditionText: localConditionText(for: viewerSummary),
                    partnerLocalConditionText: localConditionText(for: partnerSummary),
                    viewerShippingFeeTitle: mailConditionText(for: viewerSummary),
                    partnerShippingFeeTitle: mailConditionText(for: partnerSummary)
                ),
                attentionKinds: [.exchangeMethodMismatch]
            )
        }

        return HomeMutualMatchExchangeEvaluation(
            signals: signals(best.signals, carryingLocalRouteFrom: localRouteEvaluation),
            attentionKinds: best.attentionKinds
        )
    }
}
