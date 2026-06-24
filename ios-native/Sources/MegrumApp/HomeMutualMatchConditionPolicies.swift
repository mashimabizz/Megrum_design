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

    private enum ExchangeRoute: Int {
        case local
        case mail
    }

    private struct RouteEvaluation {
        var route: ExchangeRoute
        var signals: HomeExchangeConditionSignals
        var attentionKinds: [HomeMutualMatchAttentionKind]

        var score: Int {
            attentionKinds.reduce(0) { result, kind in
                result + issueWeight(kind)
            }
        }
    }

    private static func exchangeSummary(
        for listing: SupabaseHomeListingRow,
        user: SupabaseHomeUserRow?
    ) -> IndividualListingExchangeSummary {
        if let summary = IndividualListingExchangeSummary.extract(from: listing.note).summary {
            return summary
        }

        return IndividualListingExchangeSummary(
            localPrefecture: user?.primaryArea ?? ""
        )
    }

    private static func commonRoutes(
        _ lhs: IndividualListingHandoffDraft,
        _ rhs: IndividualListingHandoffDraft
    ) -> [ExchangeRoute] {
        let lhsRoutes = routes(for: lhs)
        let rhsRoutes = routes(for: rhs)
        return [.local, .mail].filter { lhsRoutes.contains($0) && rhsRoutes.contains($0) }
    }

    private static func routes(for method: IndividualListingHandoffDraft) -> Set<ExchangeRoute> {
        switch method {
        case .local:
            return [.local]
        case .mail:
            return [.mail]
        case .both:
            return [.local, .mail]
        }
    }

    private static func localEvaluation(
        viewerSummary: IndividualListingExchangeSummary,
        partnerSummary: IndividualListingExchangeSummary
    ) -> RouteEvaluation {
        let viewerPrefecture = normalizedSettingText(
            viewerSummary.localPrefecture,
            emptyMarkers: ["未設定"]
        )
        let partnerPrefecture = normalizedSettingText(
            partnerSummary.localPrefecture,
            emptyMarkers: ["未設定"]
        )
        let prefectureUnset = viewerPrefecture == nil || partnerPrefecture == nil
        let prefectureMatches = !prefectureUnset && viewerPrefecture == partnerPrefecture
        let dateMatches = schedulesMatch(viewerSummary.localSchedule, partnerSummary.localSchedule)
        let dateNeedsDiscussion = schedulesNeedDiscussion(viewerSummary.localSchedule, partnerSummary.localSchedule)
        var attentionKinds: [HomeMutualMatchAttentionKind] = []

        if prefectureUnset {
            attentionKinds.append(.prefectureUnset)
        } else if !prefectureMatches {
            attentionKinds.append(.prefectureNeedsDiscussion)
        }

        if !prefectureUnset && (!dateMatches || dateNeedsDiscussion) {
            attentionKinds.append(.dateNeedsDiscussion)
        }

        return RouteEvaluation(
            route: .local,
            signals: HomeExchangeConditionSignals(
                postalAcceptedByBoth: false,
                localExchangeSelected: true,
                prefectureMatches: prefectureMatches,
                dateMatches: prefectureUnset ? true : dateMatches,
                prefectureUnset: prefectureUnset,
                dateNeedsDiscussion: !prefectureUnset && dateNeedsDiscussion,
                viewerExchangeMethodTitle: viewerSummary.handoffMethod.title,
                partnerExchangeMethodTitle: partnerSummary.handoffMethod.title,
                viewerLocalConditionText: localConditionText(for: viewerSummary),
                partnerLocalConditionText: localConditionText(for: partnerSummary),
                viewerShippingFeeTitle: mailConditionText(for: viewerSummary),
                partnerShippingFeeTitle: mailConditionText(for: partnerSummary)
            ),
            attentionKinds: attentionKinds
        )
    }

    private static func mailEvaluation(
        viewerSummary: IndividualListingExchangeSummary,
        partnerSummary: IndividualListingExchangeSummary
    ) -> RouteEvaluation {
        let needsShippingFeeDiscussion = viewerSummary.shippingFee != .owner
            || partnerSummary.shippingFee != .owner
        return RouteEvaluation(
            route: .mail,
            signals: HomeExchangeConditionSignals(
                postalAcceptedByBoth: true,
                localExchangeSelected: false,
                prefectureMatches: true,
                dateMatches: true,
                shippingFeeNeedsDiscussion: needsShippingFeeDiscussion,
                viewerExchangeMethodTitle: viewerSummary.handoffMethod.title,
                partnerExchangeMethodTitle: partnerSummary.handoffMethod.title,
                viewerLocalConditionText: localConditionText(for: viewerSummary),
                partnerLocalConditionText: localConditionText(for: partnerSummary),
                viewerShippingFeeTitle: mailConditionText(for: viewerSummary),
                partnerShippingFeeTitle: mailConditionText(for: partnerSummary)
            ),
            attentionKinds: needsShippingFeeDiscussion ? [.shippingFeeNeedsDiscussion] : []
        )
    }

    private static func localConditionText(for summary: IndividualListingExchangeSummary) -> String {
        summary.localDetailTextForProposalDisplay ?? "対象外"
    }

    private static func mailConditionText(for summary: IndividualListingExchangeSummary) -> String {
        summary.mailDetailText ?? "対象外"
    }

    private static func routeEvaluationSorter(
        lhs: RouteEvaluation,
        rhs: RouteEvaluation
    ) -> Bool {
        if lhs.score == rhs.score {
            if lhs.attentionKinds.count == rhs.attentionKinds.count {
                return lhs.route.rawValue < rhs.route.rawValue
            }
            return lhs.attentionKinds.count < rhs.attentionKinds.count
        }
        return lhs.score < rhs.score
    }

    private static func signals(
        _ signals: HomeExchangeConditionSignals,
        carryingLocalRouteFrom localRoute: RouteEvaluation?
    ) -> HomeExchangeConditionSignals {
        HomeExchangeConditionSignals(
            postalAcceptedByBoth: signals.postalAcceptedByBoth,
            localExchangeSelected: signals.localExchangeSelected,
            prefectureMatches: signals.prefectureMatches,
            dateMatches: signals.dateMatches,
            prefectureUnset: signals.prefectureUnset,
            dateNeedsDiscussion: signals.dateNeedsDiscussion,
            shippingFeeNeedsDiscussion: signals.shippingFeeNeedsDiscussion,
            viewerExchangeMethodTitle: signals.viewerExchangeMethodTitle,
            partnerExchangeMethodTitle: signals.partnerExchangeMethodTitle,
            viewerLocalConditionText: signals.viewerLocalConditionText,
            partnerLocalConditionText: signals.partnerLocalConditionText,
            viewerShippingFeeTitle: signals.viewerShippingFeeTitle,
            partnerShippingFeeTitle: signals.partnerShippingFeeTitle,
            localRouteAvailable: localRoute != nil,
            localRoutePrefectureMatches: localRoute?.signals.prefectureMatches ?? false,
            localRouteDateMatches: localRoute?.signals.dateMatches ?? false,
            localRoutePrefectureUnset: localRoute?.signals.prefectureUnset ?? false,
            localRouteDateNeedsDiscussion: localRoute?.signals.dateNeedsDiscussion ?? false
        )
    }

    private static func issueWeight(_ kind: HomeMutualMatchAttentionKind) -> Int {
        switch kind {
        case .shippingFeeNeedsDiscussion:
            return 1
        case .dateNeedsDiscussion:
            return 2
        case .prefectureNeedsDiscussion, .prefectureUnset:
            return 3
        case .exchangeMethodMismatch:
            return 100
        case .ready, .tagMismatch, .amountIncluded, .amountInsufficient,
             .paymentMethodMismatch, .viewerPaymentUnset, .partnerPaymentUnset,
             .paymentUnset, .paymentMethodNeedsDiscussion:
            return 0
        }
    }

    private static func schedulesMatch(_ lhs: String, _ rhs: String) -> Bool {
        if isFlexibleSchedule(lhs) || isFlexibleSchedule(rhs) {
            return true
        }
        let lhsTokens = scheduleTokens(lhs)
        let rhsTokens = scheduleTokens(rhs)
        guard !lhsTokens.isEmpty, !rhsTokens.isEmpty else {
            return normalizedText(lhs) == normalizedText(rhs)
        }
        return !lhsTokens.isDisjoint(with: rhsTokens)
    }

    private static func schedulesNeedDiscussion(_ lhs: String, _ rhs: String) -> Bool {
        if isFlexibleSchedule(lhs) || isFlexibleSchedule(rhs) {
            return true
        }
        let lhsTokens = scheduleTokens(lhs)
        let rhsTokens = scheduleTokens(rhs)
        guard !lhsTokens.isEmpty, !rhsTokens.isEmpty else {
            return normalizedText(lhs) != normalizedText(rhs)
        }
        return lhsTokens.intersection(rhsTokens).count != 1
    }

    private static func isFlexibleSchedule(_ value: String) -> Bool {
        guard let normalized = normalizedText(value) else {
            return true
        }
        return normalized == normalizedText(IndividualListingExchangeSummary.defaultLocalSchedule)
    }

    private static func scheduleTokens(_ value: String) -> Set<String> {
        Set(
            value
                .components(separatedBy: CharacterSet(charactersIn: "、,\n"))
                .compactMap(normalizedText)
        )
    }

    private static func normalizedText(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacing("　", with: "")
            .replacing(" ", with: "")
            .lowercased()
        return normalized.isEmpty ? nil : normalized
    }

    private static func normalizedSettingText(
        _ value: String?,
        emptyMarkers: Set<String>
    ) -> String? {
        guard let normalized = normalizedText(value) else {
            return nil
        }
        let normalizedMarkers = Set(emptyMarkers.compactMap(normalizedText))
        return normalizedMarkers.contains(normalized) ? nil : normalized
    }

}
