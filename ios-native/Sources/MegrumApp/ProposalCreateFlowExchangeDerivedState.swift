import Foundation
import MegrumCore

extension ProposalCreateFlow {
    var draftExchangeSummary: IndividualListingExchangeSummary {
        IndividualListingExchangeSummary(
            handoffMethod: exchangeMethod.listingHandoffDraft,
            localPrefecture: currentMeetupPrefecture,
            localPlaceMemo: meetupPlaceMemo,
            localSchedule: ProposalCreateDisplayTextFormatter.dateText(meetupStartAt),
            shippingFee: shippingFee,
            shippingDays: shippingDays,
            acceptsOutsideCondition: true
        )
    }

    var defaultExchangeSettings: HomeDefaultExchangeSettings {
        HomeDefaultExchangeSettings(
            preferenceRawValue: exchangePreferenceRawValue,
            requiresSamePrefecture: exchangeRequiresSamePrefecture,
            requiresDateOverlap: exchangeRequiresDateOverlap,
            localPrefecture: exchangeLocalPrefecture,
            localDateKeysRawValue: exchangeLocalDateKeysRawValue,
            mailShippingFeeRawValue: exchangeMailShippingFeeRawValue,
            mailShippingDaysRawValue: exchangeMailShippingDaysRawValue
        )
    }

    var defaultExchangeSummary: IndividualListingExchangeSummary {
        defaultExchangeSettings.makeListingExchangeSummary()
    }

    var viewerListingExchangeSummary: IndividualListingExchangeSummary? {
        let selectedOrInitialSenderIDs = selectedSenderGoodsIDs.union(Set(initialSenderGoodsIDs))
        if let listingID,
           let listing = appState.listings.first(where: { $0.id == listingID }) {
            return IndividualListingExchangeSummary.extract(from: listing.note).summary
        }
        guard !selectedOrInitialSenderIDs.isEmpty else {
            return nil
        }
        return appState.listings
            .filter { $0.status == .active }
            .first { listing in
                listing.haves.contains { selectedOrInitialSenderIDs.contains($0.itemID) }
            }
            .flatMap { IndividualListingExchangeSummary.extract(from: $0.note).summary }
    }

    var partnerExchangeSummary: IndividualListingExchangeSummary? {
        let partnerListings = appState.publicListingsByUserID[targetItem.ownerID] ?? []
        if let listingID,
           let listing = partnerListings.first(where: { $0.id == listingID }) {
            return IndividualListingExchangeSummary.extract(from: listing.note).summary
        }
        let receiverIDs = Set((receiverGoodsIDs ?? []) + [targetItem.id])
        return partnerListings
            .filter { $0.status == .active }
            .first { listing in
                listing.haves.contains { receiverIDs.contains($0.itemID) }
            }
            .flatMap { IndividualListingExchangeSummary.extract(from: $0.note).summary }
    }

    var viewerListingForConditionDisplay: IndividualListing? {
        let selectedOrInitialSenderIDs = selectedSenderGoodsIDs.union(Set(initialSenderGoodsIDs))
        if let listingID,
           let listing = appState.listings.first(where: { $0.id == listingID }) {
            return listing
        }
        guard !selectedOrInitialSenderIDs.isEmpty else {
            return nil
        }
        return appState.listings
            .filter { $0.status == .active }
            .first { listing in
                listing.haves.contains { selectedOrInitialSenderIDs.contains($0.itemID) }
            }
    }

    var partnerListingForConditionDisplay: IndividualListing? {
        let partnerListings = appState.publicListingsByUserID[targetItem.ownerID] ?? []
        if let listingID,
           let listing = partnerListings.first(where: { $0.id == listingID }) {
            return listing
        }
        let receiverIDs = Set((receiverGoodsIDs ?? []) + [targetItem.id])
        return partnerListings
            .filter { $0.status == .active }
            .first { listing in
                listing.haves.contains { receiverIDs.contains($0.itemID) }
            }
    }

    var viewerLocalConditionText: String {
        viewerListingExchangeSummary?.localDetailTextForProposalDisplay ?? "未設定"
    }

    var partnerLocalConditionText: String {
        if let text = partnerExchangeSummary?.localDetailTextForProposalDisplay {
            return text
        }
        return "未設定"
    }

    var viewerShippingConditionText: String {
        viewerListingExchangeSummary?.mailDetailText ?? "未設定"
    }

    var partnerShippingConditionText: String {
        partnerExchangeSummary?.mailDetailText ?? "未設定"
    }

    var proposalShippingSummaryText: String {
        draftExchangeSummary.mailDetailText ?? "未設定"
    }
}

private extension ExchangeMethod {
    var listingHandoffDraft: IndividualListingHandoffDraft {
        switch self {
        case .hand:
            .local
        case .mail:
            .mail
        case .both:
            .both
        }
    }
}
