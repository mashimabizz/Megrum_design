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
        // 相手の交換カレンダー（現地交換可能な場所と日程）と表示名のため、
        // 相手のプロフィール・交換設定・アクティビティウィンドウを読み込む。
        await appState.loadPublicUserProfile(userID: targetItem.ownerID, reportsFailure: false)
        await appState.loadPublicExchangeSettings(userID: targetItem.ownerID)
        await appState.loadPartnerActivityWindows(userID: targetItem.ownerID)
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
        guard let draft = ProposalMeetupConditionDraftResolver.resolvedDraft(
            viewerListingSummary: viewerListingExchangeSummary,
            defaultSummary: defaultExchangeSummary,
            viewerPrefecture: appState.viewer?.prefecture,
            ownerPrefecture: targetItem.ownerPrefecture
        ) else {
            return
        }
        meetupPrefecture = draft.prefecture
        if let placeMemo = draft.placeMemo {
            meetupPlaceMemo = placeMemo
        }
        if let startAt = draft.startAt, let endAt = draft.endAt {
            meetupStartAt = startAt
            meetupEndAt = endAt
        }
    }

    func seedDefaultShippingConditionsIfNeeded() {
        let draft = ProposalShippingConditionDraftResolver.resolvedDraft(
            viewerListingSummary: viewerListingExchangeSummary,
            initialFee: initialShippingFee,
            initialDays: initialShippingDays,
            defaultSummary: defaultExchangeSummary
        )
        shippingFee = draft.fee
        shippingDays = draft.days
    }

    func handleExchangeMethodChange() {
        selectedStep = ProposalExchangeMethodStepResolver.resolvedStepAfterExchangeMethodChange(
            currentStep: selectedStep,
            requiresMeetupBeforeSubmit: configuration.requiresMeetupBeforeSubmit,
            requiresShippingBeforeSubmit: configuration.requiresShippingBeforeSubmit,
            requiresPaymentSelection: configuration.requiresPaymentSelection
        )
        applyInitialStepIfNeeded()
    }

    func applyInitialExchangeMethodIfNeeded() {
        guard initialStateFlags.claimExchangeMethodApplication() else {
            return
        }
        guard let initialExchangeMethod else {
            return
        }
        exchangeMethod = initialExchangeMethod
    }

    func applyVisualQAStateIfNeeded() {
        guard initialStateFlags.claimVisualQAStateApplication() else {
            return
        }
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
                methodTitle: ProposalCreateDisplayTextFormatter.methodTitle(exchangeMethod),
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
        guard initialStateFlags.canApplyInitialStep() else {
            return
        }
        switch ProposalInitialStepResolver.resolution(
            initialStep: initialStep,
            visibleSteps: visibleSteps,
            configuration: configuration
        ) {
        case .apply(let step):
            selectedStep = step
            initialStateFlags.markInitialStepApplied()
        case .markApplied:
            initialStateFlags.markInitialStepApplied()
        case .wait:
            return
        }
    }
}
