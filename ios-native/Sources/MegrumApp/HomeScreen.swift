import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct HomeScreen: View {
    var viewer: UserProfile?
    var matchedItems: [GoodsItem]
    var possibleItems: [GoodsItem]
    var adDisplayContext: AdDisplayContext = AdDisplayContext()
    @Binding var showsSearch: Bool
    var onRefresh: () async -> Void
    var appState: MegrumAppState? = nil
    var onOpenSettings: () -> Void = {}
    var onOpenSearchRequested: (() -> Void)? = nil
    var onOpenSearchWithCriteria: (SearchInitialCriteria) -> Void = { _ in }
    var onOpenWish: () -> Void = {}
    var onOpenIndividualListings: () -> Void = {}
    var onOpenExchangeSettings: () -> Void = {}
    var onOpenPaymentSettings: () -> Void = {}
    var onOpenOwnerProfile: (UUID) -> Void = { _ in }
    var onOpenRelationRoute: ((HomeRelationRoute) -> Void)?
    var onOpenProposalRoute: ((HomeProposalRoute) -> Void)?
    var onOpenMeguri: (() -> Void)? = nil
    var onOpenTrades: (() -> Void)? = nil
    var onOpenInventory: () -> Void = {}
    /// FB8-6：ホーム上部の圏内グルーム・ストーリー列からグルームを開く（タブ上位のイマーシブ表示へ）。iter1226.387。
    var onOpenGroom: (GroomPost) -> Void = { _ in }
    var tutorialSampleActive: Bool = false
    var tutorialFocusAnchor: TutorialAnchorID? = nil
    var starterMissionEnabled: Bool = false
    /// ガイドツアーのサンプル候補用シグナル差し替え。指定時は appState 由来のシグナルより優先。
    var conditionSignalsByItemIDOverride: [UUID: HomeCandidateConditionSignals]? = nil
    /// ガイドツアーのサンプル用：あなたのグッズ（求められているグッズ・激求サムネイル）を差し替える。
    var inventoryItemsOverride: [GoodsItem]? = nil
    var visualQAInitialScreen: VisualQAInitialScreen? = nil

    /// QA/デモ確認用：`starter-mission` 起動時は実データに関わらずミッションカードを強制表示する。
    /// マイグッズ済み・ほしいもの/個別募集は未達成のリアルな途中状態を見せる。
    private var starterMissionForcedState: HomeStarterMissionState? {
        guard visualQAInitialScreen == .starterMission else { return nil }
        return HomeStarterMissionState(inventoryDone: true, wishDone: false, listingDone: false)
    }

    @AppStorage("megrum.home.localMode.activityWindowID") var localModeActivityWindowID = ""
    @AppStorage("megrum.home.localMode.enabled") var localModeEnabled = false
    @AppStorage("megrum.home.localMode.venue") var localModeVenue = ""
    @AppStorage("megrum.home.localMode.latitude") var localModeLatitude = ""
    @AppStorage("megrum.home.localMode.longitude") var localModeLongitude = ""
    @AppStorage("megrum.home.localMode.startedAt") var localModeStartedAt = 0.0
    @AppStorage("megrum.home.localMode.durationMinutes") var localModeDurationMinutes = HomeLocalActivitySettings.defaultDurationMinutes
    @AppStorage("megrum.home.localMode.radiusMeters") var localModeRadiusMeters = HomeLocalActivitySettings.defaultRadiusMeters
    @AppStorage("megrum.home.localMode.selectedCarryingIDs") var localModeSelectedCarryingIDs = ""
    @State var loadedLocalActivitySettings: HomeLocalActivitySettings?
    @State private var showsLocalModeSettings = false
    @State var relationRoute: HomeRelationRoute?
    @State var proposalRoute: HomeProposalRoute?
    @State var didOpenVisualQAInitialRoute = false
    // FB8-6：圏内グルーム列＋その場投稿コンポーザ用の状態。iter1226.387。
    @StateObject private var groomLocationState = MegrumLocationState()
    @State private var isGroomComposerPresented = false
    /// FB(iter1226.392)：ロックされた（圏外×無料）遭遇グルームをタップした時のプレミアム案内。
    @State private var isShowingGroomLockPremium = false

    /// 実データのホーム（ガイドツアー以外）でグルーム列を出す。
    private var showsGroomRail: Bool {
        appState != nil && !tutorialSampleActive
    }

    /// FB(iter1226.392)：ホーム上部の列は「圏内で開けるグルーム」＋「出会った(遭遇済み)グルーム」を並べる。
    /// 遭遇済みでも圏外・無料だと開けない → ロックアイコン付きで表示（タップでプレミアム案内）。
    private var groomRailItems: [GroomPost] {
        guard let appState else { return [] }
        let coordinate = groomLocationState.coordinate
        let viewerID = (appState.viewer ?? viewer)?.id
        let openable = appState.groomMapPosts.filter { groom in
            MeguriAccessPolicy.canOpenGroom(
                groom,
                currentCoordinate: coordinate,
                viewerID: viewerID,
                hasEncountered: groom.encounteredInRange,
                subscriptionState: appState.subscriptionState
            )
        }
        var seen = Set(openable.map(\.id))
        var result = openable
        for groom in appState.encounteredGrooms where !seen.contains(groom.id) {
            seen.insert(groom.id)
            result.append(groom)
        }
        return result
    }

    /// 上記のうち、いま開けない（圏外×無料などで）グルームID。ロックアイコン表示に使う。
    private var groomRailLockedIDs: Set<UUID> {
        guard let appState else { return [] }
        let coordinate = groomLocationState.coordinate
        let viewerID = (appState.viewer ?? viewer)?.id
        return Set(
            groomRailItems.filter { groom in
                !MeguriAccessPolicy.canOpenGroom(
                    groom,
                    currentCoordinate: coordinate,
                    viewerID: viewerID,
                    hasEncountered: groom.encounteredInRange,
                    subscriptionState: appState.subscriptionState
                )
            }.map(\.id)
        )
    }

    private func handleGroomRailTap(_ groom: GroomPost) {
        guard let appState else {
            onOpenGroom(groom)
            return
        }
        let canOpen = MeguriAccessPolicy.canOpenGroom(
            groom,
            currentCoordinate: groomLocationState.coordinate,
            viewerID: (appState.viewer ?? viewer)?.id,
            hasEncountered: groom.encounteredInRange,
            subscriptionState: appState.subscriptionState
        )
        if canOpen {
            onOpenGroom(groom)
        } else {
            isShowingGroomLockPremium = true
        }
    }

    var body: some View {
        groomComposerWrapped
            .task(id: groomLocationState.coordinate?.latitude) {
                await loadNearbyGroomsIfPossible()
            }
            .onAppear {
                if showsGroomRail, groomLocationState.coordinate == nil {
                    groomLocationState.requestCurrentLocation()
                }
            }
    }

    @ViewBuilder
    private var groomComposerWrapped: some View {
        if let appState, showsGroomRail {
            GroomComposerContainer(
                appState: appState,
                locationState: groomLocationState,
                isPresented: $isGroomComposerPresented
            ) {
                homeBody
            }
        } else {
            homeBody
        }
    }

    private func loadNearbyGroomsIfPossible() async {
        guard showsGroomRail, let appState, let coordinate = groomLocationState.coordinate else {
            return
        }
        await appState.loadGroomMapPosts(latitude: coordinate.latitude, longitude: coordinate.longitude)
        // FB(iter1226.392): 出会った(遭遇済み)グルームも取得（近くに無くても列に出す）。
        await appState.loadEncounteredGrooms(latitude: coordinate.latitude, longitude: coordinate.longitude)
        await appState.loadMeguriProfiles(
            userIDs: Set(appState.groomMapPosts.map(\.authorID)).union(appState.encounteredGrooms.map(\.authorID)),
            reportsFailure: false
        )
        // FB(iter1226.390): 現在地1km圏内の推しグルームを検出して遭遇記録＋通知。
        await appState.evaluateGroomProximity(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

    private var homeBody: some View {
        HomeDiscoveryExperience(
            appState: appState,
            viewer: viewer,
            inventoryItems: inventoryItemsOverride ?? appState?.inventory ?? [],
            matchedItems: matchedItems,
            possibleItems: possibleItems,
            recentPartnerItems: appState?.homeRecentPartnerItems ?? [],
            goodsTypes: appState?.goodsTypes ?? [],
            conditionSignalsByItemID: conditionSignalsByItemIDOverride ?? appState?.homeCandidateConditionSignals ?? [:],
            mutualMatchCandidateData: appState?.homeMutualMatchCandidates ?? [],
            hasLoadedCandidates: appState?.hasLoadedHomeCandidates ?? true,
            adDisplayContext: adDisplayContext,
            opensInitialHavesLookup: visualQAInitialScreen == .homeHavesLookup,
            onOpenSettings: onOpenSettings,
            onOpenSearch: {
                if let onOpenSearchRequested {
                    onOpenSearchRequested()
                } else {
                    showsSearch = true
                }
            },
            onOpenSearchWithCriteria: onOpenSearchWithCriteria,
            onOpenWish: onOpenWish,
            onOpenIndividualListings: onOpenIndividualListings,
            onOpenExchangeSettings: onOpenExchangeSettings,
            onOpenPaymentSettings: onOpenPaymentSettings,
            onOpenOwnerProfile: onOpenOwnerProfile,
            onStartProposal: startProposalFromDiscovery,
            onRefresh: {
                await onRefresh()
                await loadLocalActivitySettings()
            },
            tutorialSampleActive: tutorialSampleActive,
            tutorialFocusAnchor: tutorialFocusAnchor,
            starterMissionEnabled: starterMissionEnabled,
            starterMissionForcedState: starterMissionForcedState,
            onOpenInventory: onOpenInventory,
            showsGroomRail: showsGroomRail,
            groomRailGrooms: groomRailItems,
            groomRailLockedIDs: groomRailLockedIDs,
            groomRailViewer: appState?.viewer ?? viewer,
            groomRailProfiles: appState?.publicProfilesByUserID ?? [:],
            groomRailViewedIDs: appState?.viewedGroomIDs ?? [],
            onOpenGroom: handleGroomRailTap,
            onAddGroom: { isGroomComposerPresented = true }
        )
        .background(MegrumTheme.canvas.ignoresSafeArea())
        .megrumHiddenNavigationBar()
        .sheet(isPresented: $showsLocalModeSettings) {
            HomeLocalModeSettingsSheet(
                viewer: viewer,
                settings: localActivitySettings,
                carryingCandidates: localCarryingCandidates,
                onSave: saveLocalActivitySettings
            )
        }
        .sheet(isPresented: $isShowingGroomLockPremium) {
            if let appState {
                NavigationStack {
                    SubscriptionSettingsScreen(appState: appState)
                }
            }
        }
        .homeRelationPresentation(item: $relationRoute) { route in
            if let relationState = localModeState {
                NavigationStack {
                    MatchRelationScreen(
                        appState: relationState,
                        targetItem: route.item,
                        matchType: route.matchType,
                        visualQAInitialScreen: visualQAInitialScreen,
                        onCompletionAction: { action in
                            relationRoute = nil
                            if action == .openTrades {
                                onOpenTrades?()
                            }
                        }
                    )
                }
            }
        }
        .homeProposalPresentation(item: $proposalRoute) { route in
            if let relationState = localModeState {
                NavigationStack {
                    ProposalCreateFlow(
                        appState: relationState,
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
                            proposalRoute = nil
                            if action == .openTrades {
                                onOpenTrades?()
                            }
                        }
                    )
                }
            }
        }
        .task(id: viewer?.id) {
            await loadLocalActivitySettings()
            openVisualQAInitialRouteIfNeeded()
        }
        .onChange(of: matchedItems.map(\.id), initial: true) { _, _ in
            openVisualQAInitialRouteIfNeeded()
        }
    }

}
