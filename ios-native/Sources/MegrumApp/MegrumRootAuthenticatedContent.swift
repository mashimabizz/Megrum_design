import MegrumCore
import SwiftUI

@MainActor
struct MegrumRootAuthenticatedContent<AuthenticatedTabs: View>: View {
    @ObservedObject var appState: MegrumAppState
    var visualQAInitialScreen: VisualQAInitialScreen?
    var directVisualQARelationRoute: HomeRelationRoute?
    var directVisualQAProposalRoute: HomeRelationRoute?
    var visualQAProposalInitialStep: ProposalCreateStep
    var visualQAIndividualListingOptionKind: IndividualListingOptionKind?
    var drawerPageDestination: AppDrawerDestination?
    var adDisplayContext: AdDisplayContext
    var onRetryLoading: () async -> Void
    var onSignOutFromLoadingFailure: () async -> Void
    var onReturnToLoginFromIncompleteAccount: () async -> Void
    var onDismissDrawerPage: () -> Void
    var onProposalCompletionAction: (ProposalCompletionAction) -> Void
    var authenticatedTabs: () -> AuthenticatedTabs

    init(
        appState: MegrumAppState,
        visualQAInitialScreen: VisualQAInitialScreen?,
        directVisualQARelationRoute: HomeRelationRoute?,
        directVisualQAProposalRoute: HomeRelationRoute?,
        visualQAProposalInitialStep: ProposalCreateStep,
        visualQAIndividualListingOptionKind: IndividualListingOptionKind?,
        drawerPageDestination: AppDrawerDestination?,
        adDisplayContext: AdDisplayContext,
        onRetryLoading: @escaping () async -> Void,
        onSignOutFromLoadingFailure: @escaping () async -> Void,
        onReturnToLoginFromIncompleteAccount: @escaping () async -> Void,
        onDismissDrawerPage: @escaping () -> Void,
        onProposalCompletionAction: @escaping (ProposalCompletionAction) -> Void,
        @ViewBuilder authenticatedTabs: @escaping () -> AuthenticatedTabs
    ) {
        self.appState = appState
        self.visualQAInitialScreen = visualQAInitialScreen
        self.directVisualQARelationRoute = directVisualQARelationRoute
        self.directVisualQAProposalRoute = directVisualQAProposalRoute
        self.visualQAProposalInitialStep = visualQAProposalInitialStep
        self.visualQAIndividualListingOptionKind = visualQAIndividualListingOptionKind
        self.drawerPageDestination = drawerPageDestination
        self.adDisplayContext = adDisplayContext
        self.onRetryLoading = onRetryLoading
        self.onSignOutFromLoadingFailure = onSignOutFromLoadingFailure
        self.onReturnToLoginFromIncompleteAccount = onReturnToLoginFromIncompleteAccount
        self.onDismissDrawerPage = onDismissDrawerPage
        self.onProposalCompletionAction = onProposalCompletionAction
        self.authenticatedTabs = authenticatedTabs
    }

    var body: some View {
        Group {
            if appState.viewer == nil {
                loadingContent
            } else if visualQAInitialScreen == .accountSetup {
                NavigationStack {
                    AccountSetupScreen(appState: appState)
                }
            } else if AccountSetupSessionPolicy.shouldReturnToLogin(
                accountStatus: appState.viewer?.accountStatus,
                visualQAInitialScreen: visualQAInitialScreen
            ) {
                NativeLoadingScreen(title: "ログイン画面へ戻しています")
                    .task(id: appState.viewer?.accountStatus) {
                        await onReturnToLoginFromIncompleteAccount()
                    }
            } else if let route = directVisualQARelationRoute {
                NavigationStack {
                    MatchRelationScreen(
                        appState: appState,
                        targetItem: route.item,
                        matchType: route.matchType,
                        visualQAInitialScreen: visualQAInitialScreen,
                        onCompletionAction: onProposalCompletionAction
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
                        onCompletionAction: onProposalCompletionAction
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
                    OwnProfileScreen(appState: appState, onClose: onDismissDrawerPage)
                }
            } else if drawerPageDestination == .schedules {
                NavigationStack {
                    PersonalScheduleScreen(appState: appState, onClose: onDismissDrawerPage)
                }
            } else {
                authenticatedTabs()
            }
        }
    }

    @ViewBuilder
    private var loadingContent: some View {
        if let errorMessage = appState.errorMessage {
            NativeLoadingFailureScreen(
                title: "Megrumを読み込めませんでした",
                message: errorMessage,
                onRetry: onRetryLoading,
                onSignOut: onSignOutFromLoadingFailure
            )
        } else {
            NativeLoadingScreen(title: "Megrumを読み込んでいます")
        }
    }
}
