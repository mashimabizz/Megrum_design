import Foundation
import MegrumCore
import SwiftUI

extension ProposalCreateFlow {
    func handleHeaderLeadingAction() {
        switch ProposalHeaderLeadingActionResolver.action(for: selectedStep) {
        case .previousStep:
            previousStep()
        case .dismiss:
            dismissProposalFlow()
        }
    }

    func handleCompletionSearchMore() {
        onCompletionAction(.searchMore)
        dismissProposalFlow()
    }

    func handleCompletionOpenTrades() {
        onCompletionAction(.openTrades)
        dismissProposalFlow()
    }

    func enforceMessageLimit(_ newValue: String) {
        let limitedMessage = ProposalMessageDraftLimiter.limited(newValue, limit: Self.messageLimit)
        guard limitedMessage != newValue else {
            return
        }
        message = limitedMessage
    }

    func ensureMeetupEndAfterStart(_ newValue: Date) {
        meetupEndAt = ProposalMeetupEndDateResolver.adjustedEnd(
            startAt: newValue,
            currentEndAt: meetupEndAt
        )
    }

    func applyCurrentLocationToSelectedMeetupCandidate() {
        guard let updatedDraft = ProposalMeetupCurrentLocationDraftResolver.resolvedDraft(
            currentDraft: selectedMeetupCandidateDraft,
            coordinate: locationState.coordinate,
            requiresMeetupBeforeSubmit: configuration.requiresMeetupBeforeSubmit
        ) else {
            return
        }
        applyMeetupCandidate(updatedDraft, at: selectedMeetupCandidateIndex)
    }

    func previousStep() {
        guard let destination = ProposalPreviousStepResolver.destination(
            from: selectedStep,
            visibleSteps: visibleSteps
        ) else {
            return
        }
        withAnimation(.snappy) {
            selectedStep = destination
        }
    }

    func primaryAction() {
        if selectedStep == .confirm {
            Task {
                await createProposal()
            }
            return
        }
        guard let destination = ProposalCreatePrimaryStepDestination.destination(
            from: selectedStep,
            configuration: configuration,
            visibleSteps: visibleSteps
        ) else {
            return
        }
        withAnimation(.snappy) {
            selectedStep = destination
        }
    }

    var stepSwipeGesture: some Gesture {
        DragGesture(minimumDistance: ProposalStepSwipeNavigator.minimumHorizontalDistance)
            .onEnded { value in
                guard selectedStep != .meetup, selectedStep != .confirm else {
                    return
                }
                guard value.translation.width < 0 else {
                    return
                }
                guard let destination = ProposalStepSwipeNavigator.destination(
                    from: selectedStep,
                    translationWidth: value.translation.width,
                    translationHeight: value.translation.height,
                    visibleSteps: visibleSteps
                ) else {
                    return
                }
                withAnimation(.snappy) {
                    selectedStep = destination
                }
            }
    }

    func createProposal() async {
        guard let targetStatus = proposalSubmissionTargetStatus else {
            return
        }
        saveSelectedMeetupCandidate()
        guard let meetupCandidates = preparedMeetupCandidatesForSubmission() else {
            return
        }
        let draft = makeSubmissionDraft(
            targetStatus: targetStatus,
            meetupCandidates: meetupCandidates
        )
        let submitted: Bool
        if let revisingProposalID {
            submitted = await appState.reviseProposal(proposalID: revisingProposalID, input: draft.input)
        } else {
            submitted = await appState.createProposal(draft.input)
        }
        if submitted {
            await onCreateSuccess?()
            if showsCompletionAfterCreate {
                withAnimation(.snappy) {
                    submittedSummary = draft.summary
                }
            } else {
                dismissProposalFlow()
            }
        }
    }

    var proposalSubmissionTargetStatus: ProposalStatus? {
        ProposalSubmissionTargetStatusResolver.status(
            canSubmit: configuration.canSubmit,
            defaultTargetStatus: configuration.targetStatus,
            override: submissionStatusOverride
        )
    }

    func preparedMeetupCandidatesForSubmission() -> [ProposalMeetupInput]? {
        ProposalMeetupSubmissionCandidatesResolver.candidates(
            requiresMeetupBeforeSubmit: configuration.requiresMeetupBeforeSubmit,
            meetupInputs: meetupInputsForSubmission
        )
    }

    func makeSubmissionDraft(
        targetStatus: ProposalStatus,
        meetupCandidates: [ProposalMeetupInput]
    ) -> ProposalCreateSubmissionDraft {
        ProposalCreateSubmissionDraft(
            receiverID: targetItem.ownerID,
            senderGoodsIDs: orderedSenderGoodsIDs,
            receiverGoodsIDs: resolvedReceiverGoodsIDs,
            exchangeMethod: exchangeMethod,
            conditionTags: proposalConditionTags,
            message: message,
            matchType: matchType,
            status: targetStatus,
            meetupCandidates: meetupCandidates,
            exposeCalendar: shareSchedule,
            listingID: listingID,
            cashAmount: proposalCashAmount,
            cashAmountSide: proposalCashAmountSide,
            senderCount: senderSelectionCount,
            receiverCount: receiverSelectionCount,
            partnerHandle: partnerHandle,
            methodTitle: ProposalCreateDisplayTextFormatter.methodTitle(exchangeMethod),
            meetupSummary: meetupSummary
        )
    }

    func dismissProposalFlow() {
        if let slidePresentationDismiss {
            slidePresentationDismiss()
        } else {
            dismiss()
        }
    }

    var partnerHandle: String {
        appState.publicProfilesByUserID[targetItem.ownerID]?.profile.handle ?? "相手"
    }

    var displayPartnerHandle: String {
        visualQAInitialScreen == nil ? partnerHandle : "michilion"
    }
}
