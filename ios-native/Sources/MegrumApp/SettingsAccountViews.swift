import MegrumDesign
import SwiftUI

@MainActor
struct AccountOverviewScreen: View {
    @ObservedObject var appState: MegrumAppState

    private var summary: SettingsAccountSummary {
        SettingsAccountSummary(
            viewer: appState.viewer,
            pushNotificationsEnabled: appState.pushNotificationsEnabled,
            mailingAddress: appState.mailingAddress
        )
    }

    var body: some View {
        AccountOverviewContent(summary: summary)
        .navigationTitle("アカウント")
        .megrumInlineNavigationTitle()
        .task {
            await loadAccountOverviewSettings()
        }
    }

    private func loadAccountOverviewSettings() async {
        if appState.mailingAddress == nil {
            await appState.loadMailingAddress()
        }
        await appState.loadPushNotificationSetting()
    }
}
