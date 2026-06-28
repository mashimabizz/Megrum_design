import Foundation
import MegrumCore
import SwiftUI

extension ProposalCreateFlow {
    func handleHeaderLeadingAction() {
        if selectedStep == .payment || selectedStep == .confirm {
            previousStep()
        } else {
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
        guard newValue.count > Self.messageLimit else {
            return
        }
        message = String(newValue.prefix(Self.messageLimit))
    }

    func ensureMeetupEndAfterStart(_ newValue: Date) {
        if meetupEndAt <= newValue {
            meetupEndAt = newValue.addingTimeInterval(30 * 60)
        }
    }

    func applyCurrentLocationToSelectedMeetupCandidate() {
        guard let coordinate = locationState.coordinate, configuration.requiresMeetupBeforeSubmit else {
            return
        }
        let updatedDraft = selectedMeetupCandidateDraft.applyingCurrentLocation(coordinate)
        applyMeetupCandidate(updatedDraft, at: selectedMeetupCandidateIndex)
    }

    func previousStep() {
        guard let index = visibleSteps.firstIndex(of: selectedStep), index > 0 else {
            return
        }
        withAnimation(.snappy) {
            selectedStep = visibleSteps[index - 1]
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
        guard configuration.canSubmit, let defaultTargetStatus = configuration.targetStatus else {
            return nil
        }
        return submissionStatusOverride ?? defaultTargetStatus
    }

    func preparedMeetupCandidatesForSubmission() -> [ProposalMeetupInput]? {
        let meetupCandidates = configuration.requiresMeetupBeforeSubmit ? meetupInputsForSubmission : []
        guard !configuration.requiresMeetupBeforeSubmit || meetupCandidates.first != nil else {
            return nil
        }
        return meetupCandidates
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
            methodTitle: Self.methodTitle(exchangeMethod),
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

    static func methodTitle(_ method: ExchangeMethod) -> String {
        switch method {
        case .hand:
            "現地交換"
        case .mail:
            "郵送交換"
        case .both:
            "現地 / 郵送"
        }
    }

    static func dateText(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .locale(Locale(identifier: "ja_JP"))
                .month()
                .day()
        )
    }

    static func date(fromScheduleText text: String) -> Date? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "　", with: " ")
        guard !normalized.isEmpty,
              normalized != IndividualListingExchangeSummary.defaultLocalSchedule
        else {
            return nil
        }

        let patterns = [
            #"(?<month>\d{1,2})月(?<day>\d{1,2})日"#,
            #"(?<month>\d{1,2})/(?<day>\d{1,2})"#,
            #"(?<month>\d{1,2})\.(?<day>\d{1,2})"#
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)),
                  let monthRange = Range(match.range(withName: "month"), in: normalized),
                  let dayRange = Range(match.range(withName: "day"), in: normalized),
                  let month = Int(normalized[monthRange]),
                  let day = Int(normalized[dayRange])
            else {
                continue
            }
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
            let currentYear = calendar.component(.year, from: .now)
            return calendar.date(from: DateComponents(year: currentYear, month: month, day: day, hour: 12))
        }
        return nil
    }

    var partnerHandle: String {
        appState.publicProfilesByUserID[targetItem.ownerID]?.profile.handle ?? "相手"
    }

    var displayPartnerHandle: String {
        visualQAInitialScreen == nil ? partnerHandle : "michilion"
    }
}
