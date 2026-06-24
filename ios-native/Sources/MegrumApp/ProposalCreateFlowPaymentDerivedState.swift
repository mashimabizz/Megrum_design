import Foundation
import MegrumCore

extension ProposalCreateFlow {
    var senderCashAmount: Int? {
        return TradeAmountFormatter.cashInputValue(from: senderCashAmountText)
    }

    var receiverCashAmount: Int? {
        return TradeAmountFormatter.cashInputValue(from: receiverCashAmountText)
    }

    var proposalCashAmount: Int? {
        senderCashAmount ?? receiverCashAmount
    }

    var proposalCashAmountSide: ProposalCashSide? {
        if senderCashAmount != nil {
            return .sender
        }
        if receiverCashAmount != nil {
            return .receiver
        }
        return nil
    }

    var requiresPaymentStep: Bool {
        senderCashAmount != nil || receiverCashAmount != nil
    }

    var senderSelectionCount: Int {
        orderedSenderGoodsIDs.count + (senderCashAmount == nil ? 0 : 1)
    }

    var receiverSelectionCount: Int {
        resolvedReceiverGoodsIDs.count + (receiverCashAmount == nil ? 0 : 1)
    }

    var listingCashReferenceRows: [ProposalCashReferenceRow] {
        [
            partnerListingCashReferenceText.map { ProposalCashReferenceRow(label: "相手", value: $0) },
            viewerListingCashReferenceText.map { ProposalCashReferenceRow(label: "自分", value: $0) }
        ]
        .compactMap(\.self)
    }

    private var viewerListingCashReferenceText: String? {
        cashReferenceText(from: viewerListingForConditionDisplay)
    }

    private var partnerListingCashReferenceText: String? {
        cashReferenceText(from: partnerListingForConditionDisplay)
    }

    private func cashReferenceText(from listing: IndividualListing?) -> String? {
        guard let listing else {
            return nil
        }
        let values = listing.options
            .filter(\.isCashOffer)
            .map { TradeAmountFormatter.fixedPrice(amount: $0.cashAmount) }
        guard !values.isEmpty else {
            return nil
        }
        var seen = Set<String>()
        let uniqueValues = values.filter { seen.insert($0).inserted }
        return uniqueValues.joined(separator: " / ")
    }

    var viewerPaymentSummaryText: String {
        UserPaymentMethod.displayText(
            for: appState.paymentSettings?.methods ?? appState.viewer?.paymentMethods ?? [],
            otherNote: appState.paymentSettings?.otherNote ?? appState.viewer?.paymentNote
        )
    }

    var partnerPaymentSummaryText: String {
        if let profile = appState.publicProfilesByUserID[targetItem.ownerID]?.profile {
            return profile.paymentSummaryText
        }
        return UserPaymentMethod.displayText(
            for: targetItem.ownerPaymentMethods,
            otherNote: targetItem.ownerPaymentNote
        )
    }

    var viewerPaymentOtherNote: String? {
        appState.paymentSettings?.otherNote ?? appState.viewer?.paymentNote
    }

    var partnerPaymentOtherNote: String? {
        if let profile = appState.publicProfilesByUserID[targetItem.ownerID]?.profile {
            return profile.paymentNote
        }
        return targetItem.ownerPaymentNote
    }

    var viewerPaymentMethods: [UserPaymentMethod] {
        UserPaymentMethod.normalized(appState.paymentSettings?.methods ?? appState.viewer?.paymentMethods ?? [])
    }

    var partnerPaymentMethods: [UserPaymentMethod] {
        if let profile = appState.publicProfilesByUserID[targetItem.ownerID]?.profile {
            return UserPaymentMethod.normalized(profile.paymentMethods)
        }
        return UserPaymentMethod.normalized(targetItem.ownerPaymentMethods)
    }

    var paymentNeedsDiscussion: Bool {
        guard senderCashAmount != nil || receiverCashAmount != nil else {
            return false
        }
        let commonMethods = Set(viewerPaymentMethods).intersection(Set(partnerPaymentMethods))
        return commonMethods.count != 1
    }

    var paymentOptionSections: [(section: ProposalPaymentOptionSection, options: [ProposalPaymentOption])] {
        ProposalPaymentOptionCatalog.sections(
            viewerMethods: viewerPaymentMethods,
            viewerOtherNote: viewerPaymentOtherNote,
            partnerMethods: partnerPaymentMethods,
            partnerOtherNote: partnerPaymentOtherNote
        )
    }

    var selectedPaymentOption: ProposalPaymentOption? {
        guard requiresPaymentStep else {
            return nil
        }
        let options = paymentOptionSections.flatMap(\.options)
        if let selectedPaymentOptionID,
           let selected = options.first(where: { $0.id == selectedPaymentOptionID }) {
            return selected
        }
        return options.first
    }

    var selectedPaymentSummaryText: String? {
        selectedPaymentOption?.confirmationTitle
    }
}
