@testable import MegrumApp
import CoreGraphics
import MegrumCore
import MegrumDesign
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

    func testHomeDoesNotShowGroomRail() {
        XCTAssertFalse(HomeGroomRailPolicy.isVisibleOnHome)
    }

    func testMutualMatchEmptyStatePromptsListingCreationWhenNoListingsExist() {
        let presentation = HomeMutualMatchEmptyStatePresentation(listingCount: 0)

        XCTAssertEqual(presentation.title, "個別募集を作成しましょう")
        XCTAssertEqual(
            presentation.message,
            "個別募集を1件も作っていないので、譲れるものと欲しいものを設定してみましょう。"
        )
        XCTAssertEqual(presentation.buttonTitle, "個別募集を作成")
    }

    func testMutualMatchEmptyStateShowsExistingListingCountAndEncouragesMoreSettings() {
        let presentation = HomeMutualMatchEmptyStatePresentation(listingCount: 3)

        XCTAssertEqual(presentation.title, "個別募集を3件作成中")
        XCTAssertEqual(
            presentation.message,
            "今作成中の個別募集は3件です。譲るものや欲しい条件をもっと設定すると、相互マッチが増えやすくなります。"
        )
        XCTAssertEqual(presentation.buttonTitle, "個別募集を追加")
    }

    func testNativePreviewHomeCandidatesUseBundledGoodsImages() throws {
        let imageURLs = NativePreviewData.homeMatchedItems.compactMap(\.imageURL)
        XCTAssertGreaterThanOrEqual(imageURLs.count, 8)

        let firstImageURL = try XCTUnwrap(imageURLs.first)
        XCTAssertTrue(firstImageURL.isFileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: firstImageURL.path))
    }

    func testNativePreviewHavesRailStartsFromViewerGoods() {
        let firstPossible = NativePreviewData.homePossibleItems.first

        XCTAssertEqual(firstPossible?.ownerID, NativePreviewData.viewerID)
        XCTAssertNotNil(firstPossible?.imageURL)
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
                environment: ["MEGRUM_VISUAL_QA_INITIAL_SCREEN": "home-haves-lookup"]
            ),
            .homeHavesLookup
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
        XCTAssertEqual(HomeLayoutMetrics.fixedHeaderTopPadding, 12)
        XCTAssertEqual(HomeLayoutMetrics.fixedHeaderBottomPadding, 12)
        XCTAssertEqual(HomeLayoutMetrics.fixedHeaderAvatarSize, 44)
        XCTAssertEqual(HomeLayoutMetrics.fixedHeaderInitialFontSize, 20)
        XCTAssertEqual(HomeLayoutMetrics.fixedHeaderTitleFontSize, 24)
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

    func testFloatingActionsSitJustAboveFooter() {
        XCTAssertEqual(FloatingActionLayoutMetrics.leadingPadding, 24)
        XCTAssertEqual(FloatingActionLayoutMetrics.bottomGapAboveFooter, 12)
        XCTAssertEqual(FloatingActionLayoutMetrics.homeSearchBottomPadding, FloatingActionLayoutMetrics.bottomGapAboveFooter)
        XCTAssertEqual(FloatingActionLayoutMetrics.contentBottomPadding, 104)
    }

    func testTabBarTitleIsLiftedAboveGlassFooter() {
        XCTAssertEqual(MegrumTabBarLayoutMetrics.titleVerticalAdjustment, -4)
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

    func testHomeDiscoveryPrimaryTabsUseRequestedCopy() {
        XCTAssertEqual(HomeDiscoveryPrimaryTab.candidates.title, "マッチ候補")
        XCTAssertEqual(HomeDiscoveryPrimaryTab.mutual.title, "相互マッチ(β版)")
        XCTAssertEqual(HomeDiscoveryPrimaryTab.allCases.map(\.title), ["マッチ候補", "相互マッチ(β版)"])
        XCTAssertEqual(HomeDiscoveryPrimaryTab.allCases.map(\.index), [0, 1])
    }

    func testHomeDiscoveryTopTabsUseTimelineLikeBarMetrics() {
        XCTAssertEqual(HomeDiscoveryTabSwitcherMetrics.itemSpacing, 32)
        XCTAssertEqual(HomeDiscoveryTabSwitcherMetrics.fontSize, 17)
        XCTAssertEqual(HomeDiscoveryTabSwitcherMetrics.underlineHeight, 4)
        XCTAssertEqual(HomeDiscoveryTabSwitcherMetrics.totalBottomPadding, 19)
    }

    func testHomeDiscoveryTabIndicatorInterpolatesAcrossLabelFrames() throws {
        let frames: [HomeDiscoveryPrimaryTab: CGRect] = [
            .candidates: CGRect(x: 20, y: 0, width: 68, height: 24),
            .mutual: CGRect(x: 120, y: 0, width: 128, height: 24)
        ]

        let halfway = try XCTUnwrap(
            HomeDiscoveryTabIndicatorFrame.interpolated(
                progress: 0.5,
                frames: frames
            )
        )

        XCTAssertEqual(halfway.minX, 70)
        XCTAssertEqual(halfway.width, 98)
    }

    func testMutualMatchShellDoesNotInventCandidatesWithoutData() {
        let candidates = HomeMutualMatchCandidateFactory.candidates(
            viewerID: NativePreviewData.viewerID,
            inventoryItems: [],
            matchedItems: [],
            possibleItems: [],
            goodsTypes: [],
            conditionSignalsByItemID: [:]
        )

        XCTAssertTrue(candidates.isEmpty)
    }

    func testMutualMatchFactoryUsesOnlyExplicitMutualMatchData() {
        let candidates = HomeMutualMatchCandidateFactory.candidates(
            mutualMatchData: [explicitMutualMatchCandidateData()],
            viewerID: NativePreviewData.viewerID,
            inventoryItems: [],
            matchedItems: [],
            possibleItems: [],
            goodsTypes: [],
            conditionSignalsByItemID: [:]
        )

        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(candidates.first?.partnerGoodsItems.first?.title, "相手が譲る サナ")
        XCTAssertEqual(candidates.first?.viewerGoodsItems.first?.title, "自分が譲る モモ")
        XCTAssertEqual(candidates.first?.partnerGoodsItems.count, 2)
        XCTAssertEqual(candidates.first?.viewerGoodsItems.count, 2)
        XCTAssertEqual(candidates.first?.requestedGoodsBadgeTitle, "セット")
        XCTAssertEqual(candidates.first?.offeredGoodsBadgeTitle, "どれか1つ")
        XCTAssertEqual(candidates.flatMap(\.attentionTags).map(\.title).contains("タグ不一致？"), true)
        XCTAssertEqual(candidates.flatMap(\.attentionTags).map(\.title).contains("金額込み候補"), true)
        XCTAssertEqual(candidates.first?.partnerMetaText, "東京都 ・ 20代 ・ 評価12件 ★4.8")
        XCTAssertFalse(candidates.first?.partnerMetaText.contains("サナ推し") == true)
    }

    func testMutualMatchGoodsLogicBadgeOnlyAppearsForMultipleItems() {
        XCTAssertNil(HomeMutualMatchGoodsLogicBadgePolicy.badgeTitle(logic: .all, itemCount: 1))
        XCTAssertNil(HomeMutualMatchGoodsLogicBadgePolicy.badgeTitle(logic: .one, itemCount: 0))
        XCTAssertEqual(HomeMutualMatchGoodsLogicBadgePolicy.badgeTitle(logic: .all, itemCount: 2), "セット")
        XCTAssertEqual(HomeMutualMatchGoodsLogicBadgePolicy.badgeTitle(logic: .one, itemCount: 2), "どれか1つ")
    }

    func testMutualMatchCashCompatibilityPolicyUsesFixedPriceAndSpecifiedAmountRules() {
        XCTAssertEqual(
            HomeMutualMatchCashCompatibilityPolicy.compatibility(
                requestedAmount: nil,
                counterpartAmount: nil
            ),
            .matched
        )
        XCTAssertEqual(
            HomeMutualMatchCashCompatibilityPolicy.compatibility(
                requestedAmount: nil,
                counterpartAmount: 1_500
            ),
            .amountIncluded
        )
        XCTAssertEqual(
            HomeMutualMatchCashCompatibilityPolicy.compatibility(
                requestedAmount: 1_500,
                counterpartAmount: nil
            ),
            .amountIncluded
        )
        XCTAssertEqual(
            HomeMutualMatchCashCompatibilityPolicy.compatibility(
                requestedAmount: 1_500,
                counterpartAmount: 1_800
            ),
            .matched
        )
        XCTAssertEqual(
            HomeMutualMatchCashCompatibilityPolicy.compatibility(
                requestedAmount: 1_500,
                counterpartAmount: 1_200
            ),
            .amountInsufficient
        )
    }

    func testMutualMatchPairsOpenGoodsHitSheetsWithPreferredOffer() throws {
        let candidates = HomeMutualMatchCandidateFactory.candidates(
            mutualMatchData: [explicitMutualMatchCandidateData()],
            viewerID: NativePreviewData.viewerID,
            inventoryItems: [],
            matchedItems: [],
            possibleItems: [],
            goodsTypes: [],
            conditionSignalsByItemID: [:]
        )
        let firstCandidate = try XCTUnwrap(candidates.first)
        let pairs = HomeMutualMatchProposalPairFactory.pairs(
            for: firstCandidate,
            in: candidates,
            goodsTypes: []
        )
        let firstPair = try XCTUnwrap(pairs.first)

        XCTAssertEqual(pairs.count, 2)
        XCTAssertEqual(firstPair.receiverGoods.title, "相手が譲る サナ")
        XCTAssertEqual(firstPair.senderGoods.title, "自分が譲る モモ")

        guard case .goodsHit(let payload) = firstPair.sheet else {
            return XCTFail("相互マッチの候補は個別募集Hitの詳細シートへ進む必要があります")
        }
        XCTAssertEqual(payload.goods.id, firstPair.receiverGoods.id)
        XCTAssertEqual(payload.preferredOfferGoodsID, firstPair.senderGoods.id)
    }

    func testMutualMatchPairsPreferCashDisplayItemsOverFallbackGoods() throws {
        var cashData = explicitMutualMatchCandidateData()
        cashData.partnerDisplayItems = [
            HomeMutualMatchDisplayItemData.cash(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000081")!,
                amount: 2_000
            )
        ]
        cashData.viewerDisplayItems = [
            HomeMutualMatchDisplayItemData.cash(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000082")!,
                amount: 1_500
            )
        ]

        let candidate = try XCTUnwrap(
            HomeMutualMatchCandidateFactory.candidates(
                mutualMatchData: [cashData],
                viewerID: NativePreviewData.viewerID,
                inventoryItems: [],
                matchedItems: [],
                possibleItems: [],
                goodsTypes: [],
                conditionSignalsByItemID: [:]
            ).first
        )
        let pair = try XCTUnwrap(
            HomeMutualMatchProposalPairFactory.pairs(
                for: candidate,
                in: [candidate],
                goodsTypes: []
            ).first
        )

        XCTAssertEqual(pair.receiverDisplayItem.title, "¥2,000")
        XCTAssertEqual(pair.receiverDisplayItem.data.kind, .cashAmount)
        XCTAssertNil(pair.receiverDisplayItem.goods)
        XCTAssertEqual(pair.senderDisplayItem.title, "¥1,500")
        XCTAssertEqual(pair.proposalCashAmount, 1_500)
        XCTAssertEqual(pair.receiverGoods.title, "相手が譲る サナ")
    }

    func testMutualMatchProposalExchangeMethodUsesCandidateSignals() {
        let bothSignals = HomeDiscoveryFixtures.miiListingHitSignals(index: 0)
        XCTAssertEqual(
            HomeProposalExchangeMethodPolicy.preferredExchangeMethod(for: bothSignals),
            bothSignals.exchange.localExchangeSelected && bothSignals.exchange.postalAcceptedByBoth ? .both : .hand
        )
    }

    func testMutualMatchConditionReviewShowsFullMatchForLocalExchange() {
        let review = mutualMatchReview(
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: false,
                localExchangeSelected: true,
                prefectureMatches: true,
                dateMatches: true
            ),
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: true)
        )

        XCTAssertEqual(review.exchangeItems.map(\.title), ["全一致"])
        XCTAssertEqual(review.exchangeItems.map(\.status), [.matched])
        XCTAssertEqual(review.paymentItems.map(\.title), ["物々交換なら確認不要"])
        XCTAssertEqual(review.paymentItems.map(\.status), [.skipped])
    }

    func testMutualMatchConditionReviewSeparatesLocalPlaceAndDateConcerns() {
        let review = mutualMatchReview(
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: false,
                localExchangeSelected: true,
                prefectureMatches: false,
                dateMatches: false
            ),
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: true)
        )

        XCTAssertEqual(
            review.exchangeItems.map(\.title),
            ["都道府県の確認が必要", "日程調整が必要"]
        )
        XCTAssertEqual(review.exchangeItems.map(\.status), [.needsDecision, .needsDecision])
    }

    func testMutualMatchConditionReviewUsesPostalFallbackBeforeLocalConcerns() {
        let review = mutualMatchReview(
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: true,
                localExchangeSelected: true,
                prefectureMatches: false,
                dateMatches: false
            ),
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: true)
        )

        XCTAssertEqual(
            review.exchangeItems.map(\.title),
            ["郵送交換で成立可能", "都道府県の確認が必要", "日程調整が必要"]
        )
        XCTAssertEqual(review.exchangeItems.map(\.status), [.matched, .needsDecision, .needsDecision])
    }

    func testMutualMatchConditionReviewShowsExchangeMethodMismatch() {
        let review = mutualMatchReview(
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: false,
                localExchangeSelected: false,
                prefectureMatches: false,
                dateMatches: false
            ),
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: true)
        )

        XCTAssertEqual(review.exchangeItems.map(\.title), ["交換手段が不一致"])
        XCTAssertEqual(review.exchangeItems.map(\.status), [.mismatch])
    }

    func testMutualMatchConditionReviewChecksPaymentOnlyForCashOptions() {
        let compatible = mutualMatchReview(
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: false,
                localExchangeSelected: true,
                prefectureMatches: true,
                dateMatches: true
            ),
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: true),
            includesCash: true
        )
        XCTAssertEqual(compatible.paymentItems.map(\.title), ["全一致"])
        XCTAssertEqual(compatible.paymentItems.map(\.status), [.matched])

        let needsDecision = mutualMatchReview(
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: false,
                localExchangeSelected: true,
                prefectureMatches: true,
                dateMatches: true
            ),
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: false),
            includesCash: true
        )
        XCTAssertEqual(needsDecision.paymentItems.map(\.title), ["支払方法不一致"])
        XCTAssertEqual(needsDecision.paymentItems.map(\.status), [.mismatch])
    }

    func testMutualMatchConditionReviewPointsExposeTagsAndCounterpartValues() {
        let exchange = HomeExchangeConditionSignals(
            postalAcceptedByBoth: false,
            localExchangeSelected: false,
            prefectureMatches: false,
            dateMatches: false,
            viewerExchangeMethodTitle: "現地交換",
            partnerExchangeMethodTitle: "郵送交換",
            viewerLocalConditionText: "東京都 / 東京ドーム / 6/28",
            partnerLocalConditionText: "対象外",
            viewerShippingFeeTitle: "対象外",
            partnerShippingFeeTitle: "送料 自己負担 / 発送 2〜4日以内"
        )
        let payment = HomePaymentConditionSignals(
            hasCompatiblePaymentMethod: false,
            requiresPayment: true,
            status: .methodMismatch,
            viewerMethods: [.paypay],
            partnerMethods: [.bankTransfer]
        )
        let pair = mutualMatchPair(
            exchange: exchange,
            payment: payment,
            receiverDisplayItem: HomeMutualMatchProposalItem(
                data: .cash(
                    id: UUID(uuidString: "10000000-0000-0000-0000-000000000611")!,
                    amount: 2_000
                ),
                goods: nil
            ),
            senderDisplayItem: HomeMutualMatchProposalItem(
                data: .cash(
                    id: UUID(uuidString: "10000000-0000-0000-0000-000000000612")!,
                    amount: 1_500
                ),
                goods: nil
            )
        )
        let review = HomeMutualMatchConditionReviewPolicy.review(for: pair)
        let points = HomeMutualMatchConditionReviewPointPolicy.points(for: pair, review: review)

        XCTAssertEqual(points.map(\.title), ["交換条件", "現地交換条件", "郵送交換条件", "金額条件", "支払条件"])
        XCTAssertEqual(points[0].tagTitle, "交換条件不一致")
        XCTAssertEqual(points[0].partnerValue, "郵送交換")
        XCTAssertEqual(points[0].viewerValue, "現地交換")
        XCTAssertEqual(points[3].tagTitle, "金額不足")
        XCTAssertEqual(points[3].partnerValue, "¥2,000")
        XCTAssertEqual(points[3].viewerValue, "¥1,500")
        XCTAssertEqual(points[4].tagTitle, "支払方法不一致")
        XCTAssertEqual(points[4].partnerValue, "銀行振込")
        XCTAssertEqual(points[4].viewerValue, "PayPay")
    }

    func testMutualMatchConditionReviewPointsSkipAmountAndPaymentForGoodsOnly() {
        let pair = mutualMatchPair(
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: false,
                localExchangeSelected: true,
                prefectureMatches: true,
                dateMatches: true,
                viewerExchangeMethodTitle: "現地交換",
                partnerExchangeMethodTitle: "現地交換",
                viewerLocalConditionText: "東京都 / 相談 / 相談して決める",
                partnerLocalConditionText: "東京都 / 相談 / 相談して決める"
            ),
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: true)
        )
        let review = HomeMutualMatchConditionReviewPolicy.review(for: pair)
        let points = HomeMutualMatchConditionReviewPointPolicy.points(for: pair, review: review)

        XCTAssertEqual(points[3].title, "金額条件")
        XCTAssertEqual(points[3].tagTitle, "ー")
        XCTAssertEqual(points[3].partnerValue, "")
        XCTAssertEqual(points[3].viewerValue, "")
        XCTAssertEqual(points[4].title, "支払条件")
        XCTAssertEqual(points[4].tagTitle, "ー")
        XCTAssertEqual(points[4].partnerValue, "")
        XCTAssertEqual(points[4].viewerValue, "")
    }

    func testMutualMatchConditionReviewPointsShowDateNeedsDiscussionForFlexibleSchedule() {
        let pair = mutualMatchPair(
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: false,
                localExchangeSelected: true,
                prefectureMatches: true,
                dateMatches: true,
                dateNeedsDiscussion: true,
                viewerExchangeMethodTitle: "現地交換",
                partnerExchangeMethodTitle: "現地交換",
                viewerLocalConditionText: "東京都 / 東京ドーム / 相談して決める",
                partnerLocalConditionText: "東京都 / 東京ドーム / 6/28 18:00"
            ),
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: true)
        )
        let review = HomeMutualMatchConditionReviewPolicy.review(for: pair)
        let points = HomeMutualMatchConditionReviewPointPolicy.points(for: pair, review: review)

        XCTAssertEqual(review.exchangeItems.map(\.title), ["日程調整が必要"])
        XCTAssertEqual(points[0].title, "交換条件")
        XCTAssertEqual(points[0].tagTitle, "OK")
        XCTAssertEqual(points[0].status, .matched)
        XCTAssertEqual(points[1].title, "現地交換条件")
        XCTAssertEqual(points[1].tagTitle, "日程要相談")
        XCTAssertEqual(points[1].status, .needsDecision)
        XCTAssertEqual(points[1].partnerValue, "東京都 / 東京ドーム / 6/28 18:00")
        XCTAssertEqual(points[1].viewerValue, "東京都 / 東京ドーム / 日程は相談")
    }

    func testMutualMatchConditionReviewPointsHideBlankPlaceMemo() {
        let pair = mutualMatchPair(
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: false,
                localExchangeSelected: true,
                prefectureMatches: true,
                dateMatches: true,
                dateNeedsDiscussion: true,
                viewerExchangeMethodTitle: "現地交換",
                partnerExchangeMethodTitle: "現地交換",
                viewerLocalConditionText: "東京都 / 場所相談 / 相談して決める",
                partnerLocalConditionText: "東京都 / 東京ドーム / 6/28 18:00"
            ),
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: true)
        )
        let review = HomeMutualMatchConditionReviewPolicy.review(for: pair)
        let points = HomeMutualMatchConditionReviewPointPolicy.points(for: pair, review: review)

        XCTAssertEqual(points[1].tagTitle, "日程要相談")
        XCTAssertEqual(points[1].viewerValue, "東京都 / 日程は相談")
        XCTAssertFalse(points[1].viewerValue.contains("場所相談"))
    }

    func testMutualMatchConditionReviewPointRenamesPrefectureDiscussionForDisplay() {
        let exchange = HomeExchangeConditionSignals(
            postalAcceptedByBoth: false,
            localExchangeSelected: true,
            prefectureMatches: false,
            dateMatches: true,
            viewerLocalConditionText: "東京都 / 6/28",
            partnerLocalConditionText: "大阪府 / 6/28"
        )
        let pair = mutualMatchPair(
            exchange: exchange,
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: true)
        )
        let review = HomeMutualMatchConditionReviewPolicy.review(for: pair)
        let points = HomeMutualMatchConditionReviewPointPolicy.points(for: pair, review: review)

        XCTAssertEqual(points.first { $0.title == "現地交換条件" }?.tagTitle, "交換場所要相談")
        XCTAssertEqual(HomeMutualMatchAttentionTag.prefectureNeedsDiscussion.title, "交換場所要相談")
    }

    func testMutualMatchPanelAttentionTagsUseConditionReviewColors() {
        XCTAssertEqual(HomeMutualMatchAttentionTag.ready.tint, MegrumTheme.ok)
        XCTAssertEqual(HomeMutualMatchAttentionTag.tagMismatch.tint, MegrumTheme.conditionPossible)
        XCTAssertEqual(HomeMutualMatchAttentionTag.amountIncluded.tint, MegrumTheme.conditionPossible)
        XCTAssertEqual(HomeMutualMatchAttentionTag.shippingFeeNeedsDiscussion.tint, MegrumTheme.conditionPossible)
        XCTAssertEqual(HomeMutualMatchAttentionTag.paymentMethodNeedsDiscussion.tint, MegrumTheme.conditionPossible)
    }

    func testMutualMatchDetailEmptyOtherCandidatesCopy() {
        XCTAssertEqual(
            HomeOtherExchangeCopy.noOtherExchangeCandidates,
            "他に交換できそうなものはありません"
        )
    }

    func testMutualMatchConditionReviewPointsDoNotMarkLocalConditionOKWhenLocalRouteIsNotSelected() {
        let pair = mutualMatchPair(
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: true,
                localExchangeSelected: false,
                prefectureMatches: true,
                dateMatches: true,
                viewerExchangeMethodTitle: "郵送交換",
                partnerExchangeMethodTitle: "どちらもOK",
                viewerLocalConditionText: nil,
                partnerLocalConditionText: "大阪府 / 相談して決める",
                viewerShippingFeeTitle: "送料 自己負担 / 発送 2〜4日以内",
                partnerShippingFeeTitle: "送料 要相談 / 発送 2〜4日以内"
            ),
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: true)
        )
        let review = HomeMutualMatchConditionReviewPolicy.review(for: pair)
        let points = HomeMutualMatchConditionReviewPointPolicy.points(for: pair, review: review)

        XCTAssertEqual(points[0].title, "交換条件")
        XCTAssertEqual(points[0].tagTitle, "郵送交換")
        XCTAssertEqual(points[0].status, .matched)
        XCTAssertEqual(points[1].title, "現地交換条件")
        XCTAssertEqual(points[1].tagTitle, "ー")
        XCTAssertEqual(points[1].status, .skipped)
        XCTAssertEqual(points[1].partnerValue, "")
        XCTAssertEqual(points[1].viewerValue, "")
    }

    func testMutualMatchConditionReviewPointsResolveBothAndLocalToLocalExchange() {
        let pair = mutualMatchPair(
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: false,
                localExchangeSelected: true,
                prefectureMatches: true,
                dateMatches: true,
                viewerExchangeMethodTitle: "現地交換",
                partnerExchangeMethodTitle: "どちらもOK",
                viewerLocalConditionText: "東京都 / 東京ドーム / 6/28",
                partnerLocalConditionText: "東京都 / 東京ドーム / 6/28"
            ),
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: true)
        )
        let review = HomeMutualMatchConditionReviewPolicy.review(for: pair)
        let points = HomeMutualMatchConditionReviewPointPolicy.points(for: pair, review: review)

        XCTAssertEqual(points[0].title, "交換条件")
        XCTAssertEqual(points[0].tagTitle, "現地交換")
        XCTAssertEqual(points[0].status, .matched)
        XCTAssertEqual(points[1].title, "現地交換条件")
        XCTAssertEqual(points[1].tagTitle, "OK")
        XCTAssertEqual(points[2].title, "郵送交換条件")
        XCTAssertEqual(points[2].tagTitle, "ー")
        XCTAssertEqual(points[2].status, .skipped)
        XCTAssertEqual(points[2].partnerValue, "")
        XCTAssertEqual(points[2].viewerValue, "")
    }

    func testMutualMatchConditionReviewPointsShowDiscussionForBothExchangeMethod() {
        let pair = mutualMatchPair(
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: false,
                localExchangeSelected: true,
                prefectureMatches: true,
                dateMatches: true,
                viewerExchangeMethodTitle: "どちらもOK",
                partnerExchangeMethodTitle: "どちらもOK",
                viewerLocalConditionText: "東京都 / 東京ドーム / 6/28 18:00",
                partnerLocalConditionText: "東京都 / 東京ドーム / 6/28 18:00"
            ),
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: true)
        )
        let review = HomeMutualMatchConditionReviewPolicy.review(for: pair)
        let points = HomeMutualMatchConditionReviewPointPolicy.points(for: pair, review: review)

        XCTAssertEqual(points[0].title, "交換条件")
        XCTAssertEqual(points[0].tagTitle, "要相談")
        XCTAssertEqual(points[0].status, .needsDecision)
    }

    private func explicitMutualMatchCandidateData() -> HomeMutualMatchCandidateData {
        let signals = HomeCandidateConditionSignals(
            goods: HomeGoodsConditionSignals(
                hasIndividualListingHit: true,
                hasWishHit: false
            ),
            exchange: HomeExchangeConditionSignals(
                postalAcceptedByBoth: true,
                localExchangeSelected: true,
                prefectureMatches: true,
                dateMatches: true
            ),
            payment: HomePaymentConditionSignals(hasCompatiblePaymentMethod: true),
            linkCounts: HomeCandidateLinkCounts(
                wishCount: 0,
                listingCount: 1
            ),
            individualListingSelection: HomeIndividualListingSelectionContext(
                wantedLogic: .one,
                offeredLogic: .all,
                wantedOptions: []
            ),
            matchesViewerWish: true,
            tagMatchCount: 0
        )
        let partnerItems = [
            GoodsItem(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000071")!,
                ownerID: NativePreviewData.partnerID,
                title: "相手が譲る サナ"
            ),
            GoodsItem(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000072")!,
                ownerID: NativePreviewData.partnerID,
                title: "相手が譲る ミナ"
            )
        ]
        let viewerItems = [
            GoodsItem(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000073")!,
                ownerID: NativePreviewData.viewerID,
                title: "自分が譲る モモ"
            ),
            GoodsItem(
                id: UUID(uuidString: "10000000-0000-0000-0000-000000000074")!,
                ownerID: NativePreviewData.viewerID,
                title: "自分が譲る ジヒョ"
            )
        ]
        return HomeMutualMatchCandidateData(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000075")!,
            partnerID: NativePreviewData.partnerID,
            partnerName: "partner_trade",
            partnerHandle: "partner_trade",
            partnerInitial: "P",
            partnerArea: "東京都",
            partnerOshiText: "サナ推し",
            partnerAgeRangeText: "20代",
            partnerEvaluationSummaryText: "評価12件 ★4.8",
            partnerGoodsItems: partnerItems,
            viewerGoodsItems: viewerItems,
            signals: signals,
            conditionSignalsByPartnerGoodsID: Dictionary(
                uniqueKeysWithValues: partnerItems.map { ($0.id, signals) }
            ),
            attentionKinds: [.tagMismatch, .amountIncluded]
        )
    }

    private func mutualMatchReview(
        exchange: HomeExchangeConditionSignals,
        payment: HomePaymentConditionSignals,
        includesCash: Bool = false
    ) -> HomeMutualMatchConditionReview {
        HomeMutualMatchConditionReviewPolicy.review(
            for: mutualMatchPair(exchange: exchange, payment: payment, includesCash: includesCash)
        )
    }

    private func mutualMatchPair(
        exchange: HomeExchangeConditionSignals,
        payment: HomePaymentConditionSignals,
        includesCash: Bool = false,
        receiverDisplayItem: HomeMutualMatchProposalItem = .goods(HomeDiscoveryFixtures.sanaBadge),
        senderDisplayItem: HomeMutualMatchProposalItem = .goods(HomeDiscoveryFixtures.momoFanmi)
    ) -> HomeMutualMatchProposalPair {
        let signals = HomeCandidateConditionSignals(
            goods: HomeGoodsConditionSignals(
                hasIndividualListingHit: true,
                hasWishHit: false
            ),
            exchange: exchange,
            payment: payment,
            individualListingSelection: HomeIndividualListingSelectionContext(
                wantedOptions: includesCash ? [
                    HomeIndividualListingWantedOption(
                        id: UUID(uuidString: "10000000-0000-0000-0000-000000000601")!,
                        listingID: UUID(uuidString: "10000000-0000-0000-0000-000000000602")!,
                        position: 0,
                        title: "定価",
                        kind: .cash
                    )
                ] : []
            )
        )
        return HomeMutualMatchProposalPair(
            id: "preview",
            receiverGoods: HomeDiscoveryFixtures.sanaBadge,
            senderGoods: HomeDiscoveryFixtures.momoFanmi,
            receiverDisplayItem: receiverDisplayItem,
            senderDisplayItem: senderDisplayItem,
            signals: signals
        )
    }
}
