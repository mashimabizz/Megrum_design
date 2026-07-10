import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct MegrumAuthenticatedTabContentView: View {
    @ObservedObject var appState: MegrumAppState
    @Binding var selectedTab: MegrumTab
    @Binding var showsSearch: Bool
    @Binding var requestedTradesStage: TradeStage?
    @Binding var publicProfileRoute: PublicProfileRoute?
    @Binding var homeSettingsRoute: HomeSettingsRoute?
    @Binding var requestedWishSection: WishCollectionSection?
    @Binding var pendingNotificationRouteIntent: NotificationRouteIntent?
    @Binding var isGroomViewerPresented: Bool
    @ObservedObject var tutorialCoordinator: TutorialTourCoordinator
    var adDisplayContext: AdDisplayContext
    var visualQAInitialScreen: VisualQAInitialScreen?
    var onOpenDrawer: () -> Void
    var onRequestInterstitial: (AdPlacement) -> Void
    @State private var homeSearchInitialCriteria: SearchInitialCriteria?
    @State private var homeRelationRoute: HomeRelationRoute?
    @State private var homeProposalRoute: HomeProposalRoute?
    @State private var tradeDetailRoute: TradeDetailRoute?
    @State private var meguriHomeResetToken = UUID()
    @State private var isShowingMeguriMessageInbox = false
    @State private var meguriMessageDetailRoute: MeguriMessagePeerRoute?
    @State private var meguriBoardThreadRoute: MeguriBoardThreadRoute?
    /// iter1226.421：圏内チャットルーム一覧（ホームすべて見る・めぐり右下アイコンから）。
    @State private var isShowingNearbyBoardList = false
    @State private var meguriUserProfileRoute: MeguriUserProfileRoute?
    @State private var didOpenVisualQAMeguriMessages = false
    @State private var meguriGroomViewerPost: GroomPost?
    @State private var meguriGroomViewerSourceAnchor: UnitPoint = .center
    /// FB(iter1226.402)：ビューアで辿るグルーム列の上書き（自分のグルーム閲覧は自分のグルームだけを渡す）。空なら appState.grooms。
    @State private var meguriGroomViewerSequence: [GroomPost] = []

    var body: some View {
        ZStack {
            tabs

            MegrumSlideItemPresentationOverlay(item: $homeRelationRoute) { route, dismiss in
                NavigationStack {
                    MatchRelationScreen(
                        appState: appState,
                        targetItem: route.item,
                        matchType: route.matchType,
                        visualQAInitialScreen: visualQAInitialScreen,
                        onCompletionAction: { action in
                            dismiss()
                            if action == .openTrades {
                                openTradesFromHomePresentation()
                            }
                        }
                    )
                }
            }
            .zIndex(88)

            MegrumSlideItemPresentationOverlay(item: $homeProposalRoute) { route, dismiss in
                NavigationStack {
                    ProposalCreateFlow(
                        appState: appState,
                        targetItem: route.item,
                        receiverGoodsIDs: route.receiverGoodsIDs,
                        initialSenderGoodsIDs: route.senderGoodsIDs,
                        matchType: route.matchType,
                        initialExchangeMethod: route.initialExchangeMethod,
                        initialMessage: route.initialMessage,
                        initialCashAmount: route.initialCashAmount,
                        initialShippingFee: route.initialShippingFee,
                        initialShippingDays: route.initialShippingDays,
                        initialStep: route.initialStep,
                        visualQAInitialScreen: visualQAInitialScreen,
                        onCompletionAction: { action in
                            dismiss()
                            if action == .openTrades {
                                openTradesFromHomePresentation()
                            }
                        }
                    )
                }
            }
            .zIndex(89)

            MegrumSlideBoolPresentationOverlay(isPresented: $showsSearch) { dismiss in
                NavigationStack {
                    SearchScreen(
                        appState: appState,
                        initialCriteria: homeSearchInitialCriteria,
                        adDisplayContext: adDisplayContext,
                        onRequestInterstitial: onRequestInterstitial,
                        onDismissRequest: dismiss
                    )
                }
            }
            .zIndex(90)

            TradeDetailSlidePresentationOverlay(
                detailRoute: $tradeDetailRoute,
                appState: appState,
                proposals: appState.proposals
            )
            .zIndex(100)

            MegrumSlideBoolPresentationOverlay(
                isPresented: $isShowingNearbyBoardList,
                backSwipeInteractionScope: .fullScreen
            ) { dismiss in
                MegrumDeferredContent(delayNanoseconds: MegrumDeferredContentDelay.slidePresentation) {
                    NavigationStack {
                        NearbyBoardListScreen(
                            appState: appState,
                            onClose: dismiss,
                            onOpenThread: { thread in
                                openMeguriBoardThread(
                                    MeguriBoardThreadRoute(thread: thread, selectedPrefecture: nil, coordinate: nil)
                                )
                            },
                            qaInitialOverlay: {
                                switch visualQAInitialScreen {
                                case .nearbyBoardFilter: .filter
                                case .nearbyBoardLocked: .lockedPopup
                                default: nil
                                }
                            }()
                        )
                    }
                }
            }
            .zIndex(108)

            MegrumSlideItemPresentationOverlay(
                item: $meguriBoardThreadRoute,
                backSwipeInteractionScope: .fullScreen
            ) { route, dismiss in
                MegrumDeferredContent(delayNanoseconds: MegrumDeferredContentDelay.slidePresentation) {
                    NavigationStack {
                        BoardThreadDetailScreen(
                            appState: appState,
                            thread: route.thread,
                            selectedPrefecture: route.selectedPrefecture,
                            coordinate: route.coordinate,
                            onClose: dismiss
                        )
                    }
                }
            }
            .zIndex(109)

            MegrumSlideBoolPresentationOverlay(
                isPresented: $isShowingMeguriMessageInbox,
                backSwipeInteractionScope: .fullScreen
            ) { dismiss in
                MegrumDeferredContent(delayNanoseconds: MegrumDeferredContentDelay.slidePresentation) {
                    MeguriMessageInboxScreen(
                        appState: appState,
                        visualQAInitialScreen: visualQAInitialScreen,
                        onClose: dismiss,
                        onOpenThread: openMeguriMessageThread
                    )
                }
            }
            .zIndex(110)

            MegrumSlideItemPresentationOverlay(
                item: $meguriMessageDetailRoute,
                backSwipeInteractionScope: .fullScreen
            ) { route, dismiss in
                MegrumDeferredContent(delayNanoseconds: MegrumDeferredContentDelay.slidePresentation) {
                    NavigationStack {
                        MeguriMessagesScreen(
                            appState: appState,
                            route: route,
                            onClose: dismiss,
                            onOpenUserProfile: openMeguriUserProfile
                        )
                    }
                }
            }
            .zIndex(111)

            MegrumSlideItemPresentationOverlay(
                item: $meguriUserProfileRoute,
                backSwipeInteractionScope: .fullScreen
            ) { route, dismiss in
                MegrumDeferredContent(delayNanoseconds: MegrumDeferredContentDelay.slidePresentation) {
                    NavigationStack {
                        MeguriUserProfileRouteScreen(
                            appState: appState,
                            userID: route.userID,
                            adDisplayContext: adDisplayContext,
                            onClose: dismiss,
                            onOpenMessage: { userID in
                                dismiss()
                                openMeguriMessageThread(peerID: userID)
                            }
                        )
                    }
                }
            }
            .zIndex(112)
        }
        .overlayPreferenceValue(TutorialAnchorPreferenceKey.self) { anchors in
            // GeometryReader ごと ignoresSafeArea して、アンカー解決・dim・吹き出しを
            // 同一のフルスクリーン座標系に揃える（内側だけ広げると切り抜きがズレる）。
            if let beat = tutorialCoordinator.currentBeat {
                GeometryReader { proxy in
                    TutorialTourOverlay(
                        beat: beat,
                        overallProgress: tutorialCoordinator.overallProgress,
                        canRetreat: tutorialCoordinator.canRetreat,
                        advanceTitle: tutorialCoordinator.isAtScopeEnd
                            ? (tutorialCoordinator.scope == .full ? "はじめる！" : "閉じる")
                            : "次へ",
                        anchorFrames: anchors.mapValues { proxy[$0] },
                        containerSize: proxy.size,
                        onAdvance: { tutorialCoordinator.advance() },
                        onRetreat: { tutorialCoordinator.retreat() },
                        onEndTour: { tutorialCoordinator.skip() },
                        onMeguriDemoTap: { appState.requestTutorialMeguriCallout() }
                    )
                }
                .ignoresSafeArea()
            }
        }
        .onAppear {
            openVisualQAMeguriMessagesIfNeeded()
            openVisualQANearbyBoardListIfNeeded()
            handlePendingNotificationRouteIntent(pendingNotificationRouteIntent)
        }
        .onChange(of: pendingNotificationRouteIntent) { _, intent in
            handlePendingNotificationRouteIntent(intent)
        }
        .onChange(of: isShowingMeguriMessageInbox) { _, newValue in
            if !newValue {
                meguriMessageDetailRoute = nil
            }
        }
        .onChange(of: meguriGroomViewerPost?.id) { _, groomID in
            isGroomViewerPresented = groomID != nil
        }
        .onDisappear {
            isGroomViewerPresented = false
        }
        .groomViewerImmersiveOverlay(
            item: $meguriGroomViewerPost,
            sourceAnchor: meguriGroomViewerSourceAnchor,
            onDismiss: dismissMeguriGroomViewer
        ) { groom, dismiss in
            GroomViewerScreen(
                grooms: meguriGroomViewerSequence.isEmpty ? appState.grooms : meguriGroomViewerSequence,
                initialGroom: groom,
                appState: appState,
                onDismiss: dismiss,
                onOpenMeguriUserProfile: openMeguriUserProfileFromGroomViewer,
                closeAnchor: meguriGroomViewerSourceAnchor
            )
        }
    }

    private var tabs: some View {
        TabView(selection: tabSelection) {
            homeTab
            tradesTab
            meguriTab
            inventoryTab
            wishTab
        }
        .tint(MegrumTheme.lavender)
        .onChange(of: selectedTab) { _, selectedTab in
            requestInterstitialIfPrepared(for: selectedTab)
        }
        #if os(iOS)
        .toolbarBackground(tabBarBackgroundVisibility, for: .tabBar)
        .ignoresSafeArea(.container, edges: selectedTab == .meguri ? .bottom : [])
        #endif
    }

    #if os(iOS)
    private var tabBarBackgroundVisibility: Visibility {
        if selectedTab == .meguri {
            return .hidden
        }
        if #available(iOS 26.0, *) {
            return .hidden
        }
        return .automatic
    }
    #endif

    private var tutorialSampleActive: Bool {
        tutorialCoordinator.isActive
    }

    private var homeTab: some View {
        NavigationStack {
            HomeScreen(
                viewer: appState.viewer,
                matchedItems: tutorialSampleActive ? TutorialSampleHomeData.matchedItems : appState.homeMatchedItems,
                possibleItems: tutorialSampleActive ? TutorialSampleHomeData.possibleItems : appState.homePossibleItems,
                adDisplayContext: adDisplayContext,
                showsSearch: $showsSearch,
                onRefresh: appState.refresh,
                appState: appState,
                onOpenSettings: onOpenDrawer,
                onOpenSearchRequested: {
                    homeSearchInitialCriteria = nil
                    showsSearch = true
                },
                onOpenSearchWithCriteria: { criteria in
                    homeSearchInitialCriteria = criteria
                    showsSearch = true
                },
                onOpenWish: {
                    openWishSection(.wishes)
                },
                onOpenIndividualListings: {
                    openWishSection(.listings)
                },
                onOpenExchangeSettings: {
                    homeSettingsRoute = .exchange
                },
                onOpenPaymentSettings: {
                    homeSettingsRoute = .payment
                },
                onOpenOwnerProfile: { userID in
                    publicProfileRoute = PublicProfileRoute(userID: userID)
                },
                onOpenRelationRoute: { route in
                    homeRelationRoute = route
                },
                onOpenProposalRoute: { route in
                    homeProposalRoute = route
                },
                onOpenMeguri: {
                    requestedTradesStage = nil
                    selectedTab = .meguri
                },
                onOpenTrades: {
                    requestedTradesStage = nil
                    selectedTab = .trades
                },
                onOpenInventory: {
                    requestedTradesStage = nil
                    selectedTab = .inventory
                },
                onOpenGroom: { groom, anchor in
                    // FB(iter1226.403)：タップしたタイルの位置から拡大／その位置へ縮小する。
                    openMeguriGroomViewer(groom, sourceAnchor: anchor)
                },
                onOpenMeguriMessages: {
                    // iter1226.420：ホームの紙飛行機/左スワイプからめぐりメッセージ一覧へスライド表示。
                    isShowingMeguriMessageInbox = true
                },
                onOpenBoardThread: { thread in
                    // iter1226.421：ホームの近くのチャットルーム行→スレッド詳細をスライド表示。
                    openMeguriBoardThread(
                        MeguriBoardThreadRoute(thread: thread, selectedPrefecture: nil, coordinate: nil)
                    )
                },
                onOpenBoardList: {
                    isShowingNearbyBoardList = true
                },
                onOpenOwnGrooms: { ownGrooms, initial, anchor in
                    // FB(iter1226.402)：自分のグルームは「自分のグルームだけ」を古い→新しい順で辿る。
                    openMeguriGroomViewer(initial, sourceAnchor: anchor, sequence: ownGrooms)
                },
                tutorialSampleActive: tutorialSampleActive,
                tutorialFocusAnchor: tutorialCoordinator.currentBeat?.homeFocusAnchor,
                starterMissionEnabled: !tutorialSampleActive,
                conditionSignalsByItemIDOverride: tutorialSampleActive ? TutorialSampleHomeData.conditionSignals : nil,
                inventoryItemsOverride: tutorialSampleActive
                    ? TutorialSampleHomeData.viewerInventory(ownerID: appState.viewer?.id ?? TutorialSampleHomeData.placeholderViewerID)
                    : nil,
                visualQAInitialScreen: visualQAInitialScreen
            )
        }
        .tag(MegrumTab.home)
        .tabItem {
            Label(MegrumTab.home.title, systemImage: MegrumTab.home.symbolName)
        }
    }

    private var inventoryTab: some View {
        NavigationStack {
            GoodsCollectionScreen(
                title: "マイグッズ",
                subtitle: "",
                items: appState.inventory,
                showsAddButton: true,
                appState: appState,
                entryKind: .inventory
            )
        }
        .tag(MegrumTab.inventory)
        .tabItem {
            Label(MegrumTab.inventory.title, systemImage: MegrumTab.inventory.symbolName)
        }
    }

    private var wishTab: some View {
        NavigationStack {
            WishCollectionScreen(
                items: appState.wishes,
                appState: appState,
                requestedSection: $requestedWishSection,
                adDisplayContext: adDisplayContext
            )
        }
        .tag(MegrumTab.wish)
        .tabItem {
            Label(MegrumTab.wish.title, systemImage: MegrumTab.wish.symbolName)
        }
    }

    private var tradesTab: some View {
        NavigationStack {
            TradesScreen(
                appState: appState,
                requestedStage: $requestedTradesStage,
                detailRoute: $tradeDetailRoute,
                adDisplayContext: adDisplayContext
            )
        }
        .tag(MegrumTab.trades)
        .tabItem {
            Label(MegrumTab.trades.title, systemImage: MegrumTab.trades.symbolName)
        }
        .badge(tradeAttentionCounts.total)
    }

    private var meguriTab: some View {
        NavigationStack {
            MegrumDeferredContent {
                MeguriScreen(
                    appState: appState,
                    homeResetToken: meguriHomeResetToken,
                    visualQAInitialScreen: visualQAInitialScreen,
                    pendingNotificationRouteIntent: $pendingNotificationRouteIntent,
                    onOpenBoardList: { isShowingNearbyBoardList = true },
                    onOpenMessages: openMeguriMessageInbox,
                    onOpenBoardThread: openMeguriBoardThread,
                    onOpenMeguriUserProfile: openMeguriUserProfile,
                    onOpenGroomViewer: { groom, anchor in openMeguriGroomViewer(groom, sourceAnchor: anchor) }
                )
            }
        }
        .tag(MegrumTab.meguri)
        .ignoresSafeArea(.container, edges: .bottom)
        .tabItem {
            Label {
                Text(MegrumTab.meguri.title)
            } icon: {
                Image("TabMeguriIcon", bundle: .main)
                    .renderingMode(.template)
            }
        }
        // めぐりバッジは「未返信」ではなく未読メッセージ数（オーナーFB iter1226.338）。
        .badge(appState.meguriUnreadMessageCount)
    }

    private func openWishSection(_ section: WishCollectionSection) {
        requestedWishSection = section
        requestedTradesStage = nil
        selectedTab = .wish
    }

    private func openTradesFromHomePresentation() {
        requestedTradesStage = nil
        selectedTab = .trades
    }

    private var tabSelection: Binding<MegrumTab> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == selectedTab {
                    handleTabReselection(newValue)
                } else {
                    selectedTab = newValue
                }
            }
        )
    }

    private func handleTabReselection(_ tab: MegrumTab) {
        if tab == .meguri {
            meguriGroomViewerPost = nil
            isGroomViewerPresented = false
            isShowingMeguriMessageInbox = false
            meguriMessageDetailRoute = nil
            meguriBoardThreadRoute = nil
            meguriHomeResetToken = UUID()
        }
    }

    private func openMeguriGroomViewer(_ groom: GroomPost, sourceAnchor: UnitPoint, sequence: [GroomPost] = []) {
        meguriGroomViewerSourceAnchor = sourceAnchor
        meguriGroomViewerSequence = sequence
        isGroomViewerPresented = true
        meguriGroomViewerPost = groom
    }

    private func dismissMeguriGroomViewer() {
        meguriGroomViewerPost = nil
        meguriGroomViewerSequence = []
        isGroomViewerPresented = false
    }

    private func openMeguriUserProfileFromGroomViewer(_ userID: UUID) {
        dismissMeguriGroomViewer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            openMeguriUserProfile(userID)
        }
    }

    private func openMeguriMessageInbox() {
        withAnimation(MegrumSlidePresentationMetrics.animation) {
            meguriMessageDetailRoute = nil
            isShowingMeguriMessageInbox = true
        }
    }

    private func openMeguriMessageThread(_ thread: MeguriMessageThread) {
        withAnimation(MegrumSlidePresentationMetrics.animation) {
            isShowingMeguriMessageInbox = true
            meguriMessageDetailRoute = MeguriMessagePeerRoute(
                peerID: thread.peerID,
                scope: .conversation(sourceGroomPostID: thread.sourceGroomPostID)
            )
        }
    }

    private func openMeguriMessageThread(peerID: UUID) {
        withAnimation(MegrumSlidePresentationMetrics.animation) {
            isShowingMeguriMessageInbox = true
            meguriMessageDetailRoute = MeguriMessagePeerRoute(peerID: peerID)
        }
    }

    private func openMeguriBoardThread(_ route: MeguriBoardThreadRoute) {
        withAnimation(MegrumSlidePresentationMetrics.animation) {
            meguriBoardThreadRoute = route
        }
    }

    private func openMeguriUserProfile(_ userID: UUID) {
        withAnimation(MegrumSlidePresentationMetrics.animation) {
            meguriUserProfileRoute = MeguriUserProfileRoute(userID: userID)
        }
    }

    private func handlePendingNotificationRouteIntent(_ intent: NotificationRouteIntent?) {
        guard let intent else {
            return
        }

        switch intent {
        case .meguriMessages(let peerID, _):
            requestedTradesStage = nil
            selectedTab = .meguri
            withAnimation(MegrumSlidePresentationMetrics.animation) {
                isShowingMeguriMessageInbox = true
                if let peerID, let uuid = UUID(uuidString: peerID) {
                    meguriMessageDetailRoute = MeguriMessagePeerRoute(peerID: uuid)
                } else {
                    meguriMessageDetailRoute = nil
                }
            }
            pendingNotificationRouteIntent = nil
        case .ownGroom, .groomDetail:
            // めぐりタブへ切替。詳細（取得＋ゲート＋表示）は MeguriScreen 側で処理するため pending は残す。
            requestedTradesStage = nil
            selectedTab = .meguri
        case .tab, .tradeDetail, .tradeEvidenceCapture, .tradeEvidenceApproval,
             .tradeEvaluation, .tradeAssistance, .disputeDetail,
             .meguriBoardThread, .userProfile, .userEvaluations, .unknown:
            pendingNotificationRouteIntent = nil
        }
    }

    private func openVisualQAMeguriMessagesIfNeeded() {
        guard visualQAInitialScreen == .meguriMessages || visualQAInitialScreen == .meguriMessageThread,
              !didOpenVisualQAMeguriMessages
        else {
            return
        }
        didOpenVisualQAMeguriMessages = true
        openMeguriMessageInbox()
    }

    private func openVisualQANearbyBoardListIfNeeded() {
        guard visualQAInitialScreen == .nearbyBoardList
                || visualQAInitialScreen == .nearbyBoardFilter
                || visualQAInitialScreen == .nearbyBoardLocked,
              !isShowingNearbyBoardList
        else {
            return
        }
        isShowingNearbyBoardList = true
    }

    private var tradeAttentionCounts: TradeStageAttentionCounts {
        TradeStageAttentionCounts(
            proposals: appState.proposals,
            messagesByProposalID: appState.messagesByProposalID,
            viewerReadAtByProposalID: appState.viewerReadAtByProposalID,
            viewerID: appState.viewer?.id,
            evaluatedProposalIDs: appState.viewerEvaluatedProposalIDs
        )
    }

    private func requestInterstitialIfPrepared(for tab: MegrumTab) {
        guard let placement = AdInterstitialPlacementResolver.placement(for: tab) else {
            return
        }
        onRequestInterstitial(placement)
    }
}
