import MegrumCore
import MegrumDesign
import SwiftUI

struct SubscriptionSettingsScreen: View {
    @ObservedObject var appState: MegrumAppState

    private var state: UserSubscriptionState {
        appState.subscriptionState
    }

    var body: some View {
        SubscriptionSettingsContent(
            state: state,
            isLoading: appState.isLoadingSubscriptionState,
            onReload: reloadSubscriptionState
        )
        .navigationTitle("Premium会員")
        .megrumInlineNavigationTitle()
        .task {
            await appState.loadSubscriptionState(reportsFailure: false)
        }
    }

    private func reloadSubscriptionState() {
        Task {
            await appState.loadSubscriptionState()
        }
    }
}
