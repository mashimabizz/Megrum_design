import Foundation
import SwiftUI

@MainActor
struct MegrumRootDrawerDestinationSheet: View {
    @ObservedObject var appState: MegrumAppState
    @ObservedObject var authState: MegrumAuthState
    var destination: AppDrawerDestination
    @Binding var selectedTab: MegrumTab
    @Binding var drawerDestination: AppDrawerDestination?
    @Binding var publicProfileRoute: PublicProfileRoute?
    var onOpenRouteIntent: (NotificationRouteIntent) -> Void = { _ in }
    var onClose: () -> Void = {}

    var body: some View {
        switch destination {
        case .settings:
            settingsScreen
        case .help:
            NavigationStack {
                SettingsHelpScreen()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("閉じる", action: onClose)
                        }
                    }
            }
        default:
            NavigationStack {
                destinationContent
            }
        }
    }

    private var settingsScreen: some View {
        SettingsScreen(
            appState: appState,
            onOpenNotificationDestination: { tab in
                selectedTab = tab
                drawerDestination = nil
            },
            onOpenNotificationRouteIntent: { intent in
                openNotificationRouteIntent(intent)
            },
            onClose: onClose,
            onAccountDeletionCompleted: {
                selectedTab = .home
                drawerDestination = nil
            },
            securityAuthState: authState,
            onSignOut: signOut
        )
    }

    @ViewBuilder
    private var destinationContent: some View {
        switch destination {
        case .profile:
            OwnProfileScreen(appState: appState, onClose: onClose)
        case .notifications:
            NotificationCenterScreen(appState: appState) { tab in
                selectedTab = tab
                drawerDestination = nil
            } onOpenRouteIntent: { intent in
                openNotificationRouteIntent(intent)
            }
        case .profileEdit:
            OwnProfileScreen(appState: appState, onClose: onClose)
        case .oshiSettings:
            OshiSettingsScreen(appState: appState, onClose: onClose)
        case .schedules:
            PersonalScheduleScreen(appState: appState)
        case .paymentSettings:
            PaymentSettingsScreen(appState: appState, onClose: onClose)
        case .exchangeSettings:
            HomeExchangeSettingsScreen(appState: appState, individualListings: appState.listings, onClose: onClose)
        case .megrumPlus:
            SubscriptionSettingsScreen(appState: appState, onClose: onClose)
        case .settings, .help:
            EmptyView()
        }
    }

    @discardableResult
    private func openNotificationRouteIntent(_ intent: NotificationRouteIntent) -> Bool {
        onOpenRouteIntent(intent)
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
             .meguriBoardThread, .meguriMessages, .ownGroom, .unknown:
            break
        }
        return true
    }

    private func signOut() async {
        await authState.signOut()
        Task {
            await appState.revokeRegisteredNativePushDeviceToken()
        }
        drawerDestination = nil
    }
}
