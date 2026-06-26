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
    var onClose: () -> Void = {}

    var body: some View {
        NavigationStack {
            destinationContent
        }
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
            AccountSetupScreen(appState: appState, mode: .edit)
        case .oshiSettings:
            OshiSettingsScreen(appState: appState)
        case .schedules:
            PersonalScheduleScreen(appState: appState)
        case .paymentSettings:
            PaymentSettingsScreen(appState: appState, onClose: onClose)
        case .exchangeSettings:
            HomeExchangeSettingsScreen(individualListings: appState.listings)
        case .settings, .help:
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
                onSignOut: signOut
            )
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

    private func signOut() async {
        await authState.signOut()
        Task {
            await appState.revokeRegisteredNativePushDeviceToken()
        }
        drawerDestination = nil
    }
}
