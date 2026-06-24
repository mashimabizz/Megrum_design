import Foundation
import MegrumCore

extension ProposalCreateSheet {
    var selectedSenderID: UUID? {
        selectedSenderGoodsID ?? appState.inventory.first?.id
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
            exchangeMethod: exchangeMethod,
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
        conditionTagOptions.filter { selectedConditionTags.contains($0) }
    }

    var meetupInput: ProposalMeetupInput? {
        guard
            let latitude = ProposalMeetupMapDraft.coordinateValue(from: meetupLatitudeText),
            let longitude = ProposalMeetupMapDraft.coordinateValue(from: meetupLongitudeText)
        else {
            return nil
        }
        let input = ProposalMeetupInput(
            startAt: meetupStartAt,
            endAt: meetupEndAt,
            placeName: meetupPlaceName,
            latitude: latitude,
            longitude: longitude
        )
        return input.isValid ? input : nil
    }
}
