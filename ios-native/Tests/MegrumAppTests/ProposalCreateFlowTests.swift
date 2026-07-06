@testable import MegrumApp
import Foundation
import MapKit
import MegrumCore
import XCTest

final class ProposalCreateFlowTests: XCTestCase {
    func testProposalCompletionAnimationPresentationStateResolvesMotionValues() {
        var state = ProposalCompletionAnimationPresentationState()

        XCTAssertEqual(state.haloScale(reduceMotion: false), 0.82)
        XCTAssertEqual(state.haloScale(reduceMotion: true), 0.82)
        XCTAssertEqual(state.haloOpacity, 0.4)
        XCTAssertEqual(state.badgeScale(reduceMotion: false), 0.72)
        XCTAssertEqual(state.badgeScale(reduceMotion: true), 1)
        XCTAssertEqual(state.sparkleOffsetValue(100, reduceMotion: false), 52)
        XCTAssertEqual(state.sparkleScale(reduceMotion: false), 0.36)
        XCTAssertEqual(state.sparkleOpacity, 0)

        state.show()

        XCTAssertEqual(state.haloScale(reduceMotion: false), 1.16)
        XCTAssertEqual(state.haloScale(reduceMotion: true), 0.82)
        XCTAssertEqual(state.haloOpacity, 1)
        XCTAssertEqual(state.badgeScale(reduceMotion: false), 1)
        XCTAssertEqual(state.sparkleOffsetValue(100, reduceMotion: false), 100)
        XCTAssertEqual(state.sparkleScale(reduceMotion: false), 1)
        XCTAssertEqual(state.sparkleOpacity, 1)
    }

    func testProposalCreateStepsStayInVisibleParityOrder() {
        XCTAssertEqual(
            ProposalCreateStep.allCases.map(\.title),
            ["出すもの", "受け取る", "交換条件", "待ち合わせ", "送料", "支払方法", "確認"]
        )
    }

    func testProposalHeaderLeadingActionResolverKeepsBackOrDismissBehavior() {
        XCTAssertEqual(ProposalHeaderLeadingActionResolver.action(for: .give), .dismiss)
        XCTAssertEqual(ProposalHeaderLeadingActionResolver.action(for: .receive), .previousStep)
        XCTAssertEqual(ProposalHeaderLeadingActionResolver.action(for: .conditions), .previousStep)
        XCTAssertEqual(ProposalHeaderLeadingActionResolver.action(for: .meetup), .dismiss)
        XCTAssertEqual(ProposalHeaderLeadingActionResolver.action(for: .shipping), .dismiss)
        XCTAssertEqual(ProposalHeaderLeadingActionResolver.action(for: .payment), .previousStep)
        XCTAssertEqual(ProposalHeaderLeadingActionResolver.action(for: .confirm), .previousStep)
    }

    func testProposalPreviousStepResolverUsesVisibleOrderOnlyWhenPossible() {
        let visibleSteps: [ProposalCreateStep] = [.give, .receive, .meetup, .confirm]

        XCTAssertNil(
            ProposalPreviousStepResolver.destination(
                from: .give,
                visibleSteps: visibleSteps
            )
        )
        XCTAssertEqual(
            ProposalPreviousStepResolver.destination(
                from: .meetup,
                visibleSteps: visibleSteps
            ),
            .receive
        )
        XCTAssertEqual(
            ProposalPreviousStepResolver.destination(
                from: .confirm,
                visibleSteps: visibleSteps
            ),
            .meetup
        )
        XCTAssertNil(
            ProposalPreviousStepResolver.destination(
                from: .payment,
                visibleSteps: visibleSteps
            )
        )
    }

    func testProposalExchangeMethodStepResolverMovesAwayFromUnavailableSteps() {
        XCTAssertEqual(
            ProposalExchangeMethodStepResolver.resolvedStepAfterExchangeMethodChange(
                currentStep: .meetup,
                requiresMeetupBeforeSubmit: false,
                requiresShippingBeforeSubmit: true,
                requiresPaymentSelection: false
            ),
            .shipping
        )
        XCTAssertEqual(
            ProposalExchangeMethodStepResolver.resolvedStepAfterExchangeMethodChange(
                currentStep: .meetup,
                requiresMeetupBeforeSubmit: false,
                requiresShippingBeforeSubmit: false,
                requiresPaymentSelection: false
            ),
            .confirm
        )
        XCTAssertEqual(
            ProposalExchangeMethodStepResolver.resolvedStepAfterExchangeMethodChange(
                currentStep: .shipping,
                requiresMeetupBeforeSubmit: true,
                requiresShippingBeforeSubmit: false,
                requiresPaymentSelection: false
            ),
            .meetup
        )
        XCTAssertEqual(
            ProposalExchangeMethodStepResolver.resolvedStepAfterExchangeMethodChange(
                currentStep: .shipping,
                requiresMeetupBeforeSubmit: false,
                requiresShippingBeforeSubmit: false,
                requiresPaymentSelection: false
            ),
            .confirm
        )
        XCTAssertEqual(
            ProposalExchangeMethodStepResolver.resolvedStepAfterExchangeMethodChange(
                currentStep: .payment,
                requiresMeetupBeforeSubmit: true,
                requiresShippingBeforeSubmit: true,
                requiresPaymentSelection: false
            ),
            .confirm
        )
        XCTAssertEqual(
            ProposalExchangeMethodStepResolver.resolvedStepAfterExchangeMethodChange(
                currentStep: .payment,
                requiresMeetupBeforeSubmit: true,
                requiresShippingBeforeSubmit: true,
                requiresPaymentSelection: true
            ),
            .payment
        )
        XCTAssertEqual(
            ProposalExchangeMethodStepResolver.resolvedStepAfterExchangeMethodChange(
                currentStep: .give,
                requiresMeetupBeforeSubmit: false,
                requiresShippingBeforeSubmit: false,
                requiresPaymentSelection: false
            ),
            .give
        )
    }

    func testProposalCreateDisplayTextFormatterKeepsMethodAndDateText() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 7, hour: 12))!

        XCTAssertEqual(ProposalCreateDisplayTextFormatter.methodTitle(.hand), "現地交換")
        XCTAssertEqual(ProposalCreateDisplayTextFormatter.methodTitle(.mail), "郵送交換")
        XCTAssertEqual(ProposalCreateDisplayTextFormatter.methodTitle(.both), "現地 / 郵送")
        XCTAssertEqual(ProposalCreateDisplayTextFormatter.dateText(date), "6月7日")
    }

    func testProposalCreateInitialStateFlagsAreOneShot() {
        var flags = ProposalCreateInitialStateFlags()

        XCTAssertTrue(flags.claimExchangeMethodApplication())
        XCTAssertFalse(flags.claimExchangeMethodApplication())
        XCTAssertTrue(flags.hasAppliedExchangeMethod)

        XCTAssertTrue(flags.claimVisualQAStateApplication())
        XCTAssertFalse(flags.claimVisualQAStateApplication())
        XCTAssertTrue(flags.hasAppliedVisualQAState)

        XCTAssertTrue(flags.canApplyInitialStep())
        flags.markInitialStepApplied()
        XCTAssertFalse(flags.canApplyInitialStep())
        XCTAssertTrue(flags.hasAppliedInitialStep)
    }

    func testProposalCreateFilterStateFiltersEachSideIndependently() {
        let groupA = UUID(uuidString: "00000000-0000-0000-0000-000000000901")!
        let groupB = UUID(uuidString: "00000000-0000-0000-0000-000000000902")!
        let typeA = UUID(uuidString: "00000000-0000-0000-0000-000000000903")!
        let typeB = UUID(uuidString: "00000000-0000-0000-0000-000000000904")!
        let first = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000905")!,
            ownerID: UUID(),
            groupID: groupA,
            goodsTypeID: typeA,
            title: "first"
        )
        let second = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000906")!,
            ownerID: UUID(),
            groupID: groupB,
            goodsTypeID: typeB,
            title: "second"
        )
        let goods = [first, second]
        let filterState = ProposalCreateFilterState(
            senderGroupID: groupA,
            senderGoodsTypeID: typeA,
            receiverGroupID: groupB,
            receiverGoodsTypeID: typeB
        )

        XCTAssertEqual(filterState.filteredSenderGoods(from: goods).map(\.id), [first.id])
        XCTAssertEqual(filterState.filteredReceiverGoods(from: goods).map(\.id), [second.id])
    }

    func testProposalCreateGoodsSelectionReducerTogglesAndSeedsFromAvailableFallbacks() {
        let first = UUID(uuidString: "00000000-0000-0000-0000-000000000921")!
        let second = UUID(uuidString: "00000000-0000-0000-0000-000000000922")!
        let missing = UUID(uuidString: "00000000-0000-0000-0000-000000000923")!

        XCTAssertEqual(ProposalCreateGoodsSelectionReducer.toggled([], id: first), [first])
        XCTAssertEqual(ProposalCreateGoodsSelectionReducer.toggled([first], id: first), [])
        XCTAssertEqual(
            ProposalCreateGoodsSelectionReducer.seeded(
                selectedIDs: [],
                availableIDs: [first, second],
                fallbackIDs: [missing, second]
            ),
            [second]
        )
        XCTAssertEqual(
            ProposalCreateGoodsSelectionReducer.seeded(
                selectedIDs: [first],
                availableIDs: [second],
                fallbackIDs: [second]
            ),
            [first]
        )
    }

    func testProposalCreateGoodsSelectionReducerReconcilesBeforeApplyingFallbacks() {
        let first = UUID(uuidString: "00000000-0000-0000-0000-000000000931")!
        let second = UUID(uuidString: "00000000-0000-0000-0000-000000000932")!
        let third = UUID(uuidString: "00000000-0000-0000-0000-000000000933")!

        XCTAssertEqual(
            ProposalCreateGoodsSelectionReducer.reconciled(
                selectedIDs: [first, second],
                availableIDs: [second, third],
                fallbackIDs: [third]
            ),
            [second]
        )
        XCTAssertEqual(
            ProposalCreateGoodsSelectionReducer.reconciled(
                selectedIDs: [first],
                availableIDs: [second, third],
                fallbackIDs: [third]
            ),
            [third]
        )
    }

    func testProposalCreateValueSelectionStateNormalizesCashAndSyncsPaymentOption() {
        let first = ProposalPaymentOption(
            id: "first",
            title: "PayPay",
            subtitle: nil,
            section: .mutuallyAccepted,
            kind: .method(.paypay)
        )
        let second = ProposalPaymentOption(
            id: "second",
            title: "銀行振込",
            subtitle: nil,
            section: .needsDiscussion,
            kind: .method(.bankTransfer)
        )
        var state = ProposalCreateValueSelectionState()

        state.senderCashAmountText = "1,234円"
        state.normalizeSenderCashAmountText(state.senderCashAmountText)
        XCTAssertEqual(state.senderCashAmountText, "1,234")
        XCTAssertEqual(state.senderCashAmount, 1234)
        XCTAssertTrue(state.requiresPaymentStep)

        state.syncPaymentSelectionIfNeeded(options: [first, second])
        XCTAssertEqual(state.selectedPaymentOptionID, "first")

        state.selectedPaymentOptionID = "second"
        state.syncPaymentSelectionIfNeeded(options: [first, second])
        XCTAssertEqual(state.selectedPaymentOptionID, "second")

        state.senderCashAmountText = ""
        state.syncPaymentSelectionIfNeeded(options: [first, second])
        XCTAssertNil(state.selectedPaymentOptionID)
    }

    func testProposalPaymentOptionSelectionResolverKeepsOrResetsSelection() {
        let first = ProposalPaymentOption(
            id: "first",
            title: "PayPay",
            subtitle: nil,
            section: .mutuallyAccepted,
            kind: .method(.paypay)
        )
        let second = ProposalPaymentOption(
            id: "second",
            title: "銀行振込",
            subtitle: nil,
            section: .needsDiscussion,
            kind: .method(.bankTransfer)
        )

        XCTAssertNil(
            ProposalPaymentOptionSelectionResolver.resolvedSelectionID(
                currentID: "first",
                requiresPaymentStep: false,
                options: [first, second]
            )
        )
        XCTAssertNil(
            ProposalPaymentOptionSelectionResolver.resolvedSelectionID(
                currentID: "first",
                requiresPaymentStep: true,
                options: []
            )
        )
        XCTAssertEqual(
            ProposalPaymentOptionSelectionResolver.resolvedSelectionID(
                currentID: "second",
                requiresPaymentStep: true,
                options: [first, second]
            ),
            "second"
        )
        XCTAssertEqual(
            ProposalPaymentOptionSelectionResolver.resolvedSelectionID(
                currentID: "missing",
                requiresPaymentStep: true,
                options: [first, second]
            ),
            "first"
        )
    }

    func testProposalShippingConditionDraftResolverKeepsExistingPriority() {
        let viewerSummary = IndividualListingExchangeSummary(
            handoffMethod: .mail,
            shippingFee: .owner,
            shippingDays: .oneDay
        )
        let defaultSummary = IndividualListingExchangeSummary(
            handoffMethod: .mail,
            shippingFee: .partner,
            shippingDays: .afterFiveDays
        )

        XCTAssertEqual(
            ProposalShippingConditionDraftResolver.resolvedDraft(
                viewerListingSummary: viewerSummary,
                initialFee: .negotiate,
                initialDays: .twoToFourDays,
                defaultSummary: defaultSummary
            ),
            ProposalShippingConditionDraft(fee: .owner, days: .oneDay)
        )
        XCTAssertEqual(
            ProposalShippingConditionDraftResolver.resolvedDraft(
                viewerListingSummary: nil,
                initialFee: .negotiate,
                initialDays: nil,
                defaultSummary: defaultSummary
            ),
            ProposalShippingConditionDraft(fee: .negotiate, days: .afterFiveDays)
        )
        XCTAssertEqual(
            ProposalShippingConditionDraftResolver.resolvedDraft(
                viewerListingSummary: nil,
                initialFee: nil,
                initialDays: nil,
                defaultSummary: IndividualListingExchangeSummary(handoffMethod: .local)
            ),
            ProposalShippingConditionDraft(fee: .negotiate, days: .twoToFourDays)
        )
    }

    func testProposalMeetupConditionDraftResolverKeepsExistingPriority() throws {
        let viewerSummary = IndividualListingExchangeSummary(
            handoffMethod: .local,
            localPrefecture: "大阪府",
            localPlaceMemo: "京セラドーム前",
            localSchedule: "6月7日"
        )
        let defaultSummary = IndividualListingExchangeSummary(
            handoffMethod: .local,
            localPrefecture: "東京都",
            localPlaceMemo: "東京ドーム",
            localSchedule: "6月8日"
        )

        let viewerDraft = try XCTUnwrap(
            ProposalMeetupConditionDraftResolver.resolvedDraft(
                viewerListingSummary: viewerSummary,
                defaultSummary: defaultSummary,
                viewerPrefecture: "福岡県",
                ownerPrefecture: "北海道"
            )
        )
        let viewerStartAt = try XCTUnwrap(viewerDraft.startAt)

        XCTAssertEqual(viewerDraft.prefecture, "大阪府")
        XCTAssertEqual(viewerDraft.placeMemo, "京セラドーム前")
        XCTAssertEqual(viewerStartAt, ProposalScheduleTextDateParser.date(from: "6月7日"))
        XCTAssertEqual(viewerDraft.endAt, viewerStartAt.addingTimeInterval(30 * 60))

        XCTAssertEqual(
            ProposalMeetupConditionDraftResolver.resolvedDraft(
                viewerListingSummary: nil,
                defaultSummary: IndividualListingExchangeSummary(handoffMethod: .mail),
                viewerPrefecture: " 福岡県 ",
                ownerPrefecture: "北海道"
            ),
            ProposalMeetupConditionDraft(prefecture: "福岡県")
        )
        XCTAssertEqual(
            ProposalMeetupConditionDraftResolver.resolvedDraft(
                viewerListingSummary: nil,
                defaultSummary: IndividualListingExchangeSummary(handoffMethod: .mail),
                viewerPrefecture: " ",
                ownerPrefecture: "北海道"
            ),
            ProposalMeetupConditionDraft(prefecture: "北海道")
        )
    }

    func testProposalMeetupConditionRowsUseSharedMinimumHeight() {
        XCTAssertEqual(ProposalMeetupConditionMetrics.rowMinHeight, 48)
        XCTAssertEqual(ProposalMeetupConditionMetrics.rowVerticalPadding, 10)
    }

    func testProposalFlowCannotAdvancePastGiveWithoutSenderGoods() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .hand,
            hasSelectedSenderGoods: false,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: true,
            receiverGoodsCount: 1,
            isListingSource: false
        )

        XCTAssertFalse(configuration.canAdvance(from: .give))
        XCTAssertEqual(configuration.blockedTitle(for: .give), "出すものを選択してください")
    }

    func testProposalFlowRequiresMeetupBeforeConfirmForHandExchange() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .hand,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            receiverGoodsCount: 1,
            isListingSource: false
        )

        XCTAssertTrue(configuration.canAdvance(from: .give))
        XCTAssertTrue(configuration.canAdvance(from: .receive))
        XCTAssertFalse(configuration.canAdvance(from: .meetup))
        XCTAssertFalse(configuration.canAdvance(from: .confirm))
    }

    func testProposalFlowCannotSubmitWithoutReceiverGoods() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .mail,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            receiverGoodsCount: 0,
            isListingSource: false
        )

        XCTAssertFalse(configuration.canSubmit)
        XCTAssertEqual(configuration.submitTitle, "受け取るものを選択")
    }

    func testProposalFlowCanUseCashOnReceiverSideInsteadOfReceiverGoods() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .mail,
            hasSelectedSenderGoods: true,
            hasReceiverCashRequest: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            receiverGoodsCount: 0,
            isListingSource: false
        )

        XCTAssertTrue(configuration.canAdvance(from: .receive))
        XCTAssertTrue(configuration.canSubmit)
    }

    func testProposalSubmissionTargetStatusResolverRequiresSubmitAndHonorsOverride() {
        XCTAssertEqual(
            ProposalSubmissionTargetStatusResolver.status(
                canSubmit: true,
                defaultTargetStatus: .sent,
                override: nil
            ),
            .sent
        )
        XCTAssertEqual(
            ProposalSubmissionTargetStatusResolver.status(
                canSubmit: true,
                defaultTargetStatus: .sent,
                override: .negotiating
            ),
            .negotiating
        )
        XCTAssertNil(
            ProposalSubmissionTargetStatusResolver.status(
                canSubmit: false,
                defaultTargetStatus: .sent,
                override: .negotiating
            )
        )
        XCTAssertNil(
            ProposalSubmissionTargetStatusResolver.status(
                canSubmit: true,
                defaultTargetStatus: nil,
                override: .negotiating
            )
        )
    }

    func testProposalFlowRequiresPaymentSelectionWhenCashIsIncluded() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .mail,
            hasSelectedSenderGoods: true,
            hasReceiverCashRequest: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            requiresPaymentSelection: true,
            hasSelectedPaymentMethod: false,
            receiverGoodsCount: 0,
            isListingSource: false
        )

        XCTAssertFalse(configuration.canAdvance(from: .payment))
        XCTAssertFalse(configuration.canSubmit)
        XCTAssertEqual(configuration.blockedTitle(for: .payment), "支払方法を選択してください")

        let selected = ProposalCreateConfiguration(
            exchangeMethod: .mail,
            hasSelectedSenderGoods: true,
            hasReceiverCashRequest: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            requiresPaymentSelection: true,
            hasSelectedPaymentMethod: true,
            receiverGoodsCount: 0,
            isListingSource: false
        )

        XCTAssertTrue(selected.canAdvance(from: .payment))
        XCTAssertTrue(selected.canSubmit)
    }

    func testProposalPaymentCatalogShowsSharedMethodsAndPartnerOtherAsAccepted() {
        let sections = ProposalPaymentOptionCatalog.sections(
            viewerMethods: [.paypay, .bankTransfer],
            viewerOtherNote: "メルペイ",
            partnerMethods: [.paypay, .cashExchange, .other],
            partnerOtherNote: "楽天ペイ"
        )
        let mutuallyAccepted = sections.first { $0.section == .mutuallyAccepted }?.options ?? []
        let discussion = sections.first { $0.section == .needsDiscussion }?.options ?? []

        XCTAssertEqual(mutuallyAccepted.map(\.title), ["PayPay", "その他（相手の入力）"])
        XCTAssertEqual(mutuallyAccepted.map(\.confirmationTitle), ["PayPay", "楽天ペイ"])
        XCTAssertTrue(discussion.map(\.title).contains("銀行振込"))
        XCTAssertTrue(discussion.map(\.title).contains("現金交換"))
        XCTAssertTrue(discussion.map(\.title).contains("その他（自分の入力）"))
        XCTAssertFalse(discussion.map(\.title).contains("その他（相手の入力）"))
    }

    func testProposalPaymentCatalogMovesAllOptionsToDiscussionWhenThereIsNoSharedConcreteMethod() {
        let sections = ProposalPaymentOptionCatalog.sections(
            viewerMethods: [.bankTransfer],
            viewerOtherNote: "メルペイ",
            partnerMethods: [.paypay, .other],
            partnerOtherNote: "楽天ペイ"
        )

        XCTAssertNil(sections.first { $0.section == .mutuallyAccepted })
        let discussion = sections.first { $0.section == .needsDiscussion }?.options ?? []
        XCTAssertEqual(
            discussion.map(\.title),
            ["銀行振込", "PayPay", "その他（自分の入力）", "その他（相手の入力）"]
        )
        XCTAssertEqual(discussion.last?.confirmationTitle, "楽天ペイ")
    }

    func testProposalPaymentCatalogFallsBackToDiscussionWhenBothUsersHaveNoPaymentSettings() {
        let sections = ProposalPaymentOptionCatalog.sections(
            viewerMethods: [],
            viewerOtherNote: nil,
            partnerMethods: [],
            partnerOtherNote: nil
        )

        XCTAssertNil(sections.first { $0.section == .mutuallyAccepted })
        XCTAssertEqual(
            sections.first { $0.section == .needsDiscussion }?.options.map(\.title),
            ["相談して決める"]
        )
    }

    func testProposalFlowCanUseGoodsAndCashOnSenderSideTogether() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .mail,
            hasSelectedSenderGoods: true,
            hasCashOffer: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            receiverGoodsCount: 1,
            isListingSource: false
        )

        XCTAssertTrue(configuration.canAdvance(from: .give))
        XCTAssertTrue(configuration.canAdvance(from: .receive))
        XCTAssertTrue(configuration.canSubmit)
    }

    func testProposalFlowRejectsCashOnBothSides() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .mail,
            hasSelectedSenderGoods: true,
            hasCashOffer: true,
            hasReceiverCashRequest: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            receiverGoodsCount: 1,
            isListingSource: false
        )

        XCTAssertFalse(configuration.canSubmit)
        XCTAssertEqual(configuration.submitTitle, "片側はグッズを選択")
    }

    func testProposalFlowCanReachConfirmWhenSelectionsAndMeetupAreReady() {
        let configuration = ProposalCreateConfiguration(
            exchangeMethod: .hand,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: false,
            isLoadingMailingAddress: false,
            hasValidMeetup: true,
            receiverGoodsCount: 2,
            isListingSource: true
        )

        XCTAssertTrue(ProposalCreateStep.allCases.allSatisfy { configuration.canAdvance(from: $0) })
        XCTAssertEqual(configuration.targetStatus, .sent)
        XCTAssertEqual(configuration.targetSupplement, "ほか1件も受け取る条件です")
    }

    func testProposalMeetupEndDateResolverKeepsOrPushesEndAfterStart() {
        let start = Date(timeIntervalSince1970: 1_000)
        let earlierEnd = Date(timeIntervalSince1970: 900)
        let sameEnd = start
        let laterEnd = Date(timeIntervalSince1970: 2_000)

        XCTAssertEqual(
            ProposalMeetupEndDateResolver.adjustedEnd(startAt: start, currentEndAt: earlierEnd),
            Date(timeIntervalSince1970: 2_800)
        )
        XCTAssertEqual(
            ProposalMeetupEndDateResolver.adjustedEnd(startAt: start, currentEndAt: sameEnd),
            Date(timeIntervalSince1970: 2_800)
        )
        XCTAssertEqual(
            ProposalMeetupEndDateResolver.adjustedEnd(startAt: start, currentEndAt: laterEnd),
            laterEnd
        )
    }

    func testProposalMeetupMapRegionBuilderKeepsExistingSpans() throws {
        XCTAssertNil(ProposalMeetupMapRegionBuilder.region(for: []))

        let primary = ProposalMeetupInput(
            startAt: Date(timeIntervalSince1970: 1_000),
            endAt: Date(timeIntervalSince1970: 2_800),
            placeName: "東京ドーム 22ゲート前",
            latitude: 35.7056,
            longitude: 139.7519
        )
        let single = try XCTUnwrap(ProposalMeetupMapRegionBuilder.region(for: [primary]))

        XCTAssertEqual(single.center.latitude, 35.7056, accuracy: 0.000_001)
        XCTAssertEqual(single.center.longitude, 139.7519, accuracy: 0.000_001)
        XCTAssertEqual(single.span.latitudeDelta, 0.008, accuracy: 0.000_001)
        XCTAssertEqual(single.span.longitudeDelta, 0.008, accuracy: 0.000_001)

        let secondary = ProposalMeetupInput(
            startAt: Date(timeIntervalSince1970: 4_000),
            endAt: Date(timeIntervalSince1970: 5_800),
            placeName: "水道橋駅 東口",
            latitude: 35.7014,
            longitude: 139.7548
        )
        let multiple = try XCTUnwrap(ProposalMeetupMapRegionBuilder.region(for: [primary, secondary]))

        XCTAssertEqual(multiple.center.latitude, (35.7014 + 35.7056) / 2, accuracy: 0.000_001)
        XCTAssertEqual(multiple.center.longitude, (139.7519 + 139.7548) / 2, accuracy: 0.000_001)
        XCTAssertEqual(multiple.span.latitudeDelta, 0.01, accuracy: 0.000_001)
        XCTAssertEqual(multiple.span.longitudeDelta, 0.01, accuracy: 0.000_001)
    }

    func testProposalMeetupSubmissionCandidatesResolverKeepsRequiredMeetupRule() {
        let input = ProposalMeetupInput(
            startAt: Date(timeIntervalSince1970: 1_000),
            endAt: Date(timeIntervalSince1970: 2_800),
            placeName: "東京ドーム 22ゲート前",
            latitude: 35.7056,
            longitude: 139.7519
        )

        XCTAssertEqual(
            ProposalMeetupSubmissionCandidatesResolver.candidates(
                requiresMeetupBeforeSubmit: false,
                meetupInputs: [input]
            ),
            []
        )
        XCTAssertNil(
            ProposalMeetupSubmissionCandidatesResolver.candidates(
                requiresMeetupBeforeSubmit: true,
                meetupInputs: []
            )
        )
        XCTAssertEqual(
            ProposalMeetupSubmissionCandidatesResolver.candidates(
                requiresMeetupBeforeSubmit: true,
                meetupInputs: [input]
            ),
            [input]
        )
    }

    func testProposalSubmittedSummaryOmitsTagsWhenEmpty() {
        let summary = ProposalSubmittedSummary(
            senderCount: 2,
            receiverCount: 1,
            partnerHandle: "michilion",
            methodTitle: "現地交換",
            meetupSummary: "6月1日 12:00 / 横浜アリーナ",
            conditionTags: [],
            exchangeMethod: .hand
        )

        XCTAssertEqual(summary.detailText, "2件を提示 / 1件を受け取り候補で送信しました。")
        XCTAssertEqual(summary.completionTitle, "打診が完了しました")
        XCTAssertEqual(summary.completionMessage, "@michilion に打診を送りました。返事が届いたら通知と打診一覧で確認できます。")
    }

    func testProposalSubmittedSummaryIncludesConditionTags() {
        let summary = ProposalSubmittedSummary(
            senderCount: 1,
            receiverCount: 3,
            partnerHandle: "michilion",
            methodTitle: "現地 / 郵送",
            meetupSummary: "6月1日 12:00 / 横浜アリーナ",
            conditionTags: ["終演後OK", "同日発送"],
            exchangeMethod: .both
        )

        XCTAssertEqual(summary.detailText, "1件を提示 / 3件を受け取り候補・終演後OK / 同日発送")
        XCTAssertEqual(summary.completionMessage, "@michilion に現地・郵送どちらも可能な打診を送りました。返事が届いたら打診一覧で確認できます。")
    }

    func testProposalSubmittedSummarySupportsMailExchangeCompletionCopy() {
        let summary = ProposalSubmittedSummary(
            senderCount: 1,
            receiverCount: 1,
            partnerHandle: "michilion",
            methodTitle: "郵送交換",
            meetupSummary: "現地では会わない設定",
            conditionTags: [],
            exchangeMethod: .mail
        )

        XCTAssertEqual(summary.completionMessage, "@michilion に郵送交換の打診を送りました。双方が合意すると住所が表示されます。")
    }

    func testProposalCompletionButtonsMatchRnOrderAndRoles() {
        XCTAssertEqual(
            ProposalCompletionButtonCopy.buttons,
            [
                ProposalCompletionButtonSpec(action: .searchMore, title: "まだ他に探す", role: .secondary),
                ProposalCompletionButtonSpec(action: .openTrades, title: "打診一覧に飛ぶ", role: .primary)
            ]
        )
    }

    func testProposalCreateSubmissionDraftBuildsPayloadAndCompletionSummaryFromSameConfirmState() {
        let receiverID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let senderGoodsID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let receiverGoodsID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let listingID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
        let primaryMeetup = ProposalMeetupInput(
            startAt: Date(timeIntervalSince1970: 1_000),
            endAt: Date(timeIntervalSince1970: 2_800),
            placeName: "東京ドーム 22ゲート前",
            latitude: 35.7056,
            longitude: 139.7519
        )
        let secondaryMeetup = ProposalMeetupInput(
            startAt: Date(timeIntervalSince1970: 4_000),
            endAt: Date(timeIntervalSince1970: 5_800),
            placeName: "水道橋駅 東口",
            latitude: 35.7014,
            longitude: 139.7548
        )
        let draft = ProposalCreateSubmissionDraft(
            receiverID: receiverID,
            senderGoodsIDs: [senderGoodsID],
            receiverGoodsIDs: [receiverGoodsID],
            exchangeMethod: .hand,
            conditionTags: ["終演後OK", "短時間OK"],
            message: " よろしくお願いします ",
            matchType: .perfect,
            status: .sent,
            meetupCandidates: [primaryMeetup, secondaryMeetup],
            exposeCalendar: true,
            listingID: listingID,
            cashAmount: 1_200,
            cashAmountSide: .sender,
            senderCount: 1,
            receiverCount: 1,
            partnerHandle: "michilion",
            methodTitle: "現地交換",
            meetupSummary: "1月1日 9:16 / 東京ドーム 22ゲート前"
        )

        XCTAssertEqual(draft.input.receiverID, receiverID)
        XCTAssertEqual(draft.input.senderGoodsIDs, [senderGoodsID])
        XCTAssertEqual(draft.input.receiverGoodsIDs, [receiverGoodsID])
        XCTAssertEqual(draft.input.matchType, .perfect)
        XCTAssertEqual(draft.input.listingID, listingID)
        XCTAssertEqual(draft.input.message, "よろしくお願いします")
        XCTAssertEqual(draft.input.meetup, primaryMeetup)
        XCTAssertEqual(draft.input.meetupCandidates, [primaryMeetup, secondaryMeetup])
        XCTAssertEqual(draft.input.exposeCalendar, true)
        XCTAssertEqual(draft.input.cashAmount, 1_200)
        XCTAssertEqual(draft.input.cashAmountSide, .sender)
        XCTAssertEqual(draft.summary.completionMessage, "@michilion に打診を送りました。返事が届いたら通知と打診一覧で確認できます。")
        XCTAssertEqual(draft.summary.detailText, "1件を提示 / 1件を受け取り候補・終演後OK / 短時間OK")
    }

    func testProposalMessageDraftLimiterKeepsLimitAndCharacterBoundaries() {
        XCTAssertEqual(ProposalMessageDraftLimiter.limited("abc", limit: 3), "abc")
        XCTAssertEqual(ProposalMessageDraftLimiter.limited("abcd", limit: 3), "abc")
        XCTAssertEqual(ProposalMessageDraftLimiter.limited("abc", limit: 0), "")

        let emojiMessage = String(repeating: "🎫", count: 3) + "a"
        XCTAssertEqual(
            ProposalMessageDraftLimiter.limited(emojiMessage, limit: 3),
            String(repeating: "🎫", count: 3)
        )
    }

    func testProposalStepSwipeNavigatorMovesBetweenVisibleSteps() {
        XCTAssertEqual(
            ProposalStepSwipeNavigator.destination(
                from: .give,
                translationWidth: -84,
                translationHeight: 12,
                visibleSteps: [.give, .receive, .meetup, .confirm]
            ),
            .receive
        )
        XCTAssertEqual(
            ProposalStepSwipeNavigator.destination(
                from: .receive,
                translationWidth: -90,
                translationHeight: 8,
                visibleSteps: [.give, .receive, .meetup, .shipping, .confirm]
            ),
            .meetup
        )
        XCTAssertEqual(
            ProposalStepSwipeNavigator.destination(
                from: .meetup,
                translationWidth: -90,
                translationHeight: 8,
                visibleSteps: [.give, .receive, .meetup, .shipping, .confirm]
            ),
            .shipping
        )
        XCTAssertEqual(
            ProposalStepSwipeNavigator.destination(
                from: .receive,
                translationWidth: 90,
                translationHeight: 8,
                visibleSteps: [.give, .receive, .confirm]
            ),
            .give
        )
        XCTAssertNil(
            ProposalStepSwipeNavigator.destination(
                from: .give,
                translationWidth: -24,
                translationHeight: 4,
                visibleSteps: [.give, .receive, .confirm]
            )
        )
    }

    func testProposalBottomBarCopyMatchesRnProgressLabels() {
        let readyHand = ProposalCreateConfiguration(
            exchangeMethod: .hand,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: true,
            receiverGoodsCount: 1,
            isListingSource: false
        )
        let readyMail = ProposalCreateConfiguration(
            exchangeMethod: .mail,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            receiverGoodsCount: 1,
            isListingSource: false
        )
        let blockedMeetup = ProposalCreateConfiguration(
            exchangeMethod: .hand,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            receiverGoodsCount: 1,
            isListingSource: false
        )

        XCTAssertEqual(
            ProposalCreateBottomBarCopy.primaryTitle(
                selectedStep: .give,
                configuration: readyHand,
                meetupHasTimeDraft: false
            ),
            "この内容で次へ"
        )
        XCTAssertEqual(
            ProposalCreateBottomBarCopy.primaryTitle(
                selectedStep: .give,
                configuration: ProposalCreateConfiguration(
                    exchangeMethod: .hand,
                    hasSelectedSenderGoods: true,
                    isCreatingProposal: false,
                    hasReadyMailingAddress: true,
                    isLoadingMailingAddress: false,
                    hasValidMeetup: true,
                    receiverGoodsCount: 0,
                    isListingSource: false
                ),
                meetupHasTimeDraft: false
            ),
            "この内容で次へ"
        )
        XCTAssertEqual(
            ProposalCreateBottomBarCopy.primaryTitle(
                selectedStep: .receive,
                configuration: readyHand,
                meetupHasTimeDraft: false
            ),
            "交換条件へ進む"
        )
        XCTAssertEqual(
            ProposalCreateBottomBarCopy.primaryTitle(
                selectedStep: .receive,
                configuration: readyMail,
                meetupHasTimeDraft: false
            ),
            "交換条件へ進む"
        )
        let paymentReady = ProposalCreateConfiguration(
            exchangeMethod: .mail,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            requiresPaymentSelection: true,
            hasSelectedPaymentMethod: true,
            receiverGoodsCount: 1,
            isListingSource: false
        )
        XCTAssertEqual(
            ProposalCreateBottomBarCopy.primaryTitle(
                selectedStep: .shipping,
                configuration: paymentReady,
                meetupHasTimeDraft: false
            ),
            "支払方法へ進む"
        )
        XCTAssertEqual(
            ProposalCreateBottomBarCopy.primaryTitle(
                selectedStep: .payment,
                configuration: paymentReady,
                meetupHasTimeDraft: false
            ),
            "この方法にする"
        )
        XCTAssertEqual(
            ProposalCreateBottomBarCopy.primaryTitle(
                selectedStep: .meetup,
                configuration: readyHand,
                meetupHasTimeDraft: true
            ),
            "次へ：送信確認"
        )
        XCTAssertEqual(
            ProposalCreateBottomBarCopy.primaryTitle(
                selectedStep: .meetup,
                configuration: blockedMeetup,
                meetupHasTimeDraft: true
            ),
            "待ち合わせ入力が必要"
        )
        XCTAssertEqual(
            ProposalCreateBottomBarCopy.primaryTitle(
                selectedStep: .meetup,
                configuration: blockedMeetup,
                meetupHasTimeDraft: false
            ),
            "待ち合わせ入力が必要"
        )
    }

    func testProposalPrimaryStepDestinationMatchesBottomBarCopy() {
        let readyHand = ProposalCreateConfiguration(
            exchangeMethod: .hand,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: true,
            receiverGoodsCount: 1,
            isListingSource: false
        )
        let readyMail = ProposalCreateConfiguration(
            exchangeMethod: .mail,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            receiverGoodsCount: 1,
            isListingSource: false
        )
        let noReceiverYet = ProposalCreateConfiguration(
            exchangeMethod: .hand,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: true,
            receiverGoodsCount: 0,
            isListingSource: false
        )
        let paymentReady = ProposalCreateConfiguration(
            exchangeMethod: .mail,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            requiresPaymentSelection: true,
            hasSelectedPaymentMethod: true,
            receiverGoodsCount: 1,
            isListingSource: false
        )

        XCTAssertEqual(
            ProposalCreatePrimaryStepDestination.destination(
                from: .give,
                configuration: readyHand,
                visibleSteps: [.give, .receive, .conditions, .confirm]
            ),
            .receive
        )
        XCTAssertEqual(
            ProposalCreatePrimaryStepDestination.destination(
                from: .give,
                configuration: readyMail,
                visibleSteps: [.give, .receive, .conditions, .confirm]
            ),
            .receive
        )
        XCTAssertEqual(
            ProposalCreatePrimaryStepDestination.destination(
                from: .give,
                configuration: noReceiverYet,
                visibleSteps: [.give, .receive, .conditions, .confirm]
            ),
            .receive
        )
        XCTAssertEqual(
            ProposalCreatePrimaryStepDestination.destination(
                from: .receive,
                configuration: readyHand,
                visibleSteps: [.give, .receive, .conditions, .confirm]
            ),
            .conditions
        )
        XCTAssertEqual(
            ProposalCreatePrimaryStepDestination.destination(
                from: .receive,
                configuration: readyMail,
                visibleSteps: [.give, .receive, .conditions, .confirm]
            ),
            .conditions
        )
        XCTAssertEqual(
            ProposalCreatePrimaryStepDestination.destination(
                from: .conditions,
                configuration: readyHand,
                visibleSteps: [.give, .receive, .conditions, .confirm]
            ),
            .confirm
        )
        XCTAssertEqual(
            ProposalCreatePrimaryStepDestination.destination(
                from: .conditions,
                configuration: readyMail,
                visibleSteps: [.give, .receive, .conditions, .confirm]
            ),
            .confirm
        )
        XCTAssertEqual(
            ProposalCreatePrimaryStepDestination.destination(
                from: .conditions,
                configuration: paymentReady,
                visibleSteps: [.give, .receive, .conditions, .confirm]
            ),
            .confirm
        )
        XCTAssertEqual(
            ProposalCreatePrimaryStepDestination.destination(
                from: .conditions,
                configuration: paymentReady,
                visibleSteps: [.give, .receive, .conditions, .confirm]
            ),
            .confirm
        )
    }

    func testProposalInitialStepResolverWaitsUntilPriorStepsCanAdvance() {
        let readyHand = ProposalCreateConfiguration(
            exchangeMethod: .hand,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            receiverGoodsCount: 1,
            isListingSource: false
        )
        let missingReceiver = ProposalCreateConfiguration(
            exchangeMethod: .hand,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            receiverGoodsCount: 0,
            isListingSource: false
        )
        let mailOnly = ProposalCreateConfiguration(
            exchangeMethod: .mail,
            hasSelectedSenderGoods: true,
            isCreatingProposal: false,
            hasReadyMailingAddress: true,
            isLoadingMailingAddress: false,
            hasValidMeetup: false,
            receiverGoodsCount: 1,
            isListingSource: false
        )

        XCTAssertEqual(
            ProposalInitialStepResolver.resolution(
                initialStep: .meetup,
                visibleSteps: [.give, .receive, .conditions, .confirm],
                configuration: readyHand
            ),
            .apply(.conditions)
        )
        XCTAssertEqual(
            ProposalInitialStepResolver.resolution(
                initialStep: .meetup,
                visibleSteps: [.give, .receive, .conditions, .confirm],
                configuration: missingReceiver
            ),
            .wait
        )
        XCTAssertEqual(
            ProposalInitialStepResolver.resolution(
                initialStep: .meetup,
                visibleSteps: [.give, .receive, .conditions, .confirm],
                configuration: mailOnly
            ),
            .apply(.conditions)
        )
    }

    func testProposalFlowScreenCopyMatchesRnHeaders() {
        XCTAssertEqual(ProposalFlowScreenCopy.title(for: .give), "提示物の選択")
        XCTAssertEqual(ProposalFlowScreenCopy.title(for: .receive), "提示物の選択")
        XCTAssertEqual(ProposalFlowScreenCopy.title(for: .payment), "支払方法")
        XCTAssertEqual(ProposalFlowScreenCopy.title(for: .confirm), "送信確認")
        XCTAssertFalse(ProposalFlowScreenCopy.showsHeaderKicker(for: .give))
        XCTAssertFalse(ProposalFlowScreenCopy.showsHeaderKicker(for: .confirm))
        XCTAssertEqual(ProposalConfirmSectionCopy.meetupCandidatesTitle, "交換できる候補")
    }

    func testProposalHeaderUsesRnLikeMetrics() {
        XCTAssertEqual(ProposalFlowHeaderMetrics.backButtonSize, 42)
        XCTAssertEqual(ProposalFlowHeaderMetrics.backChevronSize, 18)
        XCTAssertEqual(ProposalFlowHeaderMetrics.horizontalSpacing, 12)
        XCTAssertEqual(ProposalFlowHeaderMetrics.kickerFontSize, 10)
        XCTAssertEqual(ProposalFlowHeaderMetrics.kickerTracking, 0.7)
        XCTAssertEqual(ProposalFlowHeaderMetrics.titleFontSize, 23)
    }

    func testProposalConfirmContentUsesRnLikeScreenPaddingAndSpacing() {
        XCTAssertEqual(ProposalFlowContentMetrics.defaultHorizontalPadding, 18)
        XCTAssertEqual(ProposalFlowContentMetrics.confirmHorizontalPadding, 18)
        XCTAssertEqual(ProposalFlowContentMetrics.defaultContentSpacing, 12)
        XCTAssertEqual(ProposalFlowContentMetrics.confirmContentSpacing, 13)
    }

    func testProposalSectionTabsUseRnLikeSegmentMetrics() {
        XCTAssertEqual(ProposalSectionTabsMetrics.containerPadding, 3)
        XCTAssertEqual(ProposalSectionTabsMetrics.tabGap, 4)
        XCTAssertEqual(ProposalSectionTabsMetrics.tabHorizontalPadding, 5)
        XCTAssertEqual(ProposalSectionTabsMetrics.tabVerticalPadding, 5)
        XCTAssertEqual(ProposalSectionTabsMetrics.minTabHeight, 30)
        XCTAssertEqual(ProposalSectionTabsMetrics.labelFontSize, 11.5)
        XCTAssertEqual(ProposalSectionTabsMetrics.countFontSize, 10)
    }

    func testProposalGoodsFiltersUseRnLikeInlineRowMetrics() {
        XCTAssertEqual(ProposalGoodsFilterMetrics.rowSpacing, 6)
        XCTAssertEqual(ProposalGoodsFilterMetrics.labelWidth, 30)
        XCTAssertEqual(ProposalGoodsFilterMetrics.labelFontSize, 9.5)
        XCTAssertEqual(ProposalGoodsFilterMetrics.labelTracking, 0.4)
        XCTAssertEqual(ProposalGoodsFilterMetrics.chipSpacing, 6)
        XCTAssertEqual(ProposalGoodsFilterMetrics.chipHorizontalPadding, 10)
        XCTAssertEqual(ProposalGoodsFilterMetrics.chipVerticalPadding, 5)
        XCTAssertEqual(ProposalGoodsFilterMetrics.chipFontSize, 11)
    }

    func testProposalConfirmSectionsStayInRnInformationOrder() {
        XCTAssertEqual(
            ProposalConfirmSectionKind.visibleOrder(requiresMeetupBeforeSubmit: true),
            [
                .exchangeContent,
                .method,
                .meetupCandidates,
                .message
            ]
        )
        XCTAssertEqual(
            ProposalConfirmSectionKind.visibleOrder(
                requiresMeetupBeforeSubmit: false,
                requiresShippingBeforeSubmit: true,
                requiresPaymentSelection: true
            ),
            [
                .exchangeContent,
                .method,
                .shipping,
                .payment,
                .message
            ]
        )
    }

    func testProposalConfirmUsesFixedFooterSubmitButtonPlacement() {
        XCTAssertFalse(ProposalFlowBottomBarPlacement.usesInlineScrollButton(for: .give))
        XCTAssertFalse(ProposalFlowBottomBarPlacement.usesInlineScrollButton(for: .receive))
        XCTAssertFalse(ProposalFlowBottomBarPlacement.usesInlineScrollButton(for: .meetup))
        XCTAssertFalse(ProposalFlowBottomBarPlacement.usesInlineScrollButton(for: .shipping))
        XCTAssertFalse(ProposalFlowBottomBarPlacement.usesInlineScrollButton(for: .confirm))
    }

    func testProposalBottomBarUsesRnLikeFixedFooterMetrics() {
        XCTAssertEqual(ProposalFlowBottomBarMetrics.horizontalPadding, 18)
        XCTAssertEqual(ProposalFlowBottomBarMetrics.topPadding, 10)
        XCTAssertEqual(ProposalFlowBottomBarMetrics.bottomPadding, 6)
        XCTAssertEqual(ProposalFlowBottomBarMetrics.inlineTopPadding, 4)
        XCTAssertEqual(ProposalFlowBottomBarMetrics.inlineBottomPadding, 4)
        XCTAssertEqual(ProposalFlowBottomBarMetrics.buttonMinHeight, 56)
        XCTAssertEqual(ProposalFlowBottomBarMetrics.buttonCornerRadius, 18)
    }

    func testProposalPreviewGlyphResolverUsesRnLikeMemberGlyphs() {
        XCTAssertEqual(ProposalPreviewGlyphResolver.glyph(for: "スア ラキドロ"), "S")
        XCTAssertEqual(ProposalPreviewGlyphResolver.glyph(for: "  カリナ 春ver. "), "K")
        XCTAssertEqual(ProposalPreviewGlyphResolver.glyph(for: "ジョンウ ラキドロ"), "J")
        XCTAssertEqual(ProposalPreviewGlyphResolver.glyph(for: "ニンニン 制服"), "N")
        XCTAssertEqual(ProposalPreviewGlyphResolver.glyph(for: "\n\t"), "?")
    }

    func testProposalExchangePreviewThumbGridUsesRnLikeSpacing() {
        XCTAssertEqual(ProposalExchangePreviewMetrics.thumbSize, 44)
        XCTAssertEqual(ProposalExchangePreviewMetrics.thumbSpacing, 6)
        XCTAssertEqual(ProposalExchangePreviewMetrics.thumbGridColumns.count, 1)
    }

    func testProposalCandidateListUsesRnLikePaneAndRowSpacing() {
        XCTAssertEqual(ProposalCandidateListMetrics.paneSpacing, 10)
        XCTAssertEqual(ProposalCandidateListMetrics.spacing, 10)
    }

    func testProposalSelectableGoodsRowUsesRnLikeChoiceCardMetrics() {
        XCTAssertEqual(ProposalSelectableGoodsRowMetrics.rowSpacing, 12)
        XCTAssertEqual(ProposalSelectableGoodsRowMetrics.rowPadding, 10)
        XCTAssertEqual(ProposalSelectableGoodsRowMetrics.rowCornerRadius, 18)
        XCTAssertEqual(ProposalSelectableGoodsRowMetrics.selectedBackgroundOpacity, 0.08)
        XCTAssertEqual(ProposalSelectableGoodsRowMetrics.selectedBorderOpacity, 0.48)
        XCTAssertEqual(ProposalSelectableGoodsRowMetrics.defaultBorderOpacity, 0.08)
        XCTAssertEqual(ProposalSelectableGoodsRowMetrics.thumbnailWidth, 66)
        XCTAssertEqual(ProposalSelectableGoodsRowMetrics.thumbnailHeight, 82)
        XCTAssertEqual(ProposalSelectableGoodsRowMetrics.thumbnailCornerRadius, 15)
        XCTAssertEqual(ProposalSelectableGoodsRowMetrics.thumbnailShineSize, 56)
        XCTAssertEqual(ProposalSelectableGoodsRowMetrics.thumbnailShineOffsetX, 16)
        XCTAssertEqual(ProposalSelectableGoodsRowMetrics.thumbnailShineOffsetY, -18)
        XCTAssertEqual(ProposalSelectableGoodsRowMetrics.glyphFontSize, 27)
        XCTAssertEqual(ProposalSelectableGoodsRowMetrics.checkCircleSize, 26)
    }

    func testProposalSelectableGoodsRowStyleUsesRnLikeGlyphs() {
        let item = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000511")!,
            ownerID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            title: "ジョンウ ラキドロ"
        )

        XCTAssertEqual(ProposalSelectableGoodsRowStyle.glyph(for: item), "J")
    }

    func testProposalGoodsFilterCatalogUsesOnlyVisibleCandidateValues() {
        let firstGroupID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let unusedGroupID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let firstTypeID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let secondTypeID = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!
        let unusedTypeID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let item = GoodsItem(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
            ownerID: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
            groupID: firstGroupID,
            goodsTypeID: firstTypeID,
            title: "カリナ 春ver."
        )
        let secondItem = GoodsItem(
            id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
            ownerID: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
            groupID: firstGroupID,
            goodsTypeID: secondTypeID,
            title: "ニンニン 制服"
        )
        let groups = [
            OshiGroup(id: unusedGroupID, name: "NCT", displayOrder: 1),
            OshiGroup(id: firstGroupID, name: "aespa", displayOrder: 2)
        ]
        let goodsTypes = [
            GoodsType(id: firstTypeID, name: "トレカ", displayOrder: 1),
            GoodsType(id: secondTypeID, name: "アクスタ", displayOrder: 2),
            GoodsType(id: unusedTypeID, name: "アクスタ", displayOrder: 2)
        ]

        XCTAssertEqual(
            ProposalGoodsFilterCatalog.groupChoices(items: [item], groups: groups),
            [ProposalFilterChoice(id: firstGroupID, title: "aespa")]
        )
        XCTAssertEqual(
            ProposalGoodsFilterCatalog.goodsTypeChoices(items: [item], goodsTypes: goodsTypes),
            [ProposalFilterChoice(id: firstTypeID, title: "トレカ")]
        )
        XCTAssertEqual(
            ProposalGoodsFilterCatalog.goodsTypeChoices(items: [item, secondItem], goodsTypes: goodsTypes),
            [
                ProposalFilterChoice(id: secondTypeID, title: "アクスタ"),
                ProposalFilterChoice(id: firstTypeID, title: "トレカ")
            ]
        )
    }
}
