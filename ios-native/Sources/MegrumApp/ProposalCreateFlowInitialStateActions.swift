import Foundation
import MegrumCore

extension ProposalCreateFlow {
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
        if let summary = viewerListingExchangeSummary, summary.includesMail {
            shippingFee = summary.shippingFee
            shippingDays = summary.shippingDays
            return
        }
        if let initialShippingFee {
            shippingFee = initialShippingFee
        }
        if let initialShippingDays {
            shippingDays = initialShippingDays
        }
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
}
