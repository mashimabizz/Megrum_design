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
        List {
            Section {
                SettingsValueRow(title: "アカウントID", value: summary.userIDText, isMonospaced: true)
                SettingsValueRow(title: "ユーザーID", value: summary.handleText)
                SettingsValueRow(title: "表示名", value: summary.displayNameText)
                SettingsValueRow(title: "活動エリア", value: summary.activityAreaText)
                SettingsValueRow(title: "支払い条件", value: summary.paymentMethodsText)
                SettingsValueRow(title: "アカウント状態", value: summary.accountStatusText)
            } header: {
                Text("基本情報")
            }

            Section {
                SettingsValueRow(title: "モバイル通知", value: summary.pushNotificationText)
                SettingsValueRow(title: "住所登録", value: summary.addressStatusText)
            } header: {
                Text("設定状態")
            }
        }
        .navigationTitle("アカウント")
        .megrumInlineNavigationTitle()
        .task {
            if appState.mailingAddress == nil {
                await appState.loadMailingAddress()
            }
            await appState.loadPushNotificationSetting()
        }
    }
}

struct SettingsValueRow: View {
    var title: String
    var value: String
    var isMonospaced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MegrumTheme.muted)
            Text(value)
                .font(isMonospaced ? .body.monospaced() : .body)
                .foregroundStyle(MegrumTheme.ink)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)、\(value)")
    }
}
