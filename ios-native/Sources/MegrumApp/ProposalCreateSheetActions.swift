import Foundation
import MegrumCore
import SwiftUI

extension ProposalCreateSheet {
    func prepareOnAppear() {
        draftState.selectedSenderGoodsID = selectedSenderID
        boundMeetupEnd(after: draftState.meetupStartAt)
        requestLocationIfNeeded()
    }

    func toggleConditionTag(_ tag: String) {
        draftState.toggleConditionTag(tag)
    }

    func handleExchangeMethodChange() {
        draftState.pruneConditionTags(to: conditionTagOptions)
        requestLocationIfNeeded()
    }

    func boundMeetupEnd(after startAt: Date) {
        draftState.boundMeetupEnd(after: startAt)
    }

    func applyCurrentLocation(_ coordinate: MegrumLocationCoordinate?) {
        draftState.applyCurrentLocation(
            coordinate,
            requiresMeetupBeforeSubmit: configuration.requiresMeetupBeforeSubmit
        )
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
                exchangeMethod: draftState.exchangeMethod,
                conditionTags: orderedConditionTags,
                message: draftState.message,
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
