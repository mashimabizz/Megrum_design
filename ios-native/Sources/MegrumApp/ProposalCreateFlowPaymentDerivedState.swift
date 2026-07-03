import Foundation
import MegrumCore

extension ProposalCreateFlow {
    var senderCashAmount: Int? {
        valueSelectionState.senderCashAmount
    }

    var receiverCashAmount: Int? {
        valueSelectionState.receiverCashAmount
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
        valueSelectionState.requiresPaymentStep
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
            for: PaymentSettingsResolver.methods(settings: appState.paymentSettings, viewer: appState.viewer),
            otherNote: PaymentSettingsResolver.otherNote(settings: appState.paymentSettings, viewer: appState.viewer)
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
        PaymentSettingsResolver.otherNote(settings: appState.paymentSettings, viewer: appState.viewer)
    }

    var partnerPaymentOtherNote: String? {
        if let profile = appState.publicProfilesByUserID[targetItem.ownerID]?.profile {
            return profile.paymentNote
        }
        return targetItem.ownerPaymentNote
    }

    var viewerPaymentMethods: [UserPaymentMethod] {
        PaymentSettingsResolver.methods(settings: appState.paymentSettings, viewer: appState.viewer)
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
        if let selectedPaymentOptionID = valueSelectionState.selectedPaymentOptionID,
           let selected = options.first(where: { $0.id == selectedPaymentOptionID }) {
            return selected
        }
        return options.first
    }

    var selectedPaymentSummaryText: String? {
        selectedPaymentOption?.confirmationTitle
    }
}
