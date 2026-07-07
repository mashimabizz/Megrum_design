import MegrumCore
import SwiftUI

@MainActor
public struct MegrumRootView: View {
    @StateObject private var appState: MegrumAppState
    @StateObject private var authState: MegrumAuthState
    @StateObject private var tutorialCoordinator = TutorialTourCoordinator()
    @State private var selectedTab: MegrumTab = .home
    @State private var showsSearch = false
    @State private var showsDrawer = false
    @State private var requestedTradesStage: TradeStage?
    @State private var drawerDestination: AppDrawerDestination?
    @State private var drawerPageDestination: AppDrawerDestination?
    @State private var publicProfileRoute: PublicProfileRoute?
    @State private var homeSettingsRoute: HomeSettingsRoute?
    @State private var requestedWishSection: WishCollectionSection?
    @State private var interstitialAdRequest: AdInterstitialRequest?
    @State private var visualQAProposalRoute: HomeRelationRoute?
    @State private var didOpenVisualQAProposalRoute = false
    @State private var pendingNotificationRouteIntent: NotificationRouteIntent?
    private let visualQAInitialScreen: VisualQAInitialScreen?
    @State private var isReturningStoredIncompleteAccountToLogin = false
    @Environment(\.scenePhase) private var scenePhase
    @Binding private var notificationDestinationTab: MegrumTab?
    @Binding private var notificationRouteLinkPath: String?
    @Binding private var notificationRouteKindRawValue: String?

    public init(
        appState: MegrumAppState = MegrumAppState(),
        authState: MegrumAuthState = MegrumAuthState(
            repository: PreviewMegrumAuthRepository(),
            initialSession: PreviewMegrumAuthRepository.previewSession()
        ),
        notificationDestinationTab: Binding<MegrumTab?> = .constant(nil),
        notificationRouteLinkPath: Binding<String?> = .constant(nil),
        notificationRouteKindRawValue: Binding<String?> = .constant(nil)
    ) {
        MegrumTabBarAppearance.configure()
        let visualQAInitialScreen = VisualQAPreviewMode.initialScreen(
            environment: ProcessInfo.processInfo.environment
        )
        _appState = StateObject(wrappedValue: appState)
        _authState = StateObject(wrappedValue: authState)
        _selectedTab = State(initialValue: VisualQATabRouteResolver.initialTab(for: visualQAInitialScreen))
        _showsDrawer = State(initialValue: visualQAInitialScreen == .drawerOpen)
        _showsSearch = State(initialValue: visualQAInitialScreen == .search)
        let visualQAProfileUserID = ProcessInfo.processInfo.environment["MEGRUM_VISUAL_QA_PROFILE_USER_ID"]
            .flatMap(UUID.init(uuidString:)) ?? NativePreviewData.partnerID
        _publicProfileRoute = State(
            initialValue: visualQAInitialScreen == .profileProposal
                ? PublicProfileRoute(userID: visualQAProfileUserID)
                : nil
        )
        _requestedTradesStage = State(initialValue: VisualQATabRouteResolver.requestedTradesStage(for: visualQAInitialScreen))
        self.visualQAInitialScreen = visualQAInitialScreen
        _notificationDestinationTab = notificationDestinationTab
        _notificationRouteLinkPath = notificationRouteLinkPath
        _notificationRouteKindRawValue = notificationRouteKindRawValue
    }

    public var body: some View {
        Group {
            if visualQAInitialScreen == .goodsTypeSelect {
                GoodsTypeSelectPreview()
            } else if visualQAInitialScreen == .candidateSheet {
                CandidateSheetVisualQAPreview()
            } else if AccountSetupSessionPolicy.shouldShowAuthScreen(
                isAuthenticated: authState.isAuthenticated,
                isReturningStoredIncompleteAccountToLogin: isReturningStoredIncompleteAccountToLogin
            ) {
                AuthScreen(authState: authState, visualQAInitialScreen: visualQAInitialScreen)
            } else {
                authenticatedRoot
            }
        }
        .dismissKeyboardOnNonInputTap()
        .megrumInteractionFeedback()
        .onOpenURL { url in
            Task {
                await authState.handleOpenURL(url)
            }
        }
        .onChange(of: notificationDestinationTab) { _, destination in
            guard let destination else {
                return
            }
            // ツアー中は通知タブ遷移でスポットライトと実画面がズレるため破棄する。
            if !tutorialCoordinator.isActive {
                selectedTab = destination
            }
            notificationDestinationTab = nil
        }
        .onChange(of: notificationRouteLinkPath) { _, linkPath in
            guard let linkPath else {
                return
            }
            if !tutorialCoordinator.isActive {
                handleNotificationRoute(linkPath: linkPath, kindRawValue: notificationRouteKindRawValue)
            }
            notificationRouteLinkPath = nil
            notificationRouteKindRawValue = nil
        }
        .onChange(of: scenePhase) { _, phase in
            guard
                phase == .active,
                authState.isAuthenticated,
                !isReturningStoredIncompleteAccountToLogin
            else {
                return
            }
            Task {
                await syncRepositoryWithAuthSession(reloadsInitialData: false)
            }
        }
        .onChange(of: authState.sessionSource) { _, source in
            guard AccountSetupSessionPolicy.shouldClearReturnToLoginOverride(sessionSource: source) else {
                return
            }
            isReturningStoredIncompleteAccountToLogin = false
        }
    }

    private var authenticatedRoot: some View {
        MegrumRootAuthenticatedContent(
            appState: appState,
            visualQAInitialScreen: visualQAInitialScreen,
            directVisualQARelationRoute: directVisualQARelationRoute,
            directVisualQAProposalRoute: directVisualQAProposalRoute,
            visualQAProposalInitialStep: visualQAProposalInitialStep,
            visualQAIndividualListingOptionKind: visualQAIndividualListingOptionKind,
            drawerPageDestination: drawerPageDestination,
            adDisplayContext: adDisplayContext,
            sessionSource: authState.sessionSource,
            onRetryLoading: {
                await syncRepositoryWithAuthSession()
            },
            onSignOutFromLoadingFailure: {
                await authState.signOut()
                Task {
                    await appState.revokeRegisteredNativePushDeviceToken()
                }
            },
            onReturnToLoginFromIncompleteAccount: {
                isReturningStoredIncompleteAccountToLogin = true
            },
            onDismissDrawerPage: {
                drawerPageDestination = nil
            },
            onProposalCompletionAction: applyProposalCompletionRoute
        ) {
            authenticatedTabs
        }
        .task {
            await syncRepositoryWithAuthSession()
        }
        .onChange(of: authState.session?.user.id) { _, userID in
            guard userID != nil else {
                return
            }
            Task {
                await syncRepositoryWithAuthSession()
            }
        }
        .megrumSlideItemPresentation(item: $drawerDestination) { destination, dismiss in
            MegrumDeferredContent {
                MegrumRootDrawerDestinationSheet(
                    appState: appState,
                    authState: authState,
                    destination: destination,
                    selectedTab: $selectedTab,
                    drawerDestination: $drawerDestination,
                    publicProfileRoute: $publicProfileRoute,
                    onOpenRouteIntent: { intent in
                        applyNotificationRouteIntent(intent)
                    },
                    onStartTutorialChapter: { chapter in
                        // ヘルプの「使い方ガイド」：シートを閉じてから章別再生を開始する。
                        drawerDestination = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            tutorialCoordinator.startChapter(chapter)
                        }
                    },
                    onClose: dismiss
                )
            }
        }
        .megrumSlideItemPresentation(item: $publicProfileRoute) { route, _ in
            NavigationStack {
                PublicUserProfileScreen(
                    appState: appState,
                    userID: route.userID,
                    adDisplayContext: adDisplayContext,
                    adPlacement: .publicProfileFooterBanner
                )
            }
        }
        .sheet(item: $homeSettingsRoute) { route in
            NavigationStack {
                switch route {
                case .exchange:
                    HomeExchangeSettingsScreen(appState: appState, individualListings: appState.listings) {
                        homeSettingsRoute = nil
                    }
                case .payment:
                    PaymentSettingsScreen(appState: appState) {
                        homeSettingsRoute = nil
                    }
                }
            }
        }
        .rootVisualQAProposalPresentation(item: $visualQAProposalRoute) { route in
            NavigationStack {
                ProposalCreateFlow(
                    appState: appState,
                    targetItem: route.item,
                    matchType: route.matchType,
                    initialStep: visualQAProposalInitialStep,
                    visualQAInitialScreen: visualQAInitialScreen
                )
            }
        }
        .onChange(of: appState.homeMatchedItems.map(\.id), initial: true) { _, _ in
            openVisualQAProposalRouteIfNeeded()
        }
        .adInterstitialPresenter(
            request: $interstitialAdRequest,
            displayContext: adDisplayContext,
            configuration: adConfiguration
        )
        .onChange(of: appState.viewer?.accountStatus) { oldValue, newValue in
            startTutorialTourIfNeeded(oldStatus: oldValue, newStatus: newValue)
        }
        .onChange(of: tutorialCoordinator.currentBeat) { _, beat in
            handleTutorialBeatChange(beat)
        }
        .onAppear {
            startVisualQATutorialIfNeeded()
        }
    }

    /// セットアップ完了直後（requiresSetup→active）に初回のみツアーを起動する。
    private func startTutorialTourIfNeeded(oldStatus: AccountStatus?, newStatus: AccountStatus?) {
        guard oldStatus?.requiresSetup == true, newStatus == .active else { return }
        guard let userID = appState.viewer?.id else { return }
        guard !OnboardingTutorialProgressStore.isTourCompleted(userID: userID) else { return }
        tutorialCoordinator.start()
    }

    /// VisualQA（MEGRUM_VISUAL_QA_INITIAL_SCREEN=tutorial）では既読フラグを無視して強制起動する。
    /// MEGRUM_VISUAL_QA_TUTORIAL_STEP でビートID（例: 4-7）指定、
    /// MEGRUM_VISUAL_QA_TUTORIAL_CHAPTER で章別再生（ヘルプ導線相当）の直接起動もできる（スクショ検証用）。
    private func startVisualQATutorialIfNeeded() {
        guard visualQAInitialScreen == .tutorial, !tutorialCoordinator.isActive else { return }
        let environment = ProcessInfo.processInfo.environment
        if let chapter = VisualQAPreviewMode.tutorialStartChapter(environment: environment) {
            tutorialCoordinator.startChapter(chapter)
            return
        }
        let startBeat = VisualQAPreviewMode.tutorialStartBeat(environment: environment)
        tutorialCoordinator.start(at: startBeat)
    }

    /// ビート変化に応じてタブを自動遷移し、割り込み抑制フラグと完了フラグを更新する。
    private func handleTutorialBeatChange(_ beat: TutorialBeat?) {
        appState.setTutorialActive(beat != nil)

        guard let beat else {
            // ツアー終了：全編再生の時だけ既読フラグを保存（ヘルプからの章別再生では触らない）。
            if tutorialCoordinator.scope == .full, let userID = appState.viewer?.id {
                OnboardingTutorialProgressStore.markTourCompleted(userID: userID)
            }
            return
        }

        requestedTradesStage = nil
        if let section = beat.requestedWishSection {
            requestedWishSection = section
        }
        selectedTab = beat.targetTab
    }

    private var directVisualQAProposalRoute: HomeRelationRoute? {
        guard VisualQAProposalRouteResolver.shouldRenderDirectRoot(for: visualQAInitialScreen) else {
            return nil
        }
        guard let item = VisualQATargetItemResolver.targetItem(
            candidates: appState.homeMatchedItems,
            viewerID: appState.viewer?.id
        ) else {
            return nil
        }
        return HomeRelationRoute(item: item, matchType: .perfect)
    }

    private var directVisualQARelationRoute: HomeRelationRoute? {
        guard VisualQARelationRouteResolver.shouldRenderDirectRoot(for: visualQAInitialScreen) else {
            return nil
        }
        guard let item = VisualQATargetItemResolver.targetItem(
            candidates: appState.homeMatchedItems,
            viewerID: appState.viewer?.id
        ) else {
            return nil
        }
        return HomeRelationRoute(item: item, matchType: .perfect)
    }

    private var visualQAIndividualListingOptionKind: IndividualListingOptionKind? {
        switch visualQAInitialScreen {
        case .individualListingWish:
            .wish
        case .individualListingCondition:
            .condition
        case .individualListingCash:
            .cash
        default:
            nil
        }
    }

    private var authenticatedTabs: some View {
        MegrumAuthenticatedTabsView(
            appState: appState,
            selectedTab: $selectedTab,
            showsSearch: $showsSearch,
            showsDrawer: $showsDrawer,
            requestedTradesStage: $requestedTradesStage,
            drawerDestination: $drawerDestination,
            drawerPageDestination: $drawerPageDestination,
            publicProfileRoute: $publicProfileRoute,
            homeSettingsRoute: $homeSettingsRoute,
            requestedWishSection: $requestedWishSection,
            pendingNotificationRouteIntent: $pendingNotificationRouteIntent,
            tutorialCoordinator: tutorialCoordinator,
            adDisplayContext: adDisplayContext,
            visualQAInitialScreen: visualQAInitialScreen,
            onSignOut: {
                await authState.signOut()
                await appState.revokeRegisteredNativePushDeviceToken()
            },
            onRequestInterstitial: requestInterstitial
        )
    }

    private var adConfiguration: AdRuntimeConfiguration {
        AdRuntimeConfiguration.current()
    }

    private var adDisplayContext: AdDisplayContext {
        AdDisplayContext(
            viewerID: appState.viewer?.id,
            isPremiumSubscriber: appState.subscriptionState.suppressesAds
        )
    }

    private func syncRepositoryWithAuthSession(reloadsInitialData: Bool = true) async {
        await authState.refreshSessionIfNeeded()
        await appState.replaceRepository(
            MegrumAppStateFactory.repository(authSession: authState.session),
            reloadsInitialData: reloadsInitialData
        )
        // アプリアイコンのバッジ（未読通知数）を起動直後から反映できるよう、
        // ドロワーを開く前に通知を読み込んでおく。バッジ用途なので失敗しても
        // アプリ全体のエラー表示にはしない（起動を壊さない）。
        await appState.loadNotifications(reportsFailure: false)
    }

    private func applyProposalCompletionRoute(_ action: ProposalCompletionAction) {
        let route = ProposalCompletionRouteResolver.resolve(action: action)
        requestedTradesStage = route.requestedTradesStage
        selectedTab = route.selectedTab
    }

    private func handleNotificationRoute(linkPath: String, kindRawValue: String?) {
        let kind = kindRawValue.flatMap(MegrumNotificationKind.init(rawValue:))
        guard let intent = NotificationRouteIntent(linkPath: linkPath, kind: kind) else {
            selectedTab = MegrumTab(notificationLinkPath: linkPath) ?? .home
            return
        }
        applyNotificationRouteIntent(intent)
    }

    private func applyNotificationRouteIntent(_ intent: NotificationRouteIntent) {
        selectedTab = intent.fallbackTab
        switch intent {
        case .meguriMessages, .ownGroom:
            pendingNotificationRouteIntent = intent
        case .userProfile(let id), .userEvaluations(let id):
            guard let userID = UUID(uuidString: id) else {
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                publicProfileRoute = PublicProfileRoute(userID: userID)
            }
        case .tab, .tradeDetail, .tradeEvidenceCapture, .tradeEvidenceApproval,
             .tradeEvaluation, .tradeAssistance, .disputeDetail,
             .meguriBoardThread, .unknown:
            break
        }
    }

    private func openVisualQAProposalRouteIfNeeded() {
        guard VisualQAProposalRouteResolver.shouldOpenProposalFlow(for: visualQAInitialScreen),
              !VisualQAProposalRouteResolver.shouldRenderDirectRoot(for: visualQAInitialScreen),
              !didOpenVisualQAProposalRoute
        else {
            return
        }
        guard let item = VisualQATargetItemResolver.targetItem(
            candidates: appState.homeMatchedItems,
            viewerID: appState.viewer?.id
        ) else {
            return
        }
        didOpenVisualQAProposalRoute = true
        visualQAProposalRoute = HomeRelationRoute(item: item, matchType: .perfect)
    }

    private var visualQAProposalInitialStep: ProposalCreateStep {
        VisualQAProposalRouteResolver.initialStep(for: visualQAInitialScreen) ?? .meetup
    }

    private func requestInterstitial(_ placement: AdPlacement) {
        // ツアー中はタブ自動遷移で広告が挟まらないよう抑制する。
        guard !tutorialCoordinator.isActive else { return }
        interstitialAdRequest = AdInterstitialRequest(placement: placement)
    }
}
