import SwiftUI

extension MatchRelationScreen {
    func seedInitialSelection(force: Bool) {
        let details = relationDetails
        selectionState = MatchRelationSelectionStateReducer.seedingInitialSelection(
            in: selectionState,
            details: details,
            highlightedItemID: currentTargetItem.id,
            force: force
        )
        applyVisualQACandidateExpansionIfNeeded(details: details)
    }

    func applyVisualQACandidateExpansionIfNeeded(details: [MatchRelationListingDetail]) {
        guard visualQAInitialScreen == .matchRelationCandidates,
              !didApplyVisualQACandidateExpansion,
              let target = MatchRelationComposer.defaultPopupTarget(
                for: details,
                highlightedItemID: currentTargetItem.id
              )
        else {
            return
        }
        didApplyVisualQACandidateExpansion = true
        popupTarget = target
    }

    func resetRelationSelection() {
        selectionState = MatchRelationSelectionStateReducer.resettingCandidates(in: selectionState)
        popupTarget = nil
    }

    func toggleCandidate(listingID: UUID, candidateID: UUID) {
        selectionState = MatchRelationSelectionStateReducer.togglingCandidate(
            listingID: listingID,
            candidateID: candidateID,
            in: selectionState
        )
    }

    func toggleHave(listingID: UUID, haveID: UUID) {
        selectionState = MatchRelationSelectionStateReducer.togglingHave(
            listingID: listingID,
            haveID: haveID,
            in: selectionState
        )
    }

    func startProposal() {
        if canStartRelationProposal {
            let listingID = aggregate.referencedListingIDs.count == 1 ? aggregate.referencedListingIDs.first : nil
            let target = aggregate.receiverItems.first ?? currentTargetItem
            proposalTarget = MatchRelationProposalTarget(
                targetItem: target,
                listingID: listingID,
                receiverGoodsIDs: aggregate.receiverIDs,
                senderGoodsIDs: aggregate.senderIDs,
                matchType: matchType
            )
            return
        }

        guard canStartSimpleProposal else {
            return
        }
        proposalTarget = MatchRelationProposalTarget(
            targetItem: currentTargetItem,
            listingID: nil,
            receiverGoodsIDs: simpleReceiverIDs,
            senderGoodsIDs: simpleSenderIDs,
            matchType: matchType
        )
    }

    func relationSwipeGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard let direction = MatchRelationSwipeResolver.direction(for: value.translation) else {
                    return
                }
                let hasTarget = direction == .next ? nextSwipeTarget != nil : previousSwipeTarget != nil
                guard let offset = MatchRelationSwipeResolver.presentationOffset(
                    translation: value.translation,
                    screenWidth: screenWidth,
                    hasAdjacentTarget: hasTarget
                ) else {
                    return
                }
                relationSwipeOffset = offset
            }
            .onEnded { value in
                guard let direction = MatchRelationSwipeResolver.direction(for: value.translation) else {
                    withAnimation(.snappy) {
                        relationSwipeOffset = 0
                    }
                    return
                }

                let target = direction == .next ? nextSwipeTarget : previousSwipeTarget
                let shouldSwitch = MatchRelationSwipeResolver.shouldSwitchTarget(
                    translation: value.translation,
                    predictedEndTranslationWidth: value.predictedEndTranslation.width,
                    screenWidth: screenWidth,
                    hasAdjacentTarget: target != nil
                )

                if let target, shouldSwitch {
                    withAnimation(.snappy) {
                        currentTargetItem = target
                        relationSwipeOffset = 0
                    }
                } else {
                    withAnimation(.snappy) {
                        relationSwipeOffset = 0
                    }
                }
            }
    }
}
