import Foundation
import MegrumCore

extension ProposalCreateFlow {
    var visibleSteps: [ProposalCreateStep] {
        var steps: [ProposalCreateStep] = [.give, .receive]
        if configuration.requiresMeetupBeforeSubmit {
            steps.append(.meetup)
        }
        if configuration.requiresShippingBeforeSubmit {
            steps.append(.shipping)
        }
        if configuration.requiresPaymentSelection {
            steps.append(.payment)
        }
        steps.append(.confirm)
        return steps
    }

    var configuration: ProposalCreateConfiguration {
        ProposalCreateConfiguration(
            exchangeMethod: exchangeMethod,
            hasSelectedSenderGoods: !orderedSenderGoodsIDs.isEmpty,
            hasCashOffer: senderCashAmount != nil,
            hasReceiverCashRequest: receiverCashAmount != nil,
            isCreatingProposal: appState.isCreatingProposal,
            hasReadyMailingAddress: appState.mailingAddress?.isReady == true,
            isLoadingMailingAddress: appState.isLoadingMailingAddress,
            hasValidMeetup: meetupInput?.isValid == true,
            requiresPaymentSelection: requiresPaymentStep,
            hasSelectedPaymentMethod: !requiresPaymentStep || selectedPaymentOption != nil,
            receiverGoodsCount: resolvedReceiverGoodsIDs.count,
            isListingSource: listingID != nil
        )
    }

    var proposalConditionTags: [String] {
        var tags: [String] = []
        if configuration.requiresMeetupBeforeSubmit {
            tags.append("待ち合わせ: \(viewerLocalConditionText)")
        }
        if configuration.requiresShippingBeforeSubmit {
            tags.append("送料: \(shippingFee.title)")
            tags.append("発送目安: \(shippingDays.title)")
        }
        if senderCashAmount != nil || receiverCashAmount != nil {
            if let selectedPaymentSummaryText {
                tags.append("支払方法: \(selectedPaymentSummaryText)")
            }
        }
        return tags
    }
}
