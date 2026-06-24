import MegrumCore
import MegrumDesign
import SwiftUI

enum HomeSettingsRoute: Identifiable, Equatable {
    case exchange
    case payment

    var id: String {
        switch self {
        case .exchange:
            "exchange"
        case .payment:
            "payment"
        }
    }
}

@MainActor
public struct MegrumRootView: View {
    @StateObject private var appState: MegrumAppState
    @StateObject private var authState: MegrumAuthState
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
    private let visualQAInitialScreen: VisualQAInitialScreen?
    @State private var drawerDragTranslation: CGFloat = 0
    @Environment(\.scenePhase) private var scenePhase
    @Binding private var notificationDestinationTab: MegrumTab?

    public init(
        appState: MegrumAppState = MegrumAppState(),
        authState: MegrumAuthState = MegrumAuthState(
            repository: PreviewMegrumAuthRepository(),
            initialSession: PreviewMegrumAuthRepository.previewSession()
        ),
        notificationDestinationTab: Binding<MegrumTab?> = .constant(nil)
    ) {
        MegrumTabBarAppearance.configure()
        let visualQAInitialScreen = VisualQAPreviewMode.initialScreen(
            environment: ProcessInfo.processInfo.environment
        )
        _appState = StateObject(wrappedValue: appState)
        _authState = StateObject(wrappedValue: authState)
        _selectedTab = State(initialValue: VisualQATabRouteResolver.initialTab(for: visualQAInitialScreen))
        _showsDrawer = State(initialValue: visualQAInitialScreen == .drawerOpen)
        _requestedTradesStage = State(initialValue: VisualQATabRouteResolver.requestedTradesStage(for: visualQAInitialScreen))
        self.visualQAInitialScreen = visualQAInitialScreen
        _notificationDestinationTab = notificationDestinationTab
    }

    public var body: some View {
        Group {
            if authState.isAuthenticated {
                authenticatedRoot
            } else {
                AuthScreen(authState: authState, visualQAInitialScreen: visualQAInitialScreen)
            }
        }
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
            selectedTab = destination
            notificationDestinationTab = nil
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, authState.isAuthenticated else {
                return
            }
            Task {
                await syncRepositoryWithAuthSession()
            }
        }
    }

    private var authenticatedRoot: some View {
        Group {
            if appState.viewer == nil {
                if let errorMessage = appState.errorMessage {
                    NativeLoadingFailureScreen(
                        title: "Megrumを読み込めませんでした",
                        message: errorMessage,
                        onRetry: {
                            await syncRepositoryWithAuthSession()
                        },
                        onSignOut: {
                            await authState.signOut()
                            Task {
                                await appState.revokeRegisteredNativePushDeviceToken()
                            }
                        }
                    )
                } else {
                    NativeLoadingScreen(title: "Megrumを読み込んでいます")
                }
            } else if appState.viewer?.accountStatus.requiresSetup == true {
                NavigationStack {
                    AccountSetupScreen(appState: appState)
                }
            } else if let route = directVisualQARelationRoute {
                NavigationStack {
                    MatchRelationScreen(
                        appState: appState,
                        targetItem: route.item,
                        matchType: route.matchType,
                        visualQAInitialScreen: visualQAInitialScreen,
                        onCompletionAction: applyProposalCompletionRoute
                    )
                }
            } else if let route = directVisualQAProposalRoute {
                NavigationStack {
                    ProposalCreateFlow(
                        appState: appState,
                        targetItem: route.item,
                        matchType: route.matchType,
                        initialStep: visualQAProposalInitialStep,
                        visualQAInitialScreen: visualQAInitialScreen,
                        onCompletionAction: applyProposalCompletionRoute
                    )
                }
            } else if visualQAInitialScreen == .individualListings {
                NavigationStack {
                    IndividualListingsScreen(appState: appState)
                }
            } else if visualQAInitialScreen == .individualListingHaves {
                NavigationStack {
                    IndividualListingsScreen(
                        appState: appState,
                        initialEditorStep: .haves,
                        initiallyPresentsEditor: true
                    )
                }
            } else if let optionKind = visualQAIndividualListingOptionKind {
                NavigationStack {
                    IndividualListingsScreen(appState: appState, initialEditorOptionKind: optionKind)
                }
            } else if visualQAInitialScreen == .individualListingExchange {
                NavigationStack {
                    IndividualListingsScreen(
                        appState: appState,
                        initialEditorStep: .exchange,
                        initiallyPresentsEditor: true
                    )
                }
            } else if visualQAInitialScreen == .ownProfile {
                NavigationStack {
                    OwnProfileScreen(appState: appState)
                }
            } else if visualQAInitialScreen == .publicProfile {
                NavigationStack {
                    PublicUserProfileScreen(
                        appState: appState,
                        userID: NativePreviewData.partnerID,
                        adDisplayContext: adDisplayContext,
                        adPlacement: .publicProfileFooterBanner
                    )
                }
            } else if drawerPageDestination == .profile {
                NavigationStack {
                    OwnProfileScreen(appState: appState) {
                        drawerPageDestination = nil
                    }
                }
            } else if drawerPageDestination == .schedules {
                NavigationStack {
                    PersonalScheduleScreen(appState: appState) {
                        drawerPageDestination = nil
                    }
                }
            } else {
                authenticatedTabs
            }
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
        .sheet(item: $drawerDestination) { destination in
            drawerDestinationView(destination)
        }
        .sheet(item: $publicProfileRoute) { route in
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
                    HomeExchangeSettingsScreen()
                case .payment:
                    PaymentSettingsScreen(appState: appState)
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
            drawerDragTranslation: $drawerDragTranslation,
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

    private func syncRepositoryWithAuthSession() async {
        await authState.refreshSessionIfNeeded()
        await appState.replaceRepository(
            MegrumAppStateFactory.repository(authSession: authState.session)
        )
    }

    private func applyProposalCompletionRoute(_ action: ProposalCompletionAction) {
        let route = ProposalCompletionRouteResolver.resolve(action: action)
        requestedTradesStage = route.requestedTradesStage
        selectedTab = route.selectedTab
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
        interstitialAdRequest = AdInterstitialRequest(placement: placement)
    }

    @ViewBuilder
    private func drawerDestinationView(_ destination: AppDrawerDestination) -> some View {
        NavigationStack {
            switch destination {
            case .profile:
                OwnProfileScreen(appState: appState)
            case .notifications:
                NotificationCenterScreen(appState: appState) { tab in
                    selectedTab = tab
                    drawerDestination = nil
                } onOpenRouteIntent: { intent in
                    openNotificationRouteIntent(intent)
                }
            case .profileEdit:
                AccountSetupScreen(appState: appState, mode: .edit)
            case .oshiSettings:
                OshiSettingsScreen(appState: appState)
            case .schedules:
                PersonalScheduleScreen(appState: appState)
            case .paymentSettings:
                PaymentSettingsScreen(appState: appState)
            case .exchangeSettings:
                HomeExchangeSettingsScreen()
            case .settings:
                SettingsScreen(
                    appState: appState,
                    onOpenNotificationDestination: { tab in
                        selectedTab = tab
                        drawerDestination = nil
                    },
                    onOpenNotificationRouteIntent: { intent in
                        openNotificationRouteIntent(intent)
                    },
                    securityAuthState: authState,
                    onSignOut: {
                        await authState.signOut()
                        Task {
                            await appState.revokeRegisteredNativePushDeviceToken()
                        }
                        drawerDestination = nil
                    }
                )
            case .help:
                SettingsScreen(
                    appState: appState,
                    onOpenNotificationDestination: { tab in
                        selectedTab = tab
                        drawerDestination = nil
                    },
                    onOpenNotificationRouteIntent: { intent in
                        openNotificationRouteIntent(intent)
                    },
                    securityAuthState: authState,
                    onSignOut: {
                        await authState.signOut()
                        Task {
                            await appState.revokeRegisteredNativePushDeviceToken()
                        }
                        drawerDestination = nil
                    }
                )
            }
        }
    }

    @discardableResult
    private func openNotificationRouteIntent(_ intent: NotificationRouteIntent) -> Bool {
        selectedTab = intent.fallbackTab
        drawerDestination = nil

        switch intent {
        case .userProfile(let id), .userEvaluations(let id):
            guard let userID = UUID(uuidString: id) else {
                return true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                publicProfileRoute = PublicProfileRoute(userID: userID)
            }
        case .tab, .tradeDetail, .tradeEvidenceCapture, .tradeEvidenceApproval,
             .tradeEvaluation, .tradeAssistance, .disputeDetail,
             .meguriBoardThread, .meguriMessages, .unknown:
            break
        }
        return true
    }
}

private extension View {
    @ViewBuilder
    func rootVisualQAProposalPresentation<Content: View>(
        item: Binding<HomeRelationRoute?>,
        @ViewBuilder content: @escaping (HomeRelationRoute) -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, content: content)
        #else
        sheet(item: item, content: content)
        #endif
    }
}

private struct NativeLoadingScreen: View {
    var title: String

    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MegrumTheme.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }
}

private struct NativeLoadingFailureScreen: View {
    var title: String
    var message: String
    var onRetry: () async -> Void
    var onSignOut: () async -> Void

    @State private var isRetrying = false
    @State private var isSigningOut = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.orange)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(MegrumTheme.ink)
                Text(message)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MegrumTheme.muted)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                Button(action: retry) {
                    Label(isRetrying ? "再読み込み中" : "再読み込み", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(MegrumTheme.lavender)
                .disabled(isRetrying || isSigningOut)

                Button(role: .destructive, action: signOut) {
                    Label(isSigningOut ? "ログアウト中" : "ログアウトしてやり直す", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isRetrying || isSigningOut)
            }
            .controlSize(.large)
            .padding(.top, 6)
        }
        .padding(28)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MegrumTheme.canvas.ignoresSafeArea())
    }

    private func retry() {
        Task {
            isRetrying = true
            await onRetry()
            isRetrying = false
        }
    }

    private func signOut() {
        Task {
            isSigningOut = true
            await onSignOut()
            isSigningOut = false
        }
    }
}
