import MegrumCore
import SwiftUI

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
        MegrumRootAuthenticatedContent(
            appState: appState,
            visualQAInitialScreen: visualQAInitialScreen,
            directVisualQARelationRoute: directVisualQARelationRoute,
            directVisualQAProposalRoute: directVisualQAProposalRoute,
            visualQAProposalInitialStep: visualQAProposalInitialStep,
            visualQAIndividualListingOptionKind: visualQAIndividualListingOptionKind,
            drawerPageDestination: drawerPageDestination,
            adDisplayContext: adDisplayContext,
            onRetryLoading: syncRepositoryWithAuthSession,
            onSignOutFromLoadingFailure: {
                await authState.signOut()
                Task {
                    await appState.revokeRegisteredNativePushDeviceToken()
                }
            },
            onReturnToLoginFromIncompleteAccount: {
                await authState.signOut()
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
            MegrumRootDrawerDestinationSheet(
                appState: appState,
                authState: authState,
                destination: destination,
                selectedTab: $selectedTab,
                drawerDestination: $drawerDestination,
                publicProfileRoute: $publicProfileRoute,
                onClose: dismiss
            )
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
                    HomeExchangeSettingsScreen(individualListings: appState.listings) {
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
}
