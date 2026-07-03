import Foundation

struct ProposalShippingConditionDraft: Equatable {
    var fee: IndividualListingShippingFeeDraft
    var days: IndividualListingShippingDaysDraft
}

enum ProposalShippingConditionDraftResolver {
    static func resolvedDraft(
        viewerListingSummary: IndividualListingExchangeSummary?,
        initialFee: IndividualListingShippingFeeDraft?,
        initialDays: IndividualListingShippingDaysDraft?,
        defaultSummary: IndividualListingExchangeSummary
    ) -> ProposalShippingConditionDraft {
        if let viewerListingSummary, viewerListingSummary.includesMail {
            return ProposalShippingConditionDraft(
                fee: viewerListingSummary.shippingFee,
                days: viewerListingSummary.shippingDays
            )
        }
        return ProposalShippingConditionDraft(
            fee: initialFee ?? (defaultSummary.includesMail ? defaultSummary.shippingFee : .negotiate),
            days: initialDays ?? (defaultSummary.includesMail ? defaultSummary.shippingDays : .twoToFourDays)
        )
    }
}
