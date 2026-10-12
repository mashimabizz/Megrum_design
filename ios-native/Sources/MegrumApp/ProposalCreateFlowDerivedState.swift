import Foundation
import MegrumCore

extension ProposalCreateFlow {
    var visibleSteps: [ProposalCreateStep] {
        // 個別募集エディタ準拠の3ステップ（譲/受/交換条件）＋送信確認（iter1226.344）。
        // 交換手段・現地・郵送は 3/3 の「交換条件」にまとめる。
        // 支払方法は金額が発生する時だけ、3/3 の後に独立した1画面として挿入する（iter1226.381）。
        if requiresPaymentStep {
            return [.give, .receive, .conditions, .payment, .confirm]
        }
        return [.give, .receive, .conditions, .confirm]
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
