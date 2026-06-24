import Foundation
import MegrumCore
import SwiftUI

extension ProposalCreateSheet {
    func prepareOnAppear() {
        selectedSenderGoodsID = selectedSenderID
        boundMeetupEnd(after: meetupStartAt)
        requestLocationIfNeeded()
    }

    func toggleConditionTag(_ tag: String) {
        if selectedConditionTags.contains(tag) {
            selectedConditionTags.remove(tag)
        } else {
            selectedConditionTags.insert(tag)
        }
    }

    func handleExchangeMethodChange() {
        selectedConditionTags = selectedConditionTags.intersection(Set(conditionTagOptions))
        requestLocationIfNeeded()
    }

    func boundMeetupEnd(after startAt: Date) {
        if meetupEndAt <= startAt {
            meetupEndAt = startAt.addingTimeInterval(30 * 60)
        }
    }

    func applyCurrentLocation(_ coordinate: MegrumLocationCoordinate?) {
        guard let coordinate, configuration.requiresMeetupBeforeSubmit else {
            return
        }
        if meetupPlaceName.isBlank {
            meetupPlaceName = "現在地"
        }
        if meetupLatitudeText.isBlank {
            meetupLatitudeText = ProposalMeetupMapDraft.coordinateText(coordinate.latitude)
        }
        if meetupLongitudeText.isBlank {
            meetupLongitudeText = ProposalMeetupMapDraft.coordinateText(coordinate.longitude)
        }
    }

    func requestLocationIfNeeded() {
        guard configuration.requiresMeetupBeforeSubmit else {
            return
        }
        locationState.requestCurrentLocation()
    }

    func createProposal() async {
        guard let selectedSenderID, let targetStatus = configuration.targetStatus else {
            return
        }
        let meetup = configuration.requiresMeetupBeforeSubmit ? meetupInput : nil
        guard !configuration.requiresMeetupBeforeSubmit || meetup != nil else {
            return
        }
        let created = await appState.createProposal(
            ProposalCreateInput(
                receiverID: targetItem.ownerID,
                senderGoodsIDs: [selectedSenderID],
                receiverGoodsIDs: resolvedReceiverGoodsIDs,
                exchangeMethod: exchangeMethod,
                conditionTags: orderedConditionTags,
                message: message,
                status: targetStatus,
                meetup: meetup,
                listingID: listingID
            )
        )
        if created {
            dismiss()
        }
    }
}
