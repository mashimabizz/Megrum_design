@testable import MegrumApp
import Foundation
import MapKit
import MegrumCore
import XCTest

final class ProposalCreateFlowTests: XCTestCase {
    func testProposalCreateStepsStayInVisibleParityOrder() {
        XCTAssertEqual(
            ProposalCreateStep.allCases.map(\.title),
            ["出すもの", "受け取る", "待ち合わせ", "確認"]
        )
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
        XCTAssertEqual(draft.summary.completionMessage, "@michilion に打診を送りました。返事が届いたら通知と打診一覧で確認できます。")
        XCTAssertEqual(draft.summary.detailText, "1件を提示 / 1件を受け取り候補・終演後OK / 短時間OK")
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
                visibleSteps: [.give, .receive, .meetup, .confirm]
            ),
            .meetup
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
            "待ち合わせへ進む"
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
            "受け取るものへ進む"
        )
        XCTAssertEqual(
            ProposalCreateBottomBarCopy.primaryTitle(
                selectedStep: .receive,
                configuration: readyHand,
                meetupHasTimeDraft: false
            ),
            "待ち合わせへ進む"
        )
        XCTAssertEqual(
            ProposalCreateBottomBarCopy.primaryTitle(
                selectedStep: .receive,
                configuration: readyMail,
                meetupHasTimeDraft: false
            ),
            "次へ：送信確認"
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
            "場所未設定の候補があります"
        )
        XCTAssertEqual(
            ProposalCreateBottomBarCopy.primaryTitle(
                selectedStep: .meetup,
                configuration: blockedMeetup,
                meetupHasTimeDraft: false
            ),
            "交換できる時間を設定してください"
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

        XCTAssertEqual(
            ProposalCreatePrimaryStepDestination.destination(
                from: .give,
                configuration: readyHand,
                visibleSteps: [.give, .receive, .meetup, .confirm]
            ),
            .meetup
        )
        XCTAssertEqual(
            ProposalCreatePrimaryStepDestination.destination(
                from: .give,
                configuration: readyMail,
                visibleSteps: [.give, .receive, .confirm]
            ),
            .confirm
        )
        XCTAssertEqual(
            ProposalCreatePrimaryStepDestination.destination(
                from: .give,
                configuration: noReceiverYet,
                visibleSteps: [.give, .receive, .meetup, .confirm]
            ),
            .receive
        )
        XCTAssertEqual(
            ProposalCreatePrimaryStepDestination.destination(
                from: .receive,
                configuration: readyHand,
                visibleSteps: [.give, .receive, .meetup, .confirm]
            ),
            .meetup
        )
        XCTAssertEqual(
            ProposalCreatePrimaryStepDestination.destination(
                from: .meetup,
                configuration: readyHand,
                visibleSteps: [.give, .receive, .meetup, .confirm]
            ),
            .confirm
        )
    }

    func testProposalFlowScreenCopyMatchesRnHeaders() {
        XCTAssertEqual(ProposalFlowScreenCopy.title(for: .give), "提示物の選択")
        XCTAssertEqual(ProposalFlowScreenCopy.title(for: .receive), "提示物の選択")
        XCTAssertEqual(ProposalFlowScreenCopy.title(for: .confirm), "送信確認")
        XCTAssertTrue(ProposalFlowScreenCopy.showsHeaderKicker(for: .give))
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
        XCTAssertEqual(ProposalSectionTabsMetrics.containerPadding, 4)
        XCTAssertEqual(ProposalSectionTabsMetrics.tabGap, 4)
        XCTAssertEqual(ProposalSectionTabsMetrics.tabHorizontalPadding, 5)
        XCTAssertEqual(ProposalSectionTabsMetrics.tabVerticalPadding, 8)
        XCTAssertEqual(ProposalSectionTabsMetrics.minTabHeight, 36)
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
                .message,
                .scheduleShare
            ]
        )
        XCTAssertEqual(
            ProposalConfirmSectionKind.visibleOrder(requiresMeetupBeforeSubmit: false),
            [
                .exchangeContent,
                .method,
                .message
            ]
        )
    }

    func testProposalConfirmUsesRnLikeInlineSubmitButtonPlacement() {
        XCTAssertFalse(ProposalFlowBottomBarPlacement.usesInlineScrollButton(for: .give))
        XCTAssertFalse(ProposalFlowBottomBarPlacement.usesInlineScrollButton(for: .receive))
        XCTAssertFalse(ProposalFlowBottomBarPlacement.usesInlineScrollButton(for: .meetup))
        XCTAssertTrue(ProposalFlowBottomBarPlacement.usesInlineScrollButton(for: .confirm))
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

    func testProposalScheduleShareCardUsesRnLikeMetrics() {
        XCTAssertEqual(ProposalScheduleShareMetrics.cardGap, 12)
        XCTAssertEqual(ProposalScheduleShareMetrics.cardPadding, 13)
        XCTAssertEqual(ProposalScheduleShareMetrics.cardCornerRadius, 16)
        XCTAssertEqual(ProposalScheduleShareMetrics.titleFontSize, 13)
        XCTAssertEqual(ProposalScheduleShareMetrics.statusFontSize, 11)
        XCTAssertEqual(ProposalScheduleShareMetrics.statusTopSpacing, 2)
        XCTAssertEqual(ProposalScheduleShareMetrics.activeBackgroundOpacity, 0.08)
        XCTAssertEqual(ProposalScheduleShareMetrics.activeBorderOpacity, 0.48)
        XCTAssertEqual(ProposalScheduleShareMetrics.inactiveBorderOpacity, 0.08)
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
