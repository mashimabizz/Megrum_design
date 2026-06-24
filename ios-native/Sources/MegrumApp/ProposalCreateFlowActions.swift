import Foundation
import MegrumCore
import SwiftUI

extension ProposalCreateFlow {
    func handleHeaderLeadingAction() {
        if selectedStep == .payment || selectedStep == .confirm {
            previousStep()
        } else {
            dismiss()
        }
    }

    func handleCompletionSearchMore() {
        onCompletionAction(.searchMore)
        dismiss()
    }

    func handleCompletionOpenTrades() {
        onCompletionAction(.openTrades)
        dismiss()
    }

    func prepareInitialProposalState() {
        applyInitialExchangeMethodIfNeeded()
        applyInitialCashAmountIfNeeded()
        seedDefaultSenderSelection()
        seedDefaultReceiverSelection()
        seedDefaultMeetupConditionsIfNeeded()
        seedDefaultShippingConditionsIfNeeded()
        normalizeMeetupEnd()
        applyVisualQAStateIfNeeded()
        applyInitialStepIfNeeded()
        meetupCalendarAnchorDate = calendarAnchorDate(for: meetupStartAt)
    }

    func loadTargetOwnerExchangeContent() async {
        await appState.loadPublicExchangeContent(userID: targetItem.ownerID)
        syncPaymentSelectionIfNeeded()
    }

    func loadMailingAddressIfNeeded() async {
        if appState.mailingAddress == nil {
            await appState.loadMailingAddress()
        }
        applyInitialStepIfNeeded()
    }

    func loadProposalChoiceCatalogsIfNeeded() async {
        if appState.oshiGroups.isEmpty {
            await appState.loadOshiGroups()
        }
        if appState.goodsTypes.isEmpty {
            await appState.loadGoodsTypes()
        }
    }

    func loadPaymentSettingsIfNeeded() async {
        if appState.paymentSettings == nil {
            await appState.loadPaymentSettings()
        }
        syncPaymentSelectionIfNeeded()
    }

    func seedDefaultMeetupConditionsIfNeeded() {
        guard meetupPrefecture.isBlank else {
            return
        }
        if let summary = viewerListingExchangeSummary, summary.includesLocal {
            meetupPrefecture = summary.localPrefecture
            meetupPlaceMemo = summary.localPlaceMemo
            if let date = Self.date(fromScheduleText: summary.localSchedule) {
                meetupStartAt = date
                meetupEndAt = date.addingTimeInterval(30 * 60)
            }
        } else if let viewerPrefecture = appState.viewer?.prefecture.nilIfBlank {
            meetupPrefecture = viewerPrefecture
        } else if let ownerPrefecture = targetItem.ownerPrefecture.nilIfBlank {
            meetupPrefecture = ownerPrefecture
        }
    }

    func seedDefaultShippingConditionsIfNeeded() {
        guard let summary = viewerListingExchangeSummary, summary.includesMail else {
            return
        }
        shippingFee = summary.shippingFee
        shippingDays = summary.shippingDays
    }

    func handleExchangeMethodChange() {
        if selectedStep == .meetup && !configuration.requiresMeetupBeforeSubmit {
            selectedStep = configuration.requiresShippingBeforeSubmit ? .shipping : .confirm
        }
        if selectedStep == .shipping && !configuration.requiresShippingBeforeSubmit {
            selectedStep = configuration.requiresMeetupBeforeSubmit ? .meetup : .confirm
        }
        if selectedStep == .payment && !configuration.requiresPaymentSelection {
            selectedStep = .confirm
        }
        applyInitialStepIfNeeded()
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

    func applyInitialExchangeMethodIfNeeded() {
        guard !didApplyInitialExchangeMethod else {
            return
        }
        didApplyInitialExchangeMethod = true
        guard let initialExchangeMethod else {
            return
        }
        exchangeMethod = initialExchangeMethod
    }

    func applyVisualQAStateIfNeeded() {
        guard !didApplyVisualQAState else {
            return
        }
        didApplyVisualQAState = true
        guard visualQAInitialScreen == .proposalConfirm || visualQAInitialScreen == .proposalComplete else {
            return
        }
        seedVisualQAMeetupCandidateIfNeeded()
        message = ""
        shareSchedule = true
        selectedStep = .confirm
        if visualQAInitialScreen == .proposalComplete {
            submittedSummary = ProposalSubmittedSummary(
                senderCount: max(senderSelectionCount, 1),
                receiverCount: max(receiverSelectionCount, 1),
                partnerHandle: displayPartnerHandle,
                methodTitle: Self.methodTitle(exchangeMethod),
                meetupSummary: meetupSummary,
                conditionTags: [],
                exchangeMethod: exchangeMethod
            )
        }
    }

    func seedVisualQAMeetupCandidateIfNeeded() {
        guard configuration.requiresMeetupBeforeSubmit, meetupCandidateDrafts.isEmpty else {
            return
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        let start = calendar.date(from: DateComponents(year: 2026, month: 6, day: 7, hour: 16, minute: 30)) ?? Date()
        let end = start.addingTimeInterval(45 * 60)
        let draft = ProposalMeetupCandidateDraft(
            startAt: start,
            endAt: end,
            placeName: "東京ドーム 22ゲート前",
            latitudeText: "35.7056",
            longitudeText: "139.7519"
        )
        meetupCandidateDrafts = [draft]
        applyMeetupCandidate(draft, at: 0)
    }

    func applyInitialStepIfNeeded() {
        guard !didApplyInitialStep else {
            return
        }
        guard visibleSteps.contains(initialStep) else {
            didApplyInitialStep = true
            return
        }
        if visibleSteps
            .prefix(while: { $0 != initialStep })
            .allSatisfy({ configuration.canAdvance(from: $0) })
        {
            selectedStep = initialStep
            didApplyInitialStep = true
        }
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
        guard configuration.canSubmit, let targetStatus = configuration.targetStatus else {
            return
        }
        saveSelectedMeetupCandidate()
        let meetupCandidates = configuration.requiresMeetupBeforeSubmit ? meetupInputsForSubmission : []
        let meetup = meetupCandidates.first
        guard !configuration.requiresMeetupBeforeSubmit || meetup != nil else {
            return
        }
        let draft = ProposalCreateSubmissionDraft(
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
        let created = await appState.createProposal(draft.input)
        if created {
            withAnimation(.snappy) {
                submittedSummary = draft.summary
            }
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
