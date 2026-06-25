import MegrumData

extension HomeMutualMatchConditionPolicy {
    static func exchangeSummary(
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

    static func commonRoutes(
        _ lhs: IndividualListingHandoffDraft,
        _ rhs: IndividualListingHandoffDraft
    ) -> [HomeMutualMatchExchangeRoute] {
        let lhsRoutes = routes(for: lhs)
        let rhsRoutes = routes(for: rhs)
        return [.local, .mail].filter { lhsRoutes.contains($0) && rhsRoutes.contains($0) }
    }

    static func routes(for method: IndividualListingHandoffDraft) -> Set<HomeMutualMatchExchangeRoute> {
        switch method {
        case .local:
            return [.local]
        case .mail:
            return [.mail]
        case .both:
            return [.local, .mail]
        }
    }

    static func localEvaluation(
        viewerSummary: IndividualListingExchangeSummary,
        partnerSummary: IndividualListingExchangeSummary
    ) -> HomeMutualMatchExchangeRouteEvaluation {
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

        return HomeMutualMatchExchangeRouteEvaluation(
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

    static func mailEvaluation(
        viewerSummary: IndividualListingExchangeSummary,
        partnerSummary: IndividualListingExchangeSummary
    ) -> HomeMutualMatchExchangeRouteEvaluation {
        let needsShippingFeeDiscussion = viewerSummary.shippingFee != .owner
            || partnerSummary.shippingFee != .owner
        return HomeMutualMatchExchangeRouteEvaluation(
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

    static func localConditionText(for summary: IndividualListingExchangeSummary) -> String {
        summary.localDetailTextForProposalDisplay ?? "対象外"
    }

    static func mailConditionText(for summary: IndividualListingExchangeSummary) -> String {
        summary.mailDetailText ?? "対象外"
    }

    static func routeEvaluationSorter(
        lhs: HomeMutualMatchExchangeRouteEvaluation,
        rhs: HomeMutualMatchExchangeRouteEvaluation
    ) -> Bool {
        if lhs.score == rhs.score {
            if lhs.attentionKinds.count == rhs.attentionKinds.count {
                return lhs.route.rawValue < rhs.route.rawValue
            }
            return lhs.attentionKinds.count < rhs.attentionKinds.count
        }
        return lhs.score < rhs.score
    }

    static func signals(
        _ signals: HomeExchangeConditionSignals,
        carryingLocalRouteFrom localRoute: HomeMutualMatchExchangeRouteEvaluation?
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
}
