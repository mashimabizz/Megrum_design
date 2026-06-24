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

    func testTradeAmountFormatterKeepsExistingCashCopyVariants() {
        XCTAssertEqual(TradeAmountFormatter.yen(123_456), "123,456")
        XCTAssertEqual(TradeAmountFormatter.compactYen(12_000), "¥12,000")
        XCTAssertEqual(TradeAmountFormatter.fixedPrice(amount: 3_500), "定価 3,500円")
        XCTAssertEqual(TradeAmountFormatter.fixedPrice(amount: nil), "定価")
        XCTAssertEqual(TradeAmountFormatter.fixedPrice(amount: nil, fallback: "定価交換"), "定価交換")
        XCTAssertEqual(TradeAmountFormatter.fixedPrice(amount: nil, fallback: "定価も可"), "定価も可")
    }

    func testTradeAmountFormatterNormalizesCashInputToDigitsAndCommas() {
        XCTAssertEqual(TradeAmountFormatter.cashInputText(from: "1500"), "1,500")
        XCTAssertEqual(TradeAmountFormatter.cashInputText(from: "¥1,500円"), "1,500")
        XCTAssertEqual(TradeAmountFormatter.cashInputText(from: "１２３４５６７"), "1,234,567")
        XCTAssertEqual(TradeAmountFormatter.cashInputText(from: "abc"), "")
        XCTAssertEqual(TradeAmountFormatter.cashInputText(from: "0001500"), "1,500")

        XCTAssertEqual(TradeAmountFormatter.cashInputValue(from: "1,500"), 1_500)
        XCTAssertEqual(TradeAmountFormatter.cashInputValue(from: "１２,０００円"), 12_000)
        XCTAssertNil(TradeAmountFormatter.cashInputValue(from: "0"))
        XCTAssertNil(TradeAmountFormatter.cashInputValue(from: "abc"))
    }

    func testNativePreviewPendingListMirrorsRnVisualQaCount() {
        let pending = NativePreviewData.proposals.filter { TradeStage.pending.contains($0.status) }
        XCTAssertEqual(pending.count, 4)
        XCTAssertTrue(pending.contains { $0.status == .negotiating })
        XCTAssertTrue(pending.contains { $0.status == .agreementOneSide })
        XCTAssertEqual(pending.filter { $0.status == .sent }.count, 2)
    }

    func testNativePreviewPendingProposalHasSwipeableGoodsOnBothSides() throws {
        let proposal = try XCTUnwrap(NativePreviewData.proposals.first { $0.status == .negotiating })
        XCTAssertGreaterThanOrEqual(proposal.goodsOffered(by: NativePreviewData.viewerID)?.count ?? 0, 2)
        XCTAssertGreaterThanOrEqual(proposal.goodsRequested(by: NativePreviewData.viewerID)?.count ?? 0, 2)
    }

    func testTradeCardPresentationShowsIncomingSentAsUnopened() {
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
        XCTAssertEqual(presentation.updatedText, "3分前")
        XCTAssertEqual(presentation.readState, .unopened)
        XCTAssertEqual(presentation.readState.title, "未開封")
        XCTAssertEqual(presentation.meetupSummaryText, "横浜アリーナ × 候補確認中")
    }

    func testTradeCardPresentationUsesLastActivityAtForUpdatedText() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let proposal = TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000321")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .sent,
            exchangeMethod: .both,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            createdAt: Date(timeIntervalSince1970: 1_000)
        )

        let presentation = TradeCardPresentation(
            proposal: proposal,
            viewerID: viewerID,
            profilesByUserID: [:],
            lastActivityAt: Date(timeIntervalSince1970: 1_180),
            now: Date(timeIntervalSince1970: 1_240)
        )

        XCTAssertEqual(presentation.updatedText, "1分前")
    }

    func testTradeListOrderingGroupsUnreadOpenedAndWaitingThenLatestActivity() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        let unopenedOlder = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000331")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .sent,
            createdAt: base.addingTimeInterval(10)
        )
        let unopenedNewer = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000332")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .sent,
            createdAt: base.addingTimeInterval(20)
        )
        let openedNewest = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000333")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .negotiating,
            createdAt: base.addingTimeInterval(30)
        )
        let waitingNewest = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000334")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .sent,
            createdAt: base.addingTimeInterval(40)
        )

        let sorted = TradeListOrdering.sorted(
            [waitingNewest, openedNewest, unopenedOlder, unopenedNewer],
            viewerID: viewerID,
            messagesByProposalID: [
                unopenedOlder.id: [
                    tradeMessage(
                        proposalID: unopenedOlder.id,
                        senderID: partnerID,
                        createdAt: base.addingTimeInterval(200)
                    )
                ],
                unopenedNewer.id: [
                    tradeMessage(
                        proposalID: unopenedNewer.id,
                        senderID: partnerID,
                        createdAt: base.addingTimeInterval(300)
                    )
                ],
                openedNewest.id: [
                    tradeMessage(
                        proposalID: openedNewest.id,
                        senderID: partnerID,
                        createdAt: base.addingTimeInterval(400)
                    )
                ],
                waitingNewest.id: [
                    tradeMessage(
                        proposalID: waitingNewest.id,
                        senderID: viewerID,
                        createdAt: base.addingTimeInterval(500)
                    )
                ]
            ],
            viewerReadAtByProposalID: [
                openedNewest.id: base.addingTimeInterval(500)
            ]
        )

        XCTAssertEqual(sorted.map(\.id), [
            unopenedNewer.id,
            unopenedOlder.id,
            openedNewest.id,
            waitingNewest.id
        ])
    }

    func testTradeCardPresentationSeparatesOpenedAndWaitingStates() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        let openedNegotiation = TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000311")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .negotiating,
            exchangeMethod: .both,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            createdAt: Date(timeIntervalSince1970: 1_000)
        )
        let waitingForReply = TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000312")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .sent,
            exchangeMethod: .both,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            createdAt: Date(timeIntervalSince1970: 1_000)
        )

        XCTAssertEqual(
            TradeCardPresentation(
                proposal: openedNegotiation,
                viewerID: viewerID,
                profilesByUserID: [:],
                lastActivityAt: Date(timeIntervalSince1970: 1_000),
                viewerLastReadAt: Date(timeIntervalSince1970: 1_100),
                now: Date(timeIntervalSince1970: 1_180)
            ).readState,
            .opened
        )
        XCTAssertEqual(
            TradeCardPresentation(
                proposal: waitingForReply,
                viewerID: viewerID,
                profilesByUserID: [:],
                now: Date(timeIntervalSince1970: 1_180)
            ).readState,
            .waitingForReply
        )
    }

    func testTradeCardPresentationMarksOpenedProposalUnreadWhenActivityChangesAfterRead() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let proposal = TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000313")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .negotiating,
            exchangeMethod: .both,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            createdAt: Date(timeIntervalSince1970: 1_000),
            updatedAt: Date(timeIntervalSince1970: 1_400)
        )

        XCTAssertEqual(
            TradeCardPresentation(
                proposal: proposal,
                viewerID: viewerID,
                profilesByUserID: [:],
                lastActivityAt: Date(timeIntervalSince1970: 1_400),
                viewerLastReadAt: Date(timeIntervalSince1970: 1_300),
                now: Date(timeIntervalSince1970: 1_500)
            ).readState,
            .unopened
        )
        XCTAssertEqual(
            TradeCardPresentation(
                proposal: proposal,
                viewerID: viewerID,
                profilesByUserID: [:],
                lastActivityAt: Date(timeIntervalSince1970: 1_400),
                viewerLastReadAt: Date(timeIntervalSince1970: 1_400),
                now: Date(timeIntervalSince1970: 1_500)
            ).readState,
            .opened
        )
    }

    func testTradeMeetupSummaryCopyShowsOnlyFirstCandidateAndRemainingCount() {
        XCTAssertEqual(
            TradeMeetupSummaryCopy.displayText(
                primaryText: "横浜アリーナ × 17:00-18:00",
                additionalCandidateCount: 2
            ),
            "横浜アリーナ × 17:00-18:00 / 他2件の候補"
        )
        XCTAssertEqual(
            TradeMeetupSummaryCopy.displayText(primaryText: "  ", additionalCandidateCount: 1),
            "候補確認中 / 他1件の候補"
        )
    }

    func testTradeCardPresentationUsesFirstMeetupCandidateAndRemainingCount() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_800_000_000))
        let firstStart = calendar.date(byAdding: .hour, value: 9, to: day)!
        let firstEnd = calendar.date(byAdding: .minute, value: 30, to: firstStart)!
        let secondStart = calendar.date(byAdding: .hour, value: 13, to: day)!
        let secondEnd = calendar.date(byAdding: .minute, value: 30, to: secondStart)!
        let proposal = TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000302")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .sent,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            meetupCandidates: [
                ProposalMeetupInput(
                    startAt: firstStart,
                    endAt: firstEnd,
                    placeName: "横浜アリーナ 北口",
                    latitude: 35.5122,
                    longitude: 139.6171
                ),
                ProposalMeetupInput(
                    startAt: secondStart,
                    endAt: secondEnd,
                    placeName: "新横浜駅",
                    latitude: 35.5075,
                    longitude: 139.6175
                )
            ]
        )

        let presentation = TradeCardPresentation(
            proposal: proposal,
            viewerID: viewerID,
            profilesByUserID: [:],
            now: day
        )

        XCTAssertEqual(presentation.meetupSummaryText, "横浜アリーナ 北口 × 09:00-09:30 / 他1件の候補")
    }

    func testTradeGoodsCarouselLayoutKeepsDraggingCardsInsideStage() {
        let stageWidth: CGFloat = 124
        let heroWidth: CGFloat = 92
        let heroHeight: CGFloat = 128

        for position in stride(from: -1.18, through: 1.18, by: 0.24) {
            let metrics = TradeGoodsCarouselLayout.cardMetrics(
                for: position,
                heroWidth: heroWidth,
                heroHeight: heroHeight,
                stageWidth: stageWidth
            )
            let leftEdge = stageWidth / 2 + metrics.xOffset - metrics.width / 2
            let rightEdge = stageWidth / 2 + metrics.xOffset + metrics.width / 2
            XCTAssertGreaterThanOrEqual(leftEdge, 0, "position \(position) should stay inside the left edge")
            XCTAssertLessThanOrEqual(rightEdge, stageWidth, "position \(position) should stay inside the right edge")
        }
    }

    func testTradeDetailHeroDistinguishesIncomingAndOutgoingProposals() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let partner = PublicUserProfile(
            profile: UserProfile(id: partnerID, handle: "michi1", displayName: "みち"),
            averageStars: nil,
            evaluationCount: 0,
            completedTradeCount: 0
        )
        let incoming = makeProposal(
            id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0101")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .sent
        )
        let outgoing = TradeProposal(
            id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0102")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .sent,
            exchangeMethod: .hand,
            senderGoodsIDs: [UUID(uuidString: "11111111-1111-1111-1111-111111111111")!],
            receiverGoodsIDs: [UUID(uuidString: "22222222-2222-2222-2222-222222222222")!],
            agreedBySender: true
        )

        let incomingPresentation = TradeDetailHeroPresentation(
            proposal: incoming,
            viewerID: viewerID,
            profilesByUserID: [partnerID: partner]
        )
        let outgoingPresentation = TradeDetailHeroPresentation(
            proposal: outgoing,
            viewerID: viewerID,
            profilesByUserID: [partnerID: partner]
        )

        XCTAssertEqual(incomingPresentation.relationText, "相手から届いた打診")
        XCTAssertEqual(incomingPresentation.statusLabel, "新着打診")
        XCTAssertEqual(incomingPresentation.agreementLabel, "未合意")
        XCTAssertTrue(incomingPresentation.guidanceText.contains("承諾"))
        XCTAssertEqual(outgoingPresentation.relationText, "あなたから送った打診")
        XCTAssertEqual(outgoingPresentation.statusLabel, "相手待ち")
        XCTAssertEqual(outgoingPresentation.agreementLabel, "返信待ち")
        XCTAssertTrue(outgoingPresentation.guidanceText.contains("相手の返答"))
    }

    func testTradeDetailHeroReflectsAgreementAndCompletionStates() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let waitingForViewer = TradeProposal(
            id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0103")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .agreementOneSide,
            exchangeMethod: .hand,
            senderGoodsIDs: [UUID(uuidString: "11111111-1111-1111-1111-111111111111")!],
            receiverGoodsIDs: [UUID(uuidString: "22222222-2222-2222-2222-222222222222")!],
            agreedBySender: true
        )
        let completed = TradeProposal(
            id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0104")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .completed,
            exchangeMethod: .hand,
            senderGoodsIDs: [UUID(uuidString: "11111111-1111-1111-1111-111111111111")!],
            receiverGoodsIDs: [UUID(uuidString: "22222222-2222-2222-2222-222222222222")!],
            agreedBySender: true,
            agreedByReceiver: true,
            approvedBySender: true,
            approvedByReceiver: true
        )

        let agreementPresentation = TradeDetailHeroPresentation(
            proposal: waitingForViewer,
            viewerID: viewerID,
            profilesByUserID: [:]
        )
        let completedPresentation = TradeDetailHeroPresentation(
            proposal: completed,
            viewerID: viewerID,
            profilesByUserID: [:]
        )

        XCTAssertEqual(agreementPresentation.statusLabel, "合意待ち")
        XCTAssertEqual(agreementPresentation.agreementLabel, "あなたの合意待ち")
        XCTAssertTrue(agreementPresentation.guidanceText.contains("相手は合意済み"))
        XCTAssertEqual(completedPresentation.statusLabel, "完了")
        XCTAssertEqual(completedPresentation.agreementLabel, "完了")
        XCTAssertTrue(completedPresentation.guidanceText.contains("取引完了済み"))
    }

    func testTradeProposalKeepsCashOfferForPaymentSummary() {
        let proposal = TradeProposal(
            id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0110")!,
            senderID: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            receiverID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            status: .agreed,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            cashOffer: true,
            cashAmount: 1_100,
            agreedBySender: true,
            agreedByReceiver: true
        )

        XCTAssertTrue(proposal.cashOffer)
        XCTAssertEqual(proposal.cashAmount, 1_100)
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

    func testTradeMessageInputActionPolicyBuildsAgreedHandActions() {
        let policy = TradeMessageInputActionPolicy(
            proposalStatus: .agreed,
            supportsHandExchange: true,
            showsCounterProposal: true
        )

        XCTAssertEqual(policy.quickActions, [.location])
        XCTAssertEqual(policy.overflowActions, [
            .location,
            .chatCamera,
            .chatLibrary
        ])
    }

    func testTradeMessageInputActionPolicyBuildsAgreedNonHandActions() {
        let policy = TradeMessageInputActionPolicy(
            proposalStatus: .agreed,
            supportsHandExchange: false,
            showsCounterProposal: true
        )

        XCTAssertEqual(policy.quickActions, [])
        XCTAssertEqual(policy.overflowActions, [.chatCamera, .chatLibrary])
    }

    func testTradeMessageInputActionPolicyBuildsNegotiationActions() {
        let withoutCounter = TradeMessageInputActionPolicy(
            proposalStatus: .sent,
            supportsHandExchange: true,
            showsCounterProposal: false
        )
        let withCounter = TradeMessageInputActionPolicy(
            proposalStatus: .negotiating,
            supportsHandExchange: true,
            showsCounterProposal: true
        )

        XCTAssertEqual(withoutCounter.quickActions, [.schedule])
        XCTAssertEqual(withoutCounter.overflowActions, [.schedule, .chatCamera, .chatLibrary])
        XCTAssertEqual(withCounter.quickActions, [.schedule, .counterProposal])
        XCTAssertEqual(withCounter.overflowActions, [.schedule, .counterProposal, .chatCamera, .chatLibrary])
    }

    func testTradeMessageInputContextDerivesActionPolicyAndState() {
        let context = TradeMessageInputContext(
            isSending: true,
            canUseCamera: false,
            proposalStatus: .agreed,
            supportsHandExchange: true,
            showsCounterProposal: true
        )

        XCTAssertTrue(context.isSending)
        XCTAssertFalse(context.canUseCamera)
        XCTAssertEqual(context.quickActions, [.location])
        XCTAssertEqual(context.overflowActions, [
            .location,
            .chatCamera,
            .chatLibrary
        ])
    }

    func testTradeMessageInputContextHidesQuickActionsWhileComposing() {
        let context = TradeMessageInputContext(
            isSending: false,
            canUseCamera: true,
            proposalStatus: .agreed,
            supportsHandExchange: true,
            showsCounterProposal: false
        )

        XCTAssertTrue(context.shouldShowQuickActions(isComposerFocused: false))
        XCTAssertFalse(context.shouldShowQuickActions(isComposerFocused: true))
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

    func testUnavailableChatActionsDistinguishPhotoAndOutfitPhoto() {
        XCTAssertEqual(TradeUnavailableChatAction.photo.title, "写真を送信")
        XCTAssertEqual(TradeUnavailableChatAction.outfitPhoto.title, "服装写真を共有")
        XCTAssertTrue(TradeUnavailableChatAction.photo.description.contains("写真を送信"))
        XCTAssertTrue(TradeUnavailableChatAction.outfitPhoto.description.contains("服装写真"))
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

    func testEvidenceSystemMessagePresentationUsesSenderPerspective() {
        let message = TradeMessage(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaac")!,
            proposalID: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            senderID: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
            messageType: .system,
            body: "取引証跡が追加されました",
            meta: ["action": TradeEvidenceSystemMessage.action]
        )

        let outgoing = TradeSystemMessagePresentation(message: message, isMine: true)
        let incoming = TradeSystemMessagePresentation(message: message, isMine: false)

        XCTAssertTrue(TradeEvidenceSystemMessage.isEvidenceNotice(message))
        XCTAssertEqual(outgoing.title, "取引証跡を送りました")
        XCTAssertEqual(incoming.title, "取引証跡が届きました")
        XCTAssertEqual(outgoing.systemImage, "doc.viewfinder")
        XCTAssertEqual(outgoing.body, "タップして証跡写真を確認")
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

    func testTradeChatTimelineRowsAddDayDividersAndReadReceipts() {
        let viewerID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let partnerID = UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!
        let proposalID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let firstDay = Date(timeIntervalSince1970: 1_800_000_000)
        let laterSameDay = firstDay.addingTimeInterval(60 * 30)
        let nextDay = firstDay.addingTimeInterval(60 * 60 * 24)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let rows = TradeChatTimelineRows.make(
            messages: [
                TradeMessage(
                    id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1")!,
                    proposalID: proposalID,
                    senderID: partnerID,
                    messageType: .text,
                    body: "確認お願いします",
                    createdAt: firstDay
                ),
                TradeMessage(
                    id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2")!,
                    proposalID: proposalID,
                    senderID: viewerID,
                    messageType: .text,
                    body: "了解しました",
                    createdAt: laterSameDay
                ),
                TradeMessage(
                    id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3")!,
                    proposalID: proposalID,
                    senderID: viewerID,
                    messageType: .arrivalStatus,
                    body: "向かっています",
                    createdAt: nextDay
                )
            ],
            viewerID: viewerID,
            partnerLastReadAt: nextDay.addingTimeInterval(60),
            calendar: calendar
        )

        XCTAssertEqual(rows.map(\.dayDividerText), [
            "1/15 (金) · 08:00",
            nil,
            "1/16 (土) · 08:00"
        ])
        XCTAssertEqual(rows.map(\.isMine), [false, true, true])
        XCTAssertEqual(rows.map(\.isReadByPartner), [false, true, false])
    }

    private func makeProposal(
        id: UUID,
        senderID: UUID,
        receiverID: UUID,
        status: ProposalStatus,
        createdAt: Date = .now
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
            agreedByReceiver: status == .agreed || status == .completed,
            createdAt: createdAt
        )
    }

    private func tradeMessage(
        proposalID: UUID,
        senderID: UUID,
        createdAt: Date
    ) -> TradeMessage {
        TradeMessage(
            id: UUID(),
            proposalID: proposalID,
            senderID: senderID,
            messageType: .text,
            body: "更新",
            createdAt: createdAt
        )
    }
}
