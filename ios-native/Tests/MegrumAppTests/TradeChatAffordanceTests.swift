@testable import MegrumApp
import CoreGraphics
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

    func testTradeStageAttentionCountsTrackFooterBadgeTargets() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        let incomingPending = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000091")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .sent,
            createdAt: base
        )
        let outgoingPending = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000092")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .sent,
            createdAt: base
        )
        let inProgressUnread = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000093")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .agreed,
            createdAt: base
        )
        let inProgressRead = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000094")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .agreed,
            createdAt: base
        )
        let completedNeedsEvaluation = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000095")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .completed,
            createdAt: base
        )
        let completedEvaluated = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000096")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .completed,
            createdAt: base
        )
        let completedWithoutSettlement = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000098")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .completed,
            createdAt: base,
            isCompletedTradeSettled: false
        )
        let cancelled = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000097")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .cancelled,
            createdAt: base
        )
        let messagesByProposalID: [UUID: [TradeMessage]] = [
            inProgressUnread.id: [
                tradeMessage(
                    proposalID: inProgressUnread.id,
                    senderID: partnerID,
                    createdAt: base.addingTimeInterval(60)
                )
            ],
            inProgressRead.id: [
                tradeMessage(
                    proposalID: inProgressRead.id,
                    senderID: partnerID,
                    createdAt: base.addingTimeInterval(90)
                )
            ],
            completedEvaluated.id: [
                TradeMessage(
                    id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaa0096")!,
                    proposalID: completedEvaluated.id,
                    senderID: viewerID,
                    messageType: .system,
                    body: TradeEvaluationSystemMessage.body(actorDisplayName: "みち", actorHandle: "michi"),
                    meta: ["action": TradeEvaluationSystemMessage.action],
                    createdAt: base.addingTimeInterval(120)
                )
            ]
        ]

        let counts = TradeStageAttentionCounts(
            proposals: [
                incomingPending,
                outgoingPending,
                inProgressUnread,
                inProgressRead,
                completedNeedsEvaluation,
                completedEvaluated,
                completedWithoutSettlement,
                cancelled
            ],
            messagesByProposalID: messagesByProposalID,
            viewerReadAtByProposalID: [
                inProgressRead.id: base.addingTimeInterval(120)
            ],
            viewerID: viewerID
        )

        XCTAssertEqual(counts.pendingNeedsResponse, 1)
        XCTAssertEqual(counts.inProgressUnread, 1)
        XCTAssertEqual(counts.completedNeedsEvaluation, 1)
        XCTAssertEqual(counts.total, 3)
    }

    func testTradeDetailSlideBackSwipeTracksOnlyRightHorizontalDrags() {
        XCTAssertEqual(
            TradeDetailSlideBackSwipeResolver.interactiveOffset(
                translation: CGSize(width: 90, height: 12),
                screenWidth: 390
            ),
            90
        )
        XCTAssertNil(
            TradeDetailSlideBackSwipeResolver.interactiveOffset(
                translation: CGSize(width: -90, height: 12),
                screenWidth: 390
            )
        )
        XCTAssertNil(
            TradeDetailSlideBackSwipeResolver.interactiveOffset(
                translation: CGSize(width: 50, height: 90),
                screenWidth: 390
            )
        )
    }

    func testTradeDetailSlideBackSwipeCapturesPhysicalLeftEdge() {
        XCTAssertGreaterThanOrEqual(TradeDetailSlidePresentationMetrics.leadingEdgeCaptureWidth, 24)
        XCTAssertLessThanOrEqual(TradeDetailSlidePresentationMetrics.leadingEdgeCaptureWidth, 40)
    }

    func testTradeDetailSlideBackSwipeDismissesFromAnywhereAfterThreshold() {
        XCTAssertTrue(
            TradeDetailSlideBackSwipeResolver.shouldDismiss(
                translation: CGSize(width: 90, height: 12),
                predictedEndTranslationWidth: 100,
                screenWidth: 390
            )
        )
        XCTAssertTrue(
            TradeDetailSlideBackSwipeResolver.shouldDismiss(
                translation: CGSize(width: 35, height: 4),
                predictedEndTranslationWidth: 180,
                screenWidth: 390
            )
        )
        XCTAssertFalse(
            TradeDetailSlideBackSwipeResolver.shouldDismiss(
                translation: CGSize(width: 36, height: 6),
                predictedEndTranslationWidth: 44,
                screenWidth: 390
            )
        )
    }

    func testTradeDetailPresentationSlidesInAndOutFromTrailingEdge() {
        XCTAssertEqual(
            TradeDetailSlidePresentationResolver.contentOffset(
                isPresented: false,
                dragOffset: 0,
                screenWidth: 390
            ),
            390
        )
        XCTAssertEqual(
            TradeDetailSlidePresentationResolver.contentOffset(
                isPresented: true,
                dragOffset: 0,
                screenWidth: 390
            ),
            0
        )
        XCTAssertEqual(
            TradeDetailSlidePresentationResolver.contentOffset(
                isPresented: true,
                dragOffset: 118,
                screenWidth: 390
            ),
            118
        )
        XCTAssertEqual(
            TradeDetailSlidePresentationResolver.contentOffset(
                isPresented: true,
                dragOffset: 520,
                screenWidth: 390
            ),
            390
        )
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

    func testTradeProposalResponsePresentationRequiresMethodChoiceForBoth() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let proposal = TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000401")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .sent,
            exchangeMethod: .both,
            senderGoodsIDs: [UUID(uuidString: "11111111-1111-1111-1111-111111111111")!],
            receiverGoodsIDs: [UUID(uuidString: "22222222-2222-2222-2222-222222222222")!],
            cashOffer: true
        )

        let presentation = TradeProposalResponsePresentation(
            proposal: proposal,
            viewerID: viewerID,
            proposedPaymentMethods: [.paypay],
            proposedPaymentOtherNote: nil,
            availablePaymentMethods: [.bankTransfer, .paypay],
            availablePaymentOtherNote: nil
        )

        XCTAssertTrue(presentation.showsResponseControls)
        XCTAssertTrue(presentation.needsExchangeMethodSelection)
        XCTAssertTrue(presentation.showsResponseInstruction)
        XCTAssertEqual(presentation.selectableExchangeMethods, [.hand, .mail])
        XCTAssertEqual(presentation.defaultSelectedExchangeMethod, .mail)
        XCTAssertEqual(presentation.primaryActionTitle(selectedExchangeMethod: .mail), "郵送交換で応じる")
        XCTAssertEqual(presentation.paymentOptions, [.bankTransfer, .paypay, .cashExchange])
        XCTAssertEqual(presentation.paymentMenuOptions.map(\.title), ["銀行振込", "PayPay", "現金交換"])
        XCTAssertEqual(presentation.defaultPaymentMethod, .paypay)
        XCTAssertEqual(presentation.defaultPaymentOptionID, "method:paypay")
    }

    func testTradeProposalResponsePresentationIncludesBothOtherPaymentNotes() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let proposal = TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000407")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .sent,
            exchangeMethod: .mail,
            senderGoodsIDs: [UUID(uuidString: "11111111-1111-1111-1111-111111111111")!],
            receiverGoodsIDs: [UUID(uuidString: "22222222-2222-2222-2222-222222222222")!],
            cashOffer: true
        )

        let presentation = TradeProposalResponsePresentation(
            proposal: proposal,
            viewerID: viewerID,
            proposedPaymentMethods: [.other],
            proposedPaymentOtherNote: "メルペイ",
            availablePaymentMethods: [.other],
            availablePaymentOtherNote: "楽天ペイ"
        )

        XCTAssertEqual(
            presentation.paymentMenuOptions.map(\.title),
            ["銀行振込", "PayPay", "現金交換", "メルペイ", "楽天ペイ"]
        )
        XCTAssertEqual(presentation.defaultPaymentOptionID, "partner-other")
        XCTAssertEqual(presentation.paymentOptionTitle(for: "viewer-other"), "楽天ペイ")
    }

    func testTradeProposalResponsePresentationUsesCompactBarterActionWhenNoChoiceIsNeeded() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let proposal = TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000402")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .sent,
            exchangeMethod: .hand,
            senderGoodsIDs: [UUID(uuidString: "11111111-1111-1111-1111-111111111111")!],
            receiverGoodsIDs: [UUID(uuidString: "22222222-2222-2222-2222-222222222222")!],
            cashOffer: false
        )

        let presentation = TradeProposalResponsePresentation(
            proposal: proposal,
            viewerID: viewerID,
            proposedPaymentMethods: [],
            proposedPaymentOtherNote: nil,
            availablePaymentMethods: [],
            availablePaymentOtherNote: nil
        )

        XCTAssertTrue(presentation.showsResponseControls)
        XCTAssertFalse(presentation.needsExchangeMethodSelection)
        XCTAssertFalse(presentation.showsResponseInstruction)
        XCTAssertFalse(presentation.showsPaymentSelector)
        XCTAssertEqual(presentation.primaryActionTitle(selectedExchangeMethod: nil), "出品に応じる")
    }

    func testTradeCounterProposalSystemMessageNamesActor() {
        XCTAssertEqual(
            TradeCounterProposalSystemMessage.body(actorDisplayName: "  みち  ", actorHandle: "michilion"),
            "みちが条件を変えて再出品しました"
        )
        XCTAssertEqual(
            TradeCounterProposalSystemMessage.body(actorDisplayName: nil, actorHandle: "michilion"),
            "@michilionが条件を変えて再出品しました"
        )
    }

    func testTradeCounterProposalSystemMessageDetectsViewerNotice() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let proposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000405")!
        let message = TradeMessage(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000407")!,
            proposalID: proposalID,
            senderID: viewerID,
            messageType: .system,
            body: "みちが条件を変えて再出品しました"
        )

        XCTAssertTrue(TradeCounterProposalSystemMessage.isCounterProposalNotice(message))
    }

    func testTradeProposalResponsePresentationHidesAgreeAfterViewerCounterProposal() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let proposal = TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000406")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .sent,
            exchangeMethod: .both,
            senderGoodsIDs: [UUID(uuidString: "11111111-1111-1111-1111-111111111111")!],
            receiverGoodsIDs: [UUID(uuidString: "22222222-2222-2222-2222-222222222222")!],
            cashOffer: true
        )

        let presentation = TradeProposalResponsePresentation(
            proposal: proposal,
            viewerID: viewerID,
            proposedPaymentMethods: [.paypay],
            proposedPaymentOtherNote: nil,
            availablePaymentMethods: [.paypay],
            availablePaymentOtherNote: nil,
            viewerHasCounterProposal: true
        )

        XCTAssertTrue(presentation.showsResponseControls)
        XCTAssertFalse(presentation.canAgree)
        XCTAssertTrue(presentation.canCounterProposal)
        XCTAssertTrue(presentation.canReject)
        XCTAssertFalse(presentation.showsPrimaryAgreeAction)
        XCTAssertFalse(presentation.needsExchangeMethodSelection)
        XCTAssertFalse(presentation.showsPaymentSelector)
        XCTAssertEqual(presentation.responseHeaderText, "現在打診中です。相手からの返信待ちです。")
    }

    func testTradeProposalResponsePresentationHidesControlsForInitialSenderWaiting() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let proposal = TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000403")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .sent,
            exchangeMethod: .both,
            senderGoodsIDs: [UUID(uuidString: "11111111-1111-1111-1111-111111111111")!],
            receiverGoodsIDs: [UUID(uuidString: "22222222-2222-2222-2222-222222222222")!]
        )

        let presentation = TradeProposalResponsePresentation(
            proposal: proposal,
            viewerID: viewerID,
            proposedPaymentMethods: [.other],
            proposedPaymentOtherNote: "メルペイ",
            availablePaymentMethods: [.other],
            availablePaymentOtherNote: nil
        )

        XCTAssertFalse(presentation.showsResponseControls)
        XCTAssertFalse(presentation.canAgree)
        XCTAssertEqual(presentation.paymentTitle(for: .other), "メルペイ")
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
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            createdAt: Date(timeIntervalSince1970: 1_000)
        )
        let partner = PublicUserProfile(
            profile: UserProfile(
                id: partnerID,
                handle: "michilion",
                displayName: "みち",
                gender: .female,
                age: 27
            ),
            averageStars: 4.6,
            evaluationCount: 12,
            completedTradeCount: 0
        )

        let presentation = TradeCardPresentation(
            proposal: proposal,
            viewerID: viewerID,
            profilesByUserID: [partnerID: partner],
            now: Date(timeIntervalSince1970: 1_180)
        )

        XCTAssertEqual(presentation.partnerHandle, "michilion")
        XCTAssertEqual(presentation.partnerRatingText, "★ 4.6（12件）")
        XCTAssertEqual(presentation.partnerDemographicText, "20代・女性")
        XCTAssertEqual(presentation.updatedText, "3分前")
        XCTAssertEqual(presentation.readState, .unopened)
        XCTAssertEqual(presentation.readState.title, "未開封")
        XCTAssertEqual(presentation.unreadBadgeCount, 1)
        XCTAssertNil(presentation.meetupSummaryText)
        XCTAssertEqual(presentation.conditionIconSystemName, "mappin.circle")
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
        XCTAssertEqual(
            TradeCardPresentation(
                proposal: waitingForReply,
                viewerID: viewerID,
                profilesByUserID: [:],
                now: Date(timeIntervalSince1970: 1_180)
            ).unreadBadgeCount,
            0
        )
    }

    func testTradeCardReadStateHighlightsOnlyUnopenedRows() {
        XCTAssertTrue(TradeCardReadState.unopened.showsStateBackground)
        XCTAssertFalse(TradeCardReadState.opened.showsStateBackground)
        XCTAssertFalse(TradeCardReadState.waitingForReply.showsStateBackground)
    }

    func testTradeCardPresentationCountsOnlyUnreadIncomingMessagesAfterProposalWasRead() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let proposalID = UUID(uuidString: "00000000-0000-0000-0000-000000000315")!
        let proposal = TradeProposal(
            id: proposalID,
            senderID: partnerID,
            receiverID: viewerID,
            status: .negotiating,
            exchangeMethod: .both,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            createdAt: Date(timeIntervalSince1970: 1_000),
            updatedAt: Date(timeIntervalSince1970: 1_000)
        )

        let presentation = TradeCardPresentation(
            proposal: proposal,
            viewerID: viewerID,
            profilesByUserID: [:],
            messages: [
                tradeMessage(
                    proposalID: proposalID,
                    senderID: partnerID,
                    createdAt: Date(timeIntervalSince1970: 1_120)
                ),
                tradeMessage(
                    proposalID: proposalID,
                    senderID: viewerID,
                    createdAt: Date(timeIntervalSince1970: 1_140)
                ),
                tradeMessage(
                    proposalID: proposalID,
                    senderID: partnerID,
                    createdAt: Date(timeIntervalSince1970: 1_160)
                )
            ],
            lastActivityAt: Date(timeIntervalSince1970: 1_160),
            viewerLastReadAt: Date(timeIntervalSince1970: 1_080),
            now: Date(timeIntervalSince1970: 1_200)
        )

        XCTAssertEqual(presentation.readState, .unopened)
        XCTAssertEqual(presentation.unreadBadgeCount, 2)
    }

    func testTradeCardPresentationMarksSettledCompletedTradeAsEvaluationAttention() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let proposal = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000316")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .completed,
            createdAt: Date(timeIntervalSince1970: 1_000)
        )

        XCTAssertTrue(
            TradeCardPresentation(
                proposal: proposal,
                viewerID: viewerID,
                profilesByUserID: [:],
                messages: [],
                now: Date(timeIntervalSince1970: 1_200)
            ).needsEvaluationAttention
        )
    }

    func testEvaluationAttentionRequiresSettledCompletedTradeAndMissingViewerEvaluation() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        let settledCompleted = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000317")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .completed,
            createdAt: base
        )
        let completedWithoutSettlement = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000318")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .completed,
            createdAt: base,
            isCompletedTradeSettled: false
        )
        let cancelled = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000319")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .cancelled,
            createdAt: base
        )
        let evaluationNotice = TradeMessage(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaa0317")!,
            proposalID: settledCompleted.id,
            senderID: viewerID,
            messageType: .system,
            body: TradeEvaluationSystemMessage.body(actorDisplayName: "みち", actorHandle: "michi"),
            meta: ["action": TradeEvaluationSystemMessage.action],
            createdAt: base.addingTimeInterval(60)
        )

        XCTAssertTrue(
            TradeEvaluationAttentionPolicy.needsViewerEvaluation(
                proposal: settledCompleted,
                viewerID: viewerID,
                messages: []
            )
        )
        XCTAssertFalse(
            TradeEvaluationAttentionPolicy.needsViewerEvaluation(
                proposal: settledCompleted,
                viewerID: viewerID,
                messages: [evaluationNotice]
            )
        )
        XCTAssertFalse(
            TradeEvaluationAttentionPolicy.needsViewerEvaluation(
                proposal: completedWithoutSettlement,
                viewerID: viewerID,
                messages: []
            )
        )
        XCTAssertFalse(
            TradeEvaluationAttentionPolicy.needsViewerEvaluation(
                proposal: cancelled,
                viewerID: viewerID,
                messages: []
            )
        )
    }

    func testTradeListOrderingPrioritizesCompletedEvaluationAttention() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        let needsEvaluationOlder = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000341")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .completed,
            createdAt: base.addingTimeInterval(10)
        )
        let evaluatedNewer = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000342")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .completed,
            createdAt: base.addingTimeInterval(20)
        )
        let cancelledNewest = makeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000343")!,
            senderID: viewerID,
            receiverID: partnerID,
            status: .cancelled,
            createdAt: base.addingTimeInterval(30)
        )
        let evaluationNotice = TradeMessage(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaa0342")!,
            proposalID: evaluatedNewer.id,
            senderID: viewerID,
            messageType: .system,
            body: TradeEvaluationSystemMessage.body(actorDisplayName: "みち", actorHandle: "michi"),
            meta: ["action": TradeEvaluationSystemMessage.action],
            createdAt: base.addingTimeInterval(40)
        )

        let sorted = TradeListOrdering.sorted(
            [cancelledNewest, evaluatedNewer, needsEvaluationOlder],
            viewerID: viewerID,
            messagesByProposalID: [
                evaluatedNewer.id: [evaluationNotice]
            ]
        )

        XCTAssertEqual(sorted.map(\.id), [
            needsEvaluationOlder.id,
            evaluatedNewer.id,
            cancelledNewest.id
        ])
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

        XCTAssertEqual(presentation.meetupSummaryText, "現地: 横浜アリーナ 北口 / \(firstStart.formatted(.dateTime.locale(Locale(identifier: "ja_JP")).month().day())) / 他1件")
        XCTAssertEqual(presentation.conditionIconSystemName, "mappin.circle")
    }

    func testTradeCardPresentationShowsShippingAndBothConditionsFromProposalTags() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let mailProposal = TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000303")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .sent,
            exchangeMethod: .mail,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            conditionTags: ["送料: 受け取る側が負担", "発送目安: 2〜4日以内"]
        )
        let bothProposal = TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000304")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .sent,
            exchangeMethod: .both,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            conditionTags: [
                "待ち合わせ: 東京都 / 東京ドーム前 / 6月28日",
                "送料: 要相談",
                "発送目安: 1〜2日以内"
            ]
        )
        let localConsultationProposal = TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000305")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .sent,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            conditionTags: ["待ち合わせ: 東京都 / 相談して決める"]
        )
        let missingLocalPlaceProposal = TradeProposal(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000306")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .sent,
            exchangeMethod: .hand,
            senderGoodsIDs: [],
            receiverGoodsIDs: [],
            conditionTags: ["待ち合わせ: 未設定 / 東京ドーム前 / 6月28日"]
        )

        let mailPresentation = TradeCardPresentation(
            proposal: mailProposal,
            viewerID: viewerID,
            profilesByUserID: [:]
        )
        let bothPresentation = TradeCardPresentation(
            proposal: bothProposal,
            viewerID: viewerID,
            profilesByUserID: [:]
        )
        let localConsultationPresentation = TradeCardPresentation(
            proposal: localConsultationProposal,
            viewerID: viewerID,
            profilesByUserID: [:]
        )
        let missingLocalPlacePresentation = TradeCardPresentation(
            proposal: missingLocalPlaceProposal,
            viewerID: viewerID,
            profilesByUserID: [:]
        )

        XCTAssertEqual(mailPresentation.meetupSummaryText, "郵送: 送料 受け取る側が負担 / 発送目安 2〜4日以内")
        XCTAssertEqual(mailPresentation.conditionIconSystemName, "shippingbox.circle")
        XCTAssertEqual(
            bothPresentation.meetupSummaryText,
            "現地: 東京都 / 東京ドーム前 / 6月28日\n郵送: 送料 要相談 / 発送目安 1〜2日以内"
        )
        XCTAssertEqual(bothPresentation.conditionIconSystemName, "arrow.left.arrow.right.circle")
        XCTAssertEqual(localConsultationPresentation.meetupSummaryText, "現地: 東京都 / 日程相談")
        XCTAssertNil(missingLocalPlacePresentation.meetupSummaryText)
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
            profile: UserProfile(
                id: partnerID,
                handle: "michi1",
                displayName: "みち",
                gender: .female,
                prefecture: "神奈川県",
                age: 27
            ),
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

        XCTAssertEqual(incomingPresentation.partnerDisplayName, "みち")
        XCTAssertEqual(incomingPresentation.relationText, "相手から届いた打診")
        XCTAssertEqual(incomingPresentation.partnerHandle, "michi1")
        XCTAssertEqual(incomingPresentation.partnerMetaText, "20代・女性・神奈川県")
        XCTAssertEqual(incomingPresentation.statusLabel, "新着打診")
        XCTAssertEqual(incomingPresentation.agreementLabel, "未合意")
        XCTAssertTrue(incomingPresentation.guidanceText.contains("承諾"))
        XCTAssertEqual(outgoingPresentation.relationText, "あなたから送った打診")
        XCTAssertEqual(outgoingPresentation.statusLabel, "現在打診中")
        XCTAssertEqual(outgoingPresentation.agreementLabel, "相手からの返信待ち")
        XCTAssertTrue(outgoingPresentation.guidanceText.contains("現在打診中です"))
    }

    func testTradeDetailHeroUsesOutgoingWaitingStateAfterViewerCounterProposal() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let incoming = makeProposal(
            id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0105")!,
            senderID: partnerID,
            receiverID: viewerID,
            status: .sent
        )

        let presentation = TradeDetailHeroPresentation(
            proposal: incoming,
            viewerID: viewerID,
            profilesByUserID: [:],
            viewerHasCounterProposal: true
        )

        XCTAssertEqual(presentation.relationText, "あなたから送った打診")
        XCTAssertEqual(presentation.statusLabel, "現在打診中")
        XCTAssertEqual(presentation.agreementLabel, "相手からの返信待ち")
        XCTAssertTrue(presentation.guidanceText.contains("相手からの返信待ち"))
    }

    func testTradePhotoMessageLayoutUsesCompactThumbnails() {
        XCTAssertEqual(TradePhotoMessageLayout.thumbnailSize(for: .photo), CGSize(width: 150, height: 150))
        XCTAssertEqual(TradePhotoMessageLayout.thumbnailSize(for: .outfitPhoto), CGSize(width: 142, height: 188))
        XCTAssertTrue(TradePhotoMessageLayout.isPhotoMessage(.photo))
        XCTAssertTrue(TradePhotoMessageLayout.isPhotoMessage(.outfitPhoto))
        XCTAssertFalse(TradePhotoMessageLayout.isPhotoMessage(.text))
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

    func testAgreementNextStepFooterHidesAfterEvidencePhotoExists() {
        let proposalID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbb0111")!
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let evidencePhoto = TradeEvidencePhoto(
            id: UUID(uuidString: "eeeeeeee-eeee-eeee-eeee-eeeeeeee0111")!,
            proposalID: proposalID,
            photoURL: URL(string: "https://example.com/evidence.jpg")!,
            position: 1,
            takenBy: viewerID
        )

        XCTAssertTrue(
            TradeAgreementNextStepFooterPolicy.showsEvidenceCaptureFooter(
                status: .agreed,
                evidencePhotos: []
            )
        )
        XCTAssertFalse(
            TradeAgreementNextStepFooterPolicy.showsEvidenceCaptureFooter(
                status: .agreed,
                evidencePhotos: [evidencePhoto]
            )
        )
        XCTAssertFalse(
            TradeAgreementNextStepFooterPolicy.showsEvidenceCaptureFooter(
                status: .completed,
                evidencePhotos: []
            )
        )
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

        XCTAssertEqual(withoutCounter.quickActions, [])
        XCTAssertEqual(withoutCounter.overflowActions, [.location, .chatCamera, .chatLibrary])
        XCTAssertEqual(withCounter.quickActions, [.counterProposal])
        XCTAssertEqual(withCounter.overflowActions, [.location, .counterProposal, .chatCamera, .chatLibrary])
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
            body: TradeEvaluationSystemMessage.body(actorDisplayName: "みち", actorHandle: "michi"),
            meta: [
                "action": TradeEvaluationSystemMessage.action,
                "stars": "5",
                "comment": "ありがとうございました",
                "rater_display_name": "みち"
            ]
        )

        let state = TradeEvaluationPromptState(
            proposal: proposal,
            viewerID: viewerID,
            messages: [message]
        )

        XCTAssertTrue(state.hasSubmittedEvaluation)
        XCTAssertFalse(state.hasPartnerSubmittedEvaluation)
        XCTAssertFalse(state.shouldRevealEvaluations)
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
                messages: [partnerMessage]
            ).hasPartnerSubmittedEvaluation
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

    func testEvaluationPromptStateRevealsBothEvaluationCommentsAfterMutualSubmission() {
        let viewerID = UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!
        let partnerID = UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!
        let proposalID = UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!
        let proposal = makeProposal(id: proposalID, senderID: viewerID, receiverID: partnerID, status: .completed)
        let ownMessage = TradeMessage(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaea11")!,
            proposalID: proposalID,
            senderID: viewerID,
            messageType: .system,
            body: "みちの評価が完了しました",
            meta: [
                "action": TradeEvaluationSystemMessage.action,
                "stars": "5",
                "comment": "丁寧でした",
                "rater_display_name": "みち"
            ],
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let partnerMessage = TradeMessage(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaea12")!,
            proposalID: proposalID,
            senderID: partnerID,
            messageType: .system,
            body: "相手の評価が完了しました",
            meta: [
                "action": TradeEvaluationSystemMessage.action,
                "stars": "4",
                "comment": "スムーズでした",
                "rater_display_name": "相手"
            ],
            createdAt: Date(timeIntervalSince1970: 120)
        )

        let state = TradeEvaluationPromptState(
            proposal: proposal,
            viewerID: viewerID,
            messages: [partnerMessage, ownMessage]
        )

        XCTAssertTrue(state.hasSubmittedEvaluation)
        XCTAssertTrue(state.hasPartnerSubmittedEvaluation)
        XCTAssertTrue(state.shouldRevealEvaluations)
        XCTAssertEqual(state.revealedEvaluations.map(\.comment), ["丁寧でした", "スムーズでした"])
        XCTAssertEqual(state.revealedEvaluations.map(\.roleTag), ["あなた", "相手"])
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

    func testUnavailableChatActionMapsOnlyPhotoMessageFailures() {
        XCTAssertEqual(TradeUnavailableChatAction.messageFailureAction(for: .photo), .photo)
        XCTAssertEqual(TradeUnavailableChatAction.messageFailureAction(for: .outfitPhoto), .outfitPhoto)
        XCTAssertNil(TradeUnavailableChatAction.messageFailureAction(for: .text))
        XCTAssertNil(TradeUnavailableChatAction.messageFailureAction(for: .location))
        XCTAssertNil(TradeUnavailableChatAction.messageFailureAction(for: .arrivalStatus))
        XCTAssertNil(TradeUnavailableChatAction.messageFailureAction(for: .system))
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
            body: TradeEvidenceSystemMessage.body(actorDisplayName: "みち", actorHandle: "michi"),
            meta: ["action": TradeEvidenceSystemMessage.action]
        )

        let outgoing = TradeSystemMessagePresentation(message: message, isMine: true)
        let incoming = TradeSystemMessagePresentation(message: message, isMine: false)

        XCTAssertTrue(TradeEvidenceSystemMessage.isEvidenceNotice(message))
        XCTAssertEqual(TradeEvidenceSystemMessage.body(actorDisplayName: nil, actorHandle: "cash"), "@cashが取引証跡をアップロードしました")
        XCTAssertEqual(outgoing.title, "取引更新")
        XCTAssertEqual(incoming.title, "取引更新")
        XCTAssertEqual(outgoing.systemImage, "doc.viewfinder")
        XCTAssertEqual(outgoing.body, "みちが取引証跡をアップロードしました")
        XCTAssertNil(outgoing.detail)
    }

    func testCompletionSystemMessagePresentationUsesCompletedStatusCopy() {
        let message = TradeMessage(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaad")!,
            proposalID: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
            senderID: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
            messageType: .system,
            body: "取引が完了しました",
            meta: ["action": TradeCompletionSystemMessage.action]
        )

        let presentation = TradeSystemMessagePresentation(message: message)

        XCTAssertTrue(TradeCompletionSystemMessage.isCompletionNotice(message))
        XCTAssertEqual(presentation.title, "取引完了")
        XCTAssertEqual(presentation.systemImage, "checkmark.seal.fill")
        XCTAssertEqual(presentation.body, "取引が完了しました")
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
        createdAt: Date = .now,
        isCompletedTradeSettled: Bool = true
    ) -> TradeProposal {
        let isSettledCompleted = status == .completed && isCompletedTradeSettled
        return TradeProposal(
            id: id,
            senderID: senderID,
            receiverID: receiverID,
            status: status,
            exchangeMethod: .hand,
            senderGoodsIDs: [UUID(uuidString: "11111111-1111-1111-1111-111111111111")!],
            receiverGoodsIDs: [UUID(uuidString: "22222222-2222-2222-2222-222222222222")!],
            agreedBySender: status == .agreed || isSettledCompleted,
            agreedByReceiver: status == .agreed || isSettledCompleted,
            approvedBySender: isSettledCompleted,
            approvedByReceiver: isSettledCompleted,
            completedAt: isSettledCompleted ? createdAt.addingTimeInterval(600) : nil,
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
