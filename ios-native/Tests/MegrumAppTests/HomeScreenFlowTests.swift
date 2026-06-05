@testable import MegrumApp
import MegrumCore
import XCTest

final class HomeScreenFlowTests: XCTestCase {
    func testMatchedShelfRoutesToRelationScreen() {
        XCTAssertEqual(
            HomeGoodsPanelRouteResolver.destination(for: .matched),
            .relation(.perfect)
        )
    }

    func testPossibleShelfRoutesToRelationScreenAsOneWayCandidate() {
        XCTAssertEqual(
            HomeGoodsPanelRouteResolver.destination(for: .possible),
            .relation(.forward)
        )
    }

    func testVisualQAPreviewModeParsesInitialScreens() {
        XCTAssertEqual(
            VisualQAPreviewMode.initialScreen(
                environment: ["MEGRUM_VISUAL_QA_INITIAL_SCREEN": "match-relation"]
            ),
            .matchRelation
        )
        XCTAssertEqual(
            VisualQAPreviewMode.initialScreen(
                environment: ["MEGRUM_VISUAL_QA_INITIAL_SCREEN": "match-relation-candidates"]
            ),
            .matchRelationCandidates
        )
        XCTAssertEqual(
            VisualQAPreviewMode.initialScreen(
                environment: ["MEGRUM_VISUAL_QA_INITIAL_SCREEN": " drawer-open "]
            ),
            .drawerOpen
        )
        XCTAssertEqual(
            VisualQAPreviewMode.initialScreen(
                environment: ["MEGRUM_VISUAL_QA_INITIAL_SCREEN": "proposal-meetup"]
            ),
            .proposalMeetup
        )
        XCTAssertEqual(
            VisualQAPreviewMode.initialScreen(
                environment: ["MEGRUM_VISUAL_QA_INITIAL_SCREEN": "proposal-give"]
            ),
            .proposalGive
        )
        XCTAssertEqual(
            VisualQAPreviewMode.initialScreen(
                environment: ["MEGRUM_VISUAL_QA_INITIAL_SCREEN": "proposal-receive"]
            ),
            .proposalReceive
        )
        XCTAssertEqual(
            VisualQAPreviewMode.initialScreen(
                environment: ["MEGRUM_VISUAL_QA_INITIAL_SCREEN": "proposal-meetup-month"]
            ),
            .proposalMeetupMonth
        )
        XCTAssertEqual(
            VisualQAPreviewMode.initialScreen(
                environment: ["MEGRUM_VISUAL_QA_INITIAL_SCREEN": "proposal-confirm"]
            ),
            .proposalConfirm
        )
        XCTAssertEqual(
            VisualQAPreviewMode.initialScreen(
                environment: ["MEGRUM_VISUAL_QA_INITIAL_SCREEN": "proposal-complete"]
            ),
            .proposalComplete
        )
        XCTAssertEqual(
            VisualQAPreviewMode.initialScreen(
                environment: ["MEGRUM_VISUAL_QA_INITIAL_SCREEN": "proposal-pending"]
            ),
            .proposalPending
        )
        XCTAssertNil(
            VisualQAPreviewMode.initialScreen(
                environment: ["MEGRUM_VISUAL_QA_INITIAL_SCREEN": "unknown"]
            )
        )
    }

    func testVisualQAProposalRouteResolverMapsDirectProposalScreensToSteps() {
        XCTAssertFalse(VisualQAProposalRouteResolver.shouldOpenProposalFlow(for: .home))
        XCTAssertFalse(VisualQAProposalRouteResolver.shouldOpenProposalFlow(for: .drawerOpen))
        XCTAssertFalse(VisualQAProposalRouteResolver.shouldOpenProposalFlow(for: .matchRelation))
        XCTAssertFalse(VisualQAProposalRouteResolver.shouldOpenProposalFlow(for: .matchRelationCandidates))
        XCTAssertFalse(VisualQAProposalRouteResolver.shouldOpenProposalFlow(for: .proposalPending))

        XCTAssertEqual(VisualQAProposalRouteResolver.initialStep(for: .proposalGive), .give)
        XCTAssertEqual(VisualQAProposalRouteResolver.initialStep(for: .proposalReceive), .receive)
        XCTAssertEqual(VisualQAProposalRouteResolver.initialStep(for: .proposalMeetup), .meetup)
        XCTAssertEqual(VisualQAProposalRouteResolver.initialStep(for: .proposalMeetupMonth), .meetup)
        XCTAssertEqual(VisualQAProposalRouteResolver.initialStep(for: .proposalConfirm), .confirm)
        XCTAssertEqual(VisualQAProposalRouteResolver.initialStep(for: .proposalComplete), .confirm)

        XCTAssertTrue(VisualQAProposalRouteResolver.shouldOpenProposalFlow(for: .proposalGive))
        XCTAssertTrue(VisualQAProposalRouteResolver.shouldOpenProposalFlow(for: .proposalReceive))
        XCTAssertTrue(VisualQAProposalRouteResolver.shouldOpenProposalFlow(for: .proposalMeetup))
        XCTAssertTrue(VisualQAProposalRouteResolver.shouldOpenProposalFlow(for: .proposalConfirm))
        XCTAssertNil(VisualQAProposalRouteResolver.initialStep(for: nil))
    }

    func testVisualQAProposalRoutesRenderDirectRootToAvoidModalTransitionScreenshots() {
        XCTAssertTrue(VisualQAProposalRouteResolver.shouldRenderDirectRoot(for: .proposalGive))
        XCTAssertTrue(VisualQAProposalRouteResolver.shouldRenderDirectRoot(for: .proposalReceive))
        XCTAssertTrue(VisualQAProposalRouteResolver.shouldRenderDirectRoot(for: .proposalMeetup))
        XCTAssertTrue(VisualQAProposalRouteResolver.shouldRenderDirectRoot(for: .proposalConfirm))
        XCTAssertTrue(VisualQAProposalRouteResolver.shouldRenderDirectRoot(for: .proposalComplete))

        XCTAssertFalse(VisualQAProposalRouteResolver.shouldRenderDirectRoot(for: .home))
        XCTAssertFalse(VisualQAProposalRouteResolver.shouldRenderDirectRoot(for: .matchRelation))
        XCTAssertFalse(VisualQAProposalRouteResolver.shouldRenderDirectRoot(for: .proposalPending))
    }

    func testVisualQARelationRoutesRenderDirectRootForStableScreenshots() {
        XCTAssertTrue(VisualQARelationRouteResolver.shouldRenderDirectRoot(for: .matchRelation))
        XCTAssertTrue(VisualQARelationRouteResolver.shouldRenderDirectRoot(for: .matchRelationCandidates))

        XCTAssertFalse(VisualQARelationRouteResolver.shouldRenderDirectRoot(for: .home))
        XCTAssertFalse(VisualQARelationRouteResolver.shouldRenderDirectRoot(for: .proposalGive))
        XCTAssertFalse(VisualQARelationRouteResolver.shouldRenderDirectRoot(for: .proposalPending))
    }

    func testVisualQATabRouteResolverCanOpenPendingTradesAfterCompletion() {
        XCTAssertEqual(VisualQATabRouteResolver.initialTab(for: .proposalPending), .trades)
        XCTAssertEqual(VisualQATabRouteResolver.requestedTradesStage(for: .proposalPending), .pending)
        XCTAssertEqual(VisualQATabRouteResolver.initialTab(for: .proposalComplete), .home)
        XCTAssertNil(VisualQATabRouteResolver.requestedTradesStage(for: .proposalComplete))
    }

    func testVisualQAProposalRoutePrefersPartnerOwnedGoods() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let ownItem = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            ownerID: viewerID,
            title: "自分のグッズ"
        )
        let partnerItem = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
            ownerID: partnerID,
            title: "相手のグッズ"
        )

        XCTAssertEqual(
            VisualQAProposalRouteResolver.targetItem(
                candidates: [ownItem, partnerItem],
                viewerID: viewerID
            )?.id,
            partnerItem.id
        )
    }

    func testHomeRelationVisualQARoutePrefersPartnerOwnedGoods() {
        let viewerID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let partnerID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let ownItem = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000201")!,
            ownerID: viewerID,
            title: "自分のグッズ"
        )
        let partnerItem = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000202")!,
            ownerID: partnerID,
            title: "相手のグッズ"
        )

        XCTAssertEqual(
            HomeRelationVisualQARouteResolver.targetItem(
                candidates: [ownItem, partnerItem],
                viewerID: viewerID
            )?.id,
            partnerItem.id
        )
        XCTAssertEqual(
            HomeRelationVisualQARouteResolver.targetItem(
                candidates: [ownItem],
                viewerID: viewerID
            )?.id,
            ownItem.id
        )
    }

    func testHomeCandidateTileStyleUsesRnLikeMemberLettersAndTagLine() {
        let item = GoodsItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000301")!,
            ownerID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            title: "スア ラキドロ",
            tags: [
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000401")!, name: "春ver."),
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000402")!, name: "同種優先"),
                GoodsTag(id: UUID(uuidString: "00000000-0000-0000-0000-000000000403")!, name: "会場限定")
            ]
        )

        XCTAssertEqual(HomeCandidateTileStyle.letter(for: item), "S")
        XCTAssertEqual(HomeCandidateTileStyle.tagLine(for: item), "# 春ver. # 同種優先")
    }

    func testHomeCandidateGridUsesRnLikeThreeColumnWrapMetrics() {
        XCTAssertEqual(HomeLayoutMetrics.horizontalPadding, 18)
        XCTAssertEqual(HomeCandidateGridMetrics.columnCount, 3)
        XCTAssertEqual(HomeCandidateGridMetrics.spacing, 10)
        XCTAssertEqual(HomeCandidateGridMetrics.cardHeightRatio, 1.34)
        XCTAssertEqual(HomeCandidateGridMetrics.localAuraCornerRadius, 22)
        XCTAssertEqual(HomeCandidateGridMetrics.localAuraOutset, 5)
        XCTAssertEqual(HomeCandidateGridMetrics.localAuraShadowRadius, 18)
        XCTAssertEqual(HomeCandidateGridMetrics.tagFontSize, 9)
        XCTAssertEqual(HomeCandidateGridMetrics.tagHorizontalPadding, 6)
        XCTAssertEqual(HomeCandidateGridMetrics.tagVerticalPadding, 3)
        XCTAssertEqual(HomeCandidateGridMetrics.liveTopOffset, 31)
        XCTAssertEqual(HomeCandidateGridMetrics.fakeImageGlowSize, 58)
        XCTAssertEqual(HomeCandidateGridMetrics.fakeImageGlowOffsetX, 17)
        XCTAssertEqual(HomeCandidateGridMetrics.fakeImageGlowOffsetY, -12)
        XCTAssertEqual(HomeCandidateGridMetrics.fakeImageLetterFontSize, 32)
        XCTAssertEqual(HomeCandidateGridMetrics.fakeImageLetterShadowRadius, 5)
        XCTAssertEqual(
            HomeCandidateGridMetrics.tileWidth(containerWidth: 366),
            115.33,
            accuracy: 0.01
        )
        XCTAssertEqual(
            HomeCandidateGridMetrics.cardHeight(tileWidth: 115.33),
            154.54,
            accuracy: 0.01
        )
    }

    func testHomeCandidatePriorityFrameUsesRnLikeBothAndOneSideMetrics() {
        XCTAssertEqual(HomeCandidatePriorityFrameMetrics.bothBorderWidth, 2)
        XCTAssertEqual(HomeCandidatePriorityFrameMetrics.bothBorderOpacity, 0.72)
        XCTAssertEqual(HomeCandidatePriorityFrameMetrics.bothShadowOpacity, 0.22)
        XCTAssertEqual(HomeCandidatePriorityFrameMetrics.bothShadowRadius, 16)
        XCTAssertEqual(HomeCandidatePriorityFrameMetrics.bothShadowY, 8)
        XCTAssertEqual(HomeCandidatePriorityFrameMetrics.oneSideBorderWidth, 1.5)
        XCTAssertEqual(HomeCandidatePriorityFrameMetrics.oneSideBorderOpacity, 0.78)
        XCTAssertEqual(HomeCandidatePriorityFrameMetrics.oneSideShadowOpacity, 0.18)
        XCTAssertEqual(HomeCandidatePriorityFrameMetrics.oneSideShadowRadius, 12)
        XCTAssertEqual(HomeCandidatePriorityFrameMetrics.oneSideShadowY, 7)

        XCTAssertEqual(HomeCandidatePriorityFrameStyle.style(for: .matched).borderWidth, 2)
        XCTAssertEqual(HomeCandidatePriorityFrameStyle.style(for: .possible).borderWidth, 1.5)
    }

    func testPreviewHomeCandidatesStartWithPartnerGoodsForGoodsPanelEntry() {
        let firstMatched = NativePreviewData.homeMatchedItems.first

        XCTAssertEqual(firstMatched?.ownerID, NativePreviewData.partnerID)
        XCTAssertEqual(HomeCandidateTileStyle.letter(for: firstMatched!), "S")
    }
}
