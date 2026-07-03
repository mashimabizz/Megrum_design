import Foundation
import MegrumCore

extension ProposalCreateSheet {
    var selectedSenderID: UUID? {
        draftState.selectedSenderGoodsID ?? appState.inventory.first?.id
    }

    var resolvedReceiverGoodsIDs: [UUID] {
        var uniqueIDs: [UUID] = []
        let candidateIDs = receiverGoodsIDs ?? [targetItem.id]
        for id in candidateIDs where !uniqueIDs.contains(id) {
            uniqueIDs.append(id)
        }
        return uniqueIDs.isEmpty ? [targetItem.id] : uniqueIDs
    }

    var configuration: ProposalCreateConfiguration {
        ProposalCreateConfiguration(
            exchangeMethod: draftState.exchangeMethod,
            hasSelectedSenderGoods: selectedSenderID != nil,
            isCreatingProposal: appState.isCreatingProposal,
            hasReadyMailingAddress: appState.mailingAddress?.isReady == true,
            isLoadingMailingAddress: appState.isLoadingMailingAddress,
            hasValidMeetup: meetupInput?.isValid == true,
            receiverGoodsCount: resolvedReceiverGoodsIDs.count,
            isListingSource: listingID != nil
        )
    }

    var conditionTagOptions: [String] {
        configuration.conditionTagOptions
    }

    var orderedConditionTags: [String] {
        draftState.orderedConditionTags(options: conditionTagOptions)
    }

    var meetupInput: ProposalMeetupInput? {
        draftState.meetupInput
    }
}
