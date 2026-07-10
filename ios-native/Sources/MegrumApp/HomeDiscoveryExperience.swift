import MegrumCore
import MegrumDesign
import SwiftUI

struct HomeDiscoveryExperience: View {
    var appState: MegrumAppState?
    var viewer: UserProfile?
    var inventoryItems: [GoodsItem] = []
    var matchedItems: [GoodsItem] = []
    var possibleItems: [GoodsItem] = []
    var recentPartnerItems: [GoodsItem] = []
    var goodsTypes: [GoodsType] = []
    var conditionSignalsByItemID: [UUID: HomeCandidateConditionSignals] = [:]
    var mutualMatchCandidateData: [HomeMutualMatchCandidateData] = []
    var hasLoadedCandidates: Bool = true
    var adDisplayContext: AdDisplayContext = AdDisplayContext()
    var opensInitialHavesLookup: Bool = false
    var onOpenSettings: () -> Void
    var onOpenSearch: () -> Void
    var onOpenSearchWithCriteria: (SearchInitialCriteria) -> Void = { _ in }
    var onOpenWish: () -> Void = {}
    var onOpenIndividualListings: () -> Void = {}
    var onOpenExchangeSettings: () -> Void = {}
    var onOpenPaymentSettings: () -> Void = {}
    var onOpenOwnerProfile: (UUID) -> Void = { _ in }
    var onStartProposal: (HomeDiscoveryProposalSelection) -> Void = { _ in }
    var onRefresh: () async -> Void
    /// ガイドツアー中：3セクションに「サンプル」バッジを付け、候補タップを無効化する。
    var tutorialSampleActive: Bool = false
    /// ガイドツアーのホーム3ステップ：ハイライト対象セクションへ自動スクロールする。
    var tutorialFocusAnchor: TutorialAnchorID? = nil
    /// 「最初の3ステップ」ミッションカードを出す対象画面か（ホームタブのみ true）。
    var starterMissionEnabled: Bool = false
    /// QA/デモ確認用：非nilの時は実データに関わらずこの達成状況でミッションカードを強制表示する。
    var starterMissionForcedState: HomeStarterMissionState? = nil
    var onOpenInventory: () -> Void = {}
    // FB8-6：ホーム上部の圏内グルーム・ストーリー列。iter1226.387。
    var showsGroomRail: Bool = false
    var groomRailGrooms: [GroomPost] = []
    var groomRailLockedIDs: Set<UUID> = []
    var groomRailHasOwnActiveGroom: Bool = false
    var groomRailHasAnyOwnGroom: Bool = false
    var groomRailActivationSignal: Int = 0
    var groomRailViewer: UserProfile? = nil
    var groomRailProfiles: [UUID: PublicUserProfile] = [:]
    var groomRailViewedIDs: Set<UUID> = []
    /// iter1226.422：グルーム列の初回ロード中フラグ（スケルトン表示用）。
    var groomRailIsLoadingInitial: Bool = false
    var isGroomComposerCreating: Bool = false
    var onOpenGroom: (GroomPost, UnitPoint) -> Void = { _, _ in }
    /// iter1226.420：ユーザー単位に束ねたグルーム群を開く（同一投稿者の連続閲覧）。
    var onOpenGroomGroup: ([GroomPost], UnitPoint) -> Void = { _, _ in }
    /// iter1226.420：ヘッダー紙飛行機・左スワイプからめぐりメッセージ一覧を開く。
    var onOpenMeguriMessages: () -> Void = {}
    /// iter1226.421：近くのチャットルーム（LINE風行）用。
    var nearbyBoardThreads: [BoardThread] = []
    var boardReplyPreviews: [UUID: [String]] = [:]
    var lockedBoardIDs: Set<UUID> = []
    /// FB(iter1226.424)：チャットルームごとの未読メッセージ件数。
    var boardUnreadCounts: [UUID: Int] = [:]
    var onOpenBoardThread: (BoardThread) -> Void = { _ in }
    var onOpenLockedBoardThread: () -> Void = {}
    var onOpenBoardList: () -> Void = {}
    var onAddGroom: () -> Void = {}
    var onViewOwnGroom: (UnitPoint) -> Void = { _ in }

    @AppStorage(HomeExchangeSettingsStorageKeys.preference) var exchangePreferenceRawValue = HomeDefaultExchangeSettings.standard.preference.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.requiresSamePrefecture) var exchangeRequiresSamePrefecture = HomeDefaultExchangeSettings.standard.requiresSamePrefecture
    @AppStorage(HomeExchangeSettingsStorageKeys.requiresDateOverlap) var exchangeRequiresDateOverlap = HomeDefaultExchangeSettings.standard.requiresDateOverlap
    @AppStorage(HomeExchangeSettingsStorageKeys.localPrefecture) var exchangeLocalPrefecture = HomeDefaultExchangeSettings.standard.localPrefecture
    @AppStorage(HomeExchangeSettingsStorageKeys.localDateKeys) var exchangeLocalDateKeysRawValue = ""
    @AppStorage(HomeExchangeSettingsStorageKeys.mailShippingFee) var exchangeMailShippingFeeRawValue = HomeDefaultExchangeSettings.standard.mailShippingFee.rawValue
    @AppStorage(HomeExchangeSettingsStorageKeys.mailShippingDays) var exchangeMailShippingDaysRawValue = HomeDefaultExchangeSettings.standard.mailShippingDays.rawValue
    @State private var showsEmptyStateOshiSettings = false
    @State private var starterMissionCompleted = false
    @State var selectedSheet: HomeDiscoverySheet?
    @State var selectedMutualMatchCandidate: HomeMutualMatchCandidate?
    @State var showsMatchHelp = false
    @State var pendingProposalSelection: HomeDiscoveryProposalSelection?
    @State var pendingProfileUserID: UUID?
    @State var didOpenInitialSheet = false
    @State var selectedPrimaryTab: HomeDiscoveryPrimaryTab = .candidates
    @State var seeAllRoute: HomeDiscoverySeeAllRoute?
    @State var showsIndividualListingCreation = false
    @State var sharePromptContext: GoodsSharePostContext?
    @State var isPreparingSharePost = false
    @State var sharePostErrorMessage: String?
    #if os(iOS)
    @State var shareActivityPayload: GoodsSharePostPayload?
    #endif

    var body: some View {
        MegrumCollapsingTopChromeContainer {
            ScrollViewReader { scrollProxy in
            HomePullRefreshScrollView(
                coordinateSpaceName: "home-discovery-candidates-refresh",
                indicatorTopPadding: HomeDiscoveryHeaderMetrics.pullRefreshIndicatorTopPadding,
                onRefresh: onRefresh
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    if showsGroomRail {
                        // FB8-6：圏内グルームのストーリー横並び（自分アイコン＋＋、未読先頭、水色→紫/グレー枠）。
                        GroomStrip(
                            grooms: groomRailGrooms,
                            lockedGroomIDs: groomRailLockedIDs,
                            viewer: groomRailViewer,
                            publicProfilesByUserID: groomRailProfiles,
                            viewedGroomIDs: groomRailViewedIDs,
                            isCreating: isGroomComposerCreating,
                            isLoadingInitial: groomRailIsLoadingInitial,
                            hasOwnActiveGroom: groomRailHasOwnActiveGroom,
                            hasAnyOwnGroom: groomRailHasAnyOwnGroom,
                            activationSignal: groomRailActivationSignal,
                            onAdd: onAddGroom,
                            onViewOwn: onViewOwnGroom,
                            onSelectGroup: onOpenGroomGroup
                        )
                        // 画面端までスクロールできるフルブリード（親の20pt余白を打ち消す）。iter1226.420。
                        .padding(.horizontal, -20)

                        // iter1226.421：グルーム列の直下に近くのチャットルーム（LINE風・最大3件＋すべて見る）。
                        HomeNearbyBoardSection(
                            threads: nearbyBoardThreads,
                            replyPreviews: boardReplyPreviews,
                            lockedIDs: lockedBoardIDs,
                            unreadCounts: boardUnreadCounts,
                            onOpenThread: onOpenBoardThread,
                            onOpenLockedThread: onOpenLockedBoardThread,
                            onSeeAll: onOpenBoardList
                        )
                    }

                    if showsStarterMissionCard {
                        HomeStarterMissionCard(
                            state: starterMissionState,
                            onOpenInventory: onOpenInventory,
                            onOpenWish: onOpenWish,
                            onOpenListings: onOpenIndividualListings,
                            onDismiss: resolveStarterMission
                        )
                    }

                    if !userTagCandidates.isEmpty {
                        HomeDiscoverySection(
                            title: "推し×シリーズでマッチ",
                            candidates: userTagCandidates,
                            layout: .summaryRows,
                            cardTitleStyle: .memberTag,
                            showsSeeAllButton: userTagCandidates.count > HomeDiscoverySummarySectionMetrics.displayLimit,
                            displayLimit: HomeDiscoverySummarySectionMetrics.displayLimit,
                            viewerGoodsImageURLByID: viewerGoodsImageURLByID,
                            badgeText: tutorialSampleActive ? "サンプル" : nil,
                            onSelect: { if !tutorialSampleActive { selectedSheet = $0 } },
                            onSeeAll: { seeAllRoute = .userTag }
                        )
                        .tutorialAnchor(ifPresent: tutorialSampleActive ? .homeSectionUserTag : nil)
                        .id(TutorialAnchorID.homeSectionUserTag)
                    }

                    if !userCandidates.isEmpty {
                        HomeDiscoverySection(
                            title: "推しでマッチ",
                            candidates: userCandidates,
                            layout: .summaryRows,
                            cardTitleStyle: .member,
                            showsSeeAllButton: userCandidates.count > HomeDiscoverySummarySectionMetrics.displayLimit,
                            displayLimit: HomeDiscoverySummarySectionMetrics.displayLimit,
                            viewerGoodsImageURLByID: viewerGoodsImageURLByID,
                            badgeText: tutorialSampleActive ? "サンプル" : nil,
                            onSelect: { if !tutorialSampleActive { selectedSheet = $0 } },
                            onSeeAll: { seeAllRoute = .user }
                        )
                        .tutorialAnchor(ifPresent: tutorialSampleActive ? .homeSectionUser : nil)
                        .id(TutorialAnchorID.homeSectionUser)
                    }

                    if !havesCandidates.isEmpty {
                        HomeDiscoverySection(
                            title: "求められているグッズ",
                            candidates: havesCandidates,
                            layout: .rail,
                            fullBleedRail: true,
                            badgeText: tutorialSampleActive ? "サンプル" : nil,
                            onSelect: { if !tutorialSampleActive { selectedSheet = $0 } }
                        )
                        .tutorialAnchor(ifPresent: tutorialSampleActive ? .homeSectionHaves : nil)
                        .id(TutorialAnchorID.homeSectionHaves)
                    }

                    // 候補が1件もない（新規ユーザー等）：導線カード＋新着のグッズ。
                    // 読み込み確定前はCTAを出さずスケルトンで待つ（初回ちらつき防止）。
                    if userTagCandidates.isEmpty,
                       userCandidates.isEmpty,
                       havesCandidates.isEmpty,
                       mutualMatchCandidates.isEmpty {
                        if hasLoadedCandidates {
                            // ミッションカード表示中は導線が重複するので空状態CTAを出さない。
                            if !showsStarterMissionCard {
                                HomeEmptyCandidateCTACard(
                                    onAddOshi: { showsEmptyStateOshiSettings = true },
                                    onAddWish: onOpenWish
                                )
                            }

                            if !recentCandidates.isEmpty {
                                HomeDiscoverySection(
                                    title: "新着のグッズ",
                                    candidates: recentCandidates,
                                    layout: .rail,
                                    onSelect: { selectedSheet = $0 }
                                )
                            }
                        } else {
                            HomeCandidateSkeletonView()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, HomeDiscoveryHeaderMetrics.contentTopPadding)
                .padding(.bottom, HomeDiscoveryHeaderMetrics.contentBottomPadding)
                .megrumReportsScrollContentTop(in: "home-discovery-candidates-refresh")
                .megrumSuppressesEnclosingScrollEdgeEffects()
            }
            .megrumHiddenBottomScrollEdgeEffect()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: tutorialFocusAnchor, initial: true) { _, anchor in
                guard let anchor else { return }
                withAnimation(.snappy(duration: 0.3)) {
                    scrollProxy.scrollTo(anchor, anchor: .center)
                }
            }
            }
        } chrome: { isCollapsed in
            pinnedHeader(isCollapsed: isCollapsed)
        }
        .sheet(isPresented: $showsEmptyStateOshiSettings) {
            if let appState {
                OshiSettingsScreen(appState: appState)
            }
        }
        .overlay {
            if let sharePromptContext {
                GoodsSharePromptOverlay(
                    context: sharePromptContext,
                    isPreparing: isPreparingSharePost,
                    errorMessage: sharePostErrorMessage,
                    onDismiss: dismissSharePrompt,
                    onShare: startGoodsSharePost
                )
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                .zIndex(20)
            }
        }
        .sheet(
            item: $selectedSheet,
            onDismiss: presentPendingProposalIfNeeded
        ) { sheet in
            HomeDiscoverySheetView(
                sheet: sheet,
                appState: appState,
                viewerOfferGoods: viewerOfferGoods,
                otherExchangeCandidates: otherExchangeGroups(for: sheet),
                onOpenOwnerProfile: requestProfilePresentation,
                onStartProposal: requestProposalPresentation
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $seeAllRoute) { route in
            HomeDiscoverySeeAllSheet(
                route: route,
                candidates: route == .userTag ? userTagCandidates : userCandidates,
                viewerGoodsImageURLByID: viewerGoodsImageURLByID,
                onSelect: { sheet in
                    seeAllRoute = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        selectedSheet = sheet
                    }
                }
            )
        }
        .sheet(item: $selectedMutualMatchCandidate) { candidate in
            HomeMutualMatchDetailSheet(
                candidate: candidate,
                allCandidates: mutualMatchCandidates,
                appState: appState,
                viewerOfferGoods: viewerOfferGoods,
                goodsTypes: goodsTypes,
                matchedItems: matchedItems,
                possibleItems: possibleItems,
                conditionSignalsByItemID: displayConditionSignalsByItemID,
                onOpenOwnerProfile: requestProfilePresentationFromMutualMatch,
                onStartProposal: requestProposalPresentationFromMutualMatch
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .homeIndividualListingCreationPresentation(isPresented: $showsIndividualListingCreation) {
            if let appState {
                NavigationStack {
                    IndividualListingEditorSheet(
                        appState: appState,
                        initialStep: .haves,
                        onCreatedListing: handleCreatedListingShare
                    )
                }
            }
        }
        .sheet(isPresented: $showsMatchHelp) {
            HomeMatchLogicHelpSheet(
                exchangeSettings: defaultExchangeSettings,
                onOpenWish: {
                    showsMatchHelp = false
                    onOpenWish()
                },
                onOpenIndividualListings: {
                    showsMatchHelp = false
                    onOpenIndividualListings()
                },
                onOpenExchangeSettings: {
                    showsMatchHelp = false
                    onOpenExchangeSettings()
                },
                onOpenPaymentSettings: {
                    showsMatchHelp = false
                    onOpenPaymentSettings()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task {
            openInitialSheetIfNeeded()
        }
        .onChange(of: havesCandidates.map(\.id)) { _, _ in
            openInitialSheetIfNeeded()
        }
        .task(id: viewer?.id) {
            refreshStarterMissionCompletion()
        }
        .onChange(of: starterMissionState) { _, _ in
            markStarterMissionCompletedIfNeeded()
        }
        #if os(iOS)
        .sheet(item: $shareActivityPayload, content: GoodsShareActivitySheet.init)
        #endif
        .animation(.spring(response: 0.30, dampingFraction: 0.86), value: sharePromptContext?.id)
    }

}

extension HomeDiscoveryExperience {
    var starterMissionState: HomeStarterMissionState {
        if let starterMissionForcedState {
            return starterMissionForcedState
        }
        return HomeStarterMissionState.evaluate(
            inventory: appState?.inventory ?? [],
            wishes: appState?.wishes ?? [],
            listings: appState?.listings ?? []
        )
    }

    var showsStarterMissionCard: Bool {
        // QA/デモ用の強制表示：完了フラグ・全達成判定を無視して必ず出す。
        if starterMissionForcedState != nil {
            return !starterMissionCompleted
        }
        guard starterMissionEnabled, viewer != nil, !starterMissionCompleted else {
            return false
        }
        // 3タスク全達成なら表示しない（onChange 前の初期allDoneも拾う）。
        return !starterMissionState.allDone
    }

    private func refreshStarterMissionCompletion() {
        // QA/デモ強制表示中は毎回まっさらな状態から出す（過去のクローズを引き継がない）。
        if starterMissionForcedState != nil {
            starterMissionCompleted = false
            return
        }
        guard let userID = viewer?.id else {
            starterMissionCompleted = false
            return
        }
        starterMissionCompleted = OnboardingTutorialProgressStore.isMissionCompleted(userID: userID)
        // 初回表示時点で既に全達成なら完了フラグを永続化する。
        markStarterMissionCompletedIfNeeded()
    }

    private func markStarterMissionCompletedIfNeeded() {
        guard starterMissionEnabled, !starterMissionCompleted, starterMissionState.allDone else {
            return
        }
        resolveStarterMission()
    }

    /// ミッションを完了扱いにして以後表示しない（全達成 or 手動クローズ）。
    func resolveStarterMission() {
        guard let userID = viewer?.id else { return }
        OnboardingTutorialProgressStore.markMissionCompleted(userID: userID)
        withAnimation(.snappy(duration: 0.24)) {
            starterMissionCompleted = true
        }
    }
}
