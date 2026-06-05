@testable import MegrumApp
import MegrumCore
import XCTest

final class TradeChatAffordanceTests: XCTestCase {
    func testTradeStagesExposePendingInProgressAndCompletedBuckets() {
        XCTAssertEqual(TradeStage.allCases, [.pending, .inProgress, .completed])
        XCTAssertTrue(TradeStage.pending.contains(.sent))
        XCTAssertTrue(TradeStage.pending.contains(.negotiating))
        XCTAssertTrue(TradeStage.inProgress.contains(.agreed))
        XCTAssertFalse(TradeStage.inProgress.contains(.completed))
        XCTAssertTrue(TradeStage.completed.contains(.completed))
        XCTAssertTrue(TradeStage.completed.contains(.cancelled))
        XCTAssertTrue(TradeStage.completed.contains(.rejected))
        XCTAssertTrue(TradeStage.completed.contains(.expired))
        XCTAssertFalse(TradeStage.completed.contains(.agreed))
    }

    func testTradeStagesSupportSwipeProgressionAndEmptyCopy() {
        XCTAssertEqual(TradeStage.pending.next, .inProgress)
        XCTAssertEqual(TradeStage.inProgress.next, .completed)
        XCTAssertEqual(TradeStage.completed.next, .completed)
        XCTAssertEqual(TradeStage.completed.previous, .inProgress)
        XCTAssertFalse(TradeStage.completed.emptyTitle.isEmpty)
        XCTAssertTrue(TradeStage.completed.emptyMessage.contains("証跡"))
        XCTAssertTrue(TradeStage.completed.emptyMessage.contains("終了"))
    }

    func testTradeStageRouteRequestPrefersExplicitPendingDestination() {
        XCTAssertEqual(
            TradeStageRouteRequestResolver.resolve(current: .completed, requested: .pending),
            .pending
        )
        XCTAssertEqual(
            TradeStageRouteRequestResolver.resolve(current: .inProgress, requested: nil),
            .inProgress
        )
    }

    func testNativePreviewPendingListMirrorsRnVisualQaCount() {
        let pending = NativePreviewData.proposals.filter { TradeStage.pending.contains($0.status) }
        XCTAssertEqual(pending.count, 4)
        XCTAssertTrue(pending.contains { $0.status == .negotiating })
        XCTAssertTrue(pending.contains { $0.status == .agreementOneSide })
        XCTAssertEqual(pending.filter { $0.status == .sent }.count, 2)
    }

    func testTradeCardPresentationMatchesRnPendingStatusCopy() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let proposal = TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000301")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .sent,
            exchangeMethod: .both,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            createdAt: Date(timeIntervalSince1970: 1_000)
        )
        let partner = PublicUserProfile(
            profile: UserProfile(id: partnerID, handle: "michilion", displayName: "みち"),
            averageStars: nil,
            evaluationCount: 0,
            completedTradeCount: 0
        )

        let presentation = TradeCardPresentation(
            proposal: proposal,
            viewerID: viewerID,
            profilesByUserID: [partnerID: partner],
            now: Date(timeIntervalSince1970: 1_180)
        )

        XCTAssertEqual(presentation.partnerHandle, "michilion")
        XCTAssertEqual(presentation.directionText, "届いた")
        XCTAssertEqual(presentation.updatedText, "3分前")
        XCTAssertEqual(presentation.statusText, "新着打診")
        XCTAssertEqual(presentation.responseText, "要対応")
        XCTAssertEqual(presentation.tone, .action)
    }

    func testTradePreviewThumbnailStyleUsesRnLikeGlyphs() {
        let item = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000401")!,
            ownerID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            title: "ニンニン 制服"
        )

        XCTAssertEqual(TradePreviewThumbnailStyle.glyph(for: item), "N")
    }

    func testProposalCompletionRoutesMatchRnCompletionButtons() {
        XCTAssertEqual(
            ProposalCompletionRouteResolver.resolve(action: .searchMore),
            ProposalCompletionRouteState(selectedTab: .home, requestedTradesStage: nil)
        )
        XCTAssertEqual(
            ProposalCompletionRouteResolver.resolve(action: .openTrades),
            ProposalCompletionRouteState(selectedTab: .trades, requestedTradesStage: .pending)
        )
    }

    func testTradeChatInputAvailabilityAllowsOnlyActiveNegotiationAndDealStates() {
        XCTAssertFalse(TradeChatInputAvailability(status: .draft).canSendMessages)
        XCTAssertTrue(TradeChatInputAvailability(status: .sent).canSendMessages)
        XCTAssertTrue(TradeChatInputAvailability(status: .negotiating).canSendMessages)
        XCTAssertTrue(TradeChatInputAvailability(status: .agreementOneSide).canSendMessages)
        XCTAssertTrue(TradeChatInputAvailability(status: .agreed).canSendMessages)
        XCTAssertFalse(TradeChatInputAvailability(status: .completed).canSendMessages)
        XCTAssertFalse(TradeChatInputAvailability(status: .cancelled).canSendMessages)
        XCTAssertFalse(TradeChatInputAvailability(status: .rejected).canSendMessages)
        XCTAssertFalse(TradeChatInputAvailability(status: .expired).canSendMessages)
    }

    func testArrivalQuickActionsMapToSendableMessageBodies() {
        XCTAssertEqual(TradeArrivalQuickAction.enroute.messageBody, "向かっています")
        XCTAssertEqual(TradeArrivalQuickAction.arrived.messageBody, "到着しました")
        XCTAssertEqual(TradeArrivalQuickAction.left.messageBody, "離れました")
    }

    func testArrivalQuickActionsHaveAccessibleLabelsAndSymbols() {
        for action in TradeArrivalQuickAction.allCases {
            XCTAssertFalse(action.title.isEmpty)
            XCTAssertFalse(action.messageBody.isEmpty)
            XCTAssertFalse(action.systemImage.isEmpty)
        }
    }

    func testAssistanceRequestKindsHaveChatMenuLabels() {
        for kind in TradeAssistanceRequestKind.allCases {
            XCTAssertFalse(kind.title.isEmpty)
            XCTAssertFalse(kind.systemImage.isEmpty)
            XCTAssertFalse(kind.placeholder.isEmpty)
            XCTAssertFalse(kind.reasonPlaceholder.isEmpty)
            XCTAssertFalse(kind.notePlaceholder.isEmpty)
            XCTAssertFalse(kind.acknowledgementText.isEmpty)
            XCTAssertFalse(kind.menuAccessibilityLabel.isEmpty)
            XCTAssertFalse(kind.reasonAccessibilityLabel.isEmpty)
            XCTAssertFalse(kind.noteAccessibilityLabel.isEmpty)
            XCTAssertFalse(kind.acknowledgementAccessibilityLabel.isEmpty)
        }
    }

    func testLateDelayBucketsExposeTypedMinutesAndAccessibleLabels() {
        XCTAssertEqual(TradeLateDelayBucket.twenty.rawValue, 20)
        XCTAssertEqual(TradeLateDelayBucket.sixty.title, "1時間")
        XCTAssertEqual(TradeLateDelayBucket.ninety.accessibilityLabel, "遅れる見込み 1時間以上")
    }

    func testArrivalQuickActionBuildsTypedSendIntent() {
        let intent = TradeArrivalStatusSendIntent(action: .arrived)

        XCTAssertEqual(intent.messageType, .arrivalStatus)
        XCTAssertEqual(intent.status, .arrived)
        XCTAssertEqual(intent.body, "到着しました")
        XCTAssertEqual(intent.metadata, ["status": "arrived"])
    }

    func testLocationShareIntentValidatesCoordinateAndLabel() {
        let intent = TradeLocationShareIntent(
            coordinate: MegrumLocationCoordinate(latitude: 35.443707, longitude: 139.638031),
            label: " 現在地 "
        )

        XCTAssertEqual(intent.messageType, .location)
        XCTAssertEqual(intent.normalizedLabel, "現在地")
        XCTAssertTrue(intent.isSubmittable)

        let invalid = TradeLocationShareIntent(
            coordinate: MegrumLocationCoordinate(latitude: 91, longitude: 139.638031),
            label: "現在地"
        )
        XCTAssertFalse(invalid.isSubmittable)
    }

    func testOutfitPhotoIntentUsesTypedMessageDefaults() {
        let intent = TradeOutfitPhotoSendIntent(imageContentType: "image/jpeg")

        XCTAssertEqual(intent.messageType, .outfitPhoto)
        XCTAssertEqual(intent.imageContentType, "image/jpeg")
        XCTAssertEqual(intent.body, "服装写真を共有しました")
    }

    func testEvaluationPromptStateDetectsViewerEvaluationSubmission() {
        let viewerID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let partnerID = UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!
        let proposalID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let proposal = makeProposal(id: proposalID, senderID: viewerID, receiverID: partnerID, status: .completed)
        let message = TradeMessage(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaea01")!,
            proposalID: proposalID,
            senderID: viewerID,
            messageType: .system,
            body: "取引評価を送信しました"
        )

        let state = TradeEvaluationPromptState(
            proposal: proposal,
            viewerID: viewerID,
            messages: [message]
        )

        XCTAssertTrue(state.hasSubmittedEvaluation)
    }

    func testEvaluationPromptStateIgnoresPartnerEvaluationAndHonorsLocalSubmission() {
        let viewerID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let partnerID = UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!
        let proposalID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let proposal = makeProposal(id: proposalID, senderID: viewerID, receiverID: partnerID, status: .completed)
        let partnerMessage = TradeMessage(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaea02")!,
            proposalID: proposalID,
            senderID: partnerID,
            messageType: .system,
            body: "取引評価を送信しました"
        )

        XCTAssertFalse(
            TradeEvaluationPromptState(
                proposal: proposal,
                viewerID: viewerID,
                messages: [partnerMessage]
            ).hasSubmittedEvaluation
        )
        XCTAssertTrue(
            TradeEvaluationPromptState(
                proposal: proposal,
                viewerID: viewerID,
                messages: [],
                localSubmission: true
            ).hasSubmittedEvaluation
        )
    }

    func testAssistanceRequestLegacySystemMessageUsesTypedBodyWhenPossible() {
        XCTAssertEqual(
            TradeAssistanceRequestKind.late.systemMessageBody(from: "電車遅延"),
            "10分遅れる旨が通知されました\n理由：電車遅延"
        )
        XCTAssertEqual(TradeAssistanceRequestKind.cancel.systemMessageBody(from: "   "), "キャンセル申請")
    }

    func testOperationalSystemMessagePresentationUsesMetadataAction() {
        let message = TradeMessage(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            proposalID: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            senderID: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
            messageType: .system,
            body: "20分遅れる旨が通知されました\n理由：電車遅延",
            meta: ["action": "late_notice"]
        )

        let presentation = TradeSystemMessagePresentation(message: message)

        XCTAssertEqual(presentation.title, "遅刻連絡")
        XCTAssertEqual(presentation.systemImage, "clock.badge.exclamationmark")
        XCTAssertTrue(presentation.accessibilityLabel.contains("遅刻連絡"))
    }

    func testOperationalSystemMessagePresentationPrefersMetaDetails() {
        let message = TradeMessage(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaab")!,
            proposalID: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            senderID: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
            messageType: .system,
            body: "20分遅れる旨が通知されました\n理由：電車遅延",
            meta: [
                "action": "late_notice",
                "late_minutes": "20",
                "reason": "電車遅延",
                "note": "東口から向かいます"
            ]
        )

        let presentation = TradeSystemMessagePresentation(message: message)

        XCTAssertEqual(presentation.body, "理由：電車遅延\n補足：東口から向かいます")
        XCTAssertEqual(presentation.detail, "見込み：20分")
        XCTAssertTrue(presentation.accessibilityLabel.contains("見込み：20分"))
    }

    func testCancelApprovalPromptShowsOnlyForIncomingRequestOnAgreedTrade() {
        let viewerID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let partnerID = UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!
        let proposalID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let request = TradeMessage(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaac01")!,
            proposalID: proposalID,
            senderID: partnerID,
            messageType: .system,
            body: "キャンセル申請",
            meta: [
                "action": "cancel_requested",
                "requested_by": partnerID.uuidString.lowercased()
            ]
        )

        let prompt = TradeCancelApprovalPrompt(
            message: request,
            proposal: makeProposal(id: proposalID, senderID: viewerID, receiverID: partnerID, status: .agreed),
            viewerID: viewerID,
            messages: [request]
        )

        XCTAssertTrue(prompt.canApprove)
    }

    func testCancelApprovalPromptHidesForOwnRequestOrAlreadyApproved() {
        let viewerID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let partnerID = UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!
        let proposalID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let proposal = makeProposal(id: proposalID, senderID: viewerID, receiverID: partnerID, status: .agreed)
        let ownRequest = TradeMessage(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaac02")!,
            proposalID: proposalID,
            senderID: viewerID,
            messageType: .system,
            body: "キャンセル申請",
            meta: [
                "action": "cancel_requested",
                "requested_by": viewerID.uuidString.lowercased()
            ]
        )
        let partnerRequest = TradeMessage(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaac03")!,
            proposalID: proposalID,
            senderID: partnerID,
            messageType: .system,
            body: "キャンセル申請",
            meta: [
                "action": "cancel_requested",
                "requested_by": partnerID.uuidString.lowercased()
            ]
        )
        let approved = TradeMessage(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaac04")!,
            proposalID: proposalID,
            senderID: viewerID,
            messageType: .system,
            body: "キャンセル申請に同意しました",
            meta: ["action": "cancel_approved"]
        )

        XCTAssertFalse(
            TradeCancelApprovalPrompt(
                message: ownRequest,
                proposal: proposal,
                viewerID: viewerID,
                messages: [ownRequest]
            ).canApprove
        )
        XCTAssertFalse(
            TradeCancelApprovalPrompt(
                message: partnerRequest,
                proposal: proposal,
                viewerID: viewerID,
                messages: [partnerRequest, approved]
            ).canApprove
        )
    }

    func testOperationalMessagePresentationFormatsArrivalStatus() {
        let message = TradeMessage(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaac1")!,
            proposalID: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            senderID: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
            messageType: .arrivalStatus,
            body: "到着しました",
            meta: ["status": "arrived"]
        )

        let presentation = TradeOperationalMessagePresentation(message: message)

        XCTAssertEqual(presentation.title, "到着ステータス")
        XCTAssertEqual(presentation.systemImage, "checkmark.circle.fill")
        XCTAssertEqual(presentation.body, "到着しました")
        XCTAssertEqual(presentation.detail, "到着済み")
    }

    func testOperationalMessagePresentationFormatsLocationFallback() {
        let message = TradeMessage(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaac2")!,
            proposalID: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            senderID: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
            messageType: .location,
            locationLatitude: 35.443707,
            locationLongitude: 139.638031,
            locationLabel: " 横浜アリーナ付近 "
        )

        let presentation = TradeOperationalMessagePresentation(message: message)

        XCTAssertEqual(presentation.title, "横浜アリーナ付近")
        XCTAssertEqual(presentation.systemImage, "location.fill")
        XCTAssertTrue(presentation.body.contains("緯度 35.44371"))
        XCTAssertTrue(presentation.body.contains("経度 139.63803"))
        XCTAssertEqual(presentation.detail, "位置情報")
    }

    func testDisputeSummaryParsesReceiptMessageAndBuildsReadOnlyDetailModel() throws {
        let proposalID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let reporterID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let respondentID = UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!
        let message = TradeMessage(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaac")!,
            proposalID: proposalID,
            senderID: reporterID,
            messageType: .system,
            body: "取引の申告を受け付けました（DPT-260531-0001）",
            createdAt: Date(timeIntervalSince1970: 3_000)
        )

        let summary = try XCTUnwrap(TradeDisputeSummary(message: message))
        let model = summary.detailModel(
            proposal: makeProposal(id: proposalID, senderID: reporterID, receiverID: respondentID, status: .agreed),
            viewerID: reporterID
        )

        XCTAssertEqual(summary.ticketNo, "DPT-260531-0001")
        XCTAssertEqual(summary.bannerBody, "DPT-260531-0001 · 申告送信済")
        XCTAssertEqual(model.status, .arbitration)
        XCTAssertEqual(model.viewerRole, .reporter)
        XCTAssertFalse(model.canSubmitReply)
        XCTAssertFalse(model.canWithdraw)
        XCTAssertEqual(model.messages.first?.body, "取引の申告を受け付けました（DPT-260531-0001）")
    }

    func testDisputeSummaryUsesMetadataWhenPresent() throws {
        let disputeID = UUID(uuidString: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")!
        let message = TradeMessage(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaad")!,
            proposalID: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            senderID: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
            messageType: .system,
            body: "申告のステータスが更新されました",
            meta: [
                "action": "dispute_responded",
                "dispute_id": disputeID.uuidString,
                "ticket_no": "DPT-260531-0002",
                "category": "noshow",
                "fact_memo": "相手が現れませんでした"
            ]
        )

        let summary = try XCTUnwrap(TradeDisputeSummary(message: message))

        XCTAssertEqual(summary.id, disputeID)
        XCTAssertEqual(summary.status, .replyReceived)
        XCTAssertEqual(summary.category, .noshow)
        XCTAssertEqual(summary.factMemo, "相手が現れませんでした")
    }

    func testDayOfBannerSummarizesArrivalAndOutfitState() throws {
        let viewerID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let partnerID = UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!
        let proposalID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let messages = [
            TradeMessage(
                id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaae")!,
                proposalID: proposalID,
                senderID: partnerID,
                messageType: .arrivalStatus,
                body: "到着しました",
                meta: ["status": "arrived"],
                createdAt: Date(timeIntervalSince1970: 4_000)
            ),
            TradeMessage(
                id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaf")!,
                proposalID: proposalID,
                senderID: viewerID,
                messageType: .outfitPhoto,
                body: "服装写真を共有しました",
                createdAt: Date(timeIntervalSince1970: 4_100)
            )
        ]

        let presentation = try XCTUnwrap(
            TradeDayOfBannerPresentation(
                proposal: makeProposal(id: proposalID, senderID: viewerID, receiverID: partnerID, status: .agreed),
                messages: messages,
                viewerID: viewerID
            )
        )

        XCTAssertEqual(presentation.myArrivalText, "未共有")
        XCTAssertEqual(presentation.partnerArrivalText, "到着済み")
        XCTAssertEqual(presentation.myOutfitText, "共有済み")
        XCTAssertEqual(presentation.partnerOutfitText, "未共有")
        XCTAssertTrue(presentation.promptText.contains("到着"))
    }

    func testDayOfBannerOnlyShowsForActiveTrades() {
        let proposal = makeProposal(
            id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            senderID: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
            receiverID: UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!,
            status: .sent
        )

        XCTAssertNil(TradeDayOfBannerPresentation(proposal: proposal, messages: [], viewerID: proposal.senderID))
    }

    private func makeProposal(
        id: UUID,
        senderID: UUID,
        receiverID: UUID,
        status: ProposalStatus
    ) -> TradeProposal {
        TradeProposal(
            id: id,
            senderID: senderID,
            receiverID: receiverID,
            status: status,
            exchangeMethod: .hand,
            senderGoodsIDs: [UUID(uuidString: "11111111-1111-1111-1111-111111111111")!],
            receiverGoodsIDs: [UUID(uuidString: "22222222-2222-2222-2222-222222222222")!],
            agreedBySender: status == .agreed || status == .completed,
            agreedByReceiver: status == .agreed || status == .completed
        )
    }
}
