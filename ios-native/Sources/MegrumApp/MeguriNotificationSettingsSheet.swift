import MegrumCore
import MegrumDesign
import SwiftUI

/// めぐり地図の通知アイコンから開く、グルーム/チャットルームの通知設定。
/// 反応の通知（既存設定）に加えて、推し一致・圏内の新着投稿の購読を切り替える。
struct MeguriNotificationSettingsSheet: View {
    @ObservedObject var appState: MegrumAppState
    var currentCoordinate: MegrumLocationCoordinate?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                Toggle("いいね・コメントの通知", isOn: groomActivityBinding)
                Toggle("圏内の推しグルーム通知", isOn: groomOshiNearbyMasterBinding)
                if appState.groomOshiPushNotificationsEnabled {
                    NavigationLink {
                        MeguriGroomOshiNotifySettingsScreen(appState: appState)
                    } label: {
                        Text("推しごとの通知設定")
                    }
                }
            } header: {
                Text("グルーム")
            } footer: {
                Text("最後にめぐりを開いた場所から約3km以内で、自分の推し（グループ・メンバー）に一致する新着グルームを通知します。")
            }

            Section {
                Toggle("返信・メンションの通知", isOn: chatroomActivityBinding)
                Toggle("推しの新着チャットルーム", isOn: subscriptionBinding(\.chatroomOshiPushEnabled))
                Toggle("圏内の新着チャットルーム", isOn: subscriptionBinding(\.chatroomNearbyPushEnabled))
            } header: {
                Text("チャットルーム")
            } footer: {
                Text("圏内は最後にめぐりを開いた場所から約3km以内の投稿が対象です。")
            }

            if !appState.pushNotificationsEnabled {
                Section {
                    Label("モバイル通知がオフのため、通知は届きません。設定から有効にできます。", systemImage: "bell.slash")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MegrumTheme.muted)
                }
            }
        }
        .tint(MegrumTheme.lavender)
        .navigationTitle("めぐりの通知")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .task {
            await appState.loadPushNotificationSetting()
        }
    }

    private var groomActivityBinding: Binding<Bool> {
        Binding(
            get: { appState.groomActivityPushNotificationsEnabled },
            set: { enabled in
                Task {
                    await appState.setGroomActivityPushNotificationsEnabled(enabled)
                }
            }
        )
    }

    private var chatroomActivityBinding: Binding<Bool> {
        Binding(
            get: { appState.chatroomActivityPushNotificationsEnabled },
            set: { enabled in
                Task {
                    await appState.setChatroomActivityPushNotificationsEnabled(enabled)
                }
            }
        )
    }

    /// FB8-7: グルーム通知の親スイッチ（圏内 かつ 同一推し）。有効化時は今の位置を基準位置として保存する。iter1226.388。
    private var groomOshiNearbyMasterBinding: Binding<Bool> {
        Binding(
            get: { appState.groomOshiPushNotificationsEnabled },
            set: { enabled in
                var next = currentSubscriptionSettings
                next.groomOshiPushEnabled = enabled
                Task {
                    let saved = await appState.setMeguriSubscriptionPushSettings(next)
                    if saved, enabled, let coordinate = currentCoordinate {
                        await appState.updatePushNotificationLocationIfNeeded(
                            latitude: coordinate.latitude,
                            longitude: coordinate.longitude
                        )
                    }
                }
            }
        )
    }

    private func subscriptionBinding(
        _ keyPath: WritableKeyPath<MeguriSubscriptionPushSettingsInput, Bool> & Sendable
    ) -> Binding<Bool> {
        let isNearbyToggle = keyPath == \.groomNearbyPushEnabled || keyPath == \.chatroomNearbyPushEnabled
        return Binding(
            get: { currentSubscriptionSettings[keyPath: keyPath] },
            set: { enabled in
                var next = currentSubscriptionSettings
                next[keyPath: keyPath] = enabled
                Task {
                    let saved = await appState.setMeguriSubscriptionPushSettings(next)
                    // 圏内通知を有効にした直後は、今の位置を基準位置として保存する。
                    if saved, enabled, isNearbyToggle, let coordinate = currentCoordinate {
                        await appState.updatePushNotificationLocationIfNeeded(
                            latitude: coordinate.latitude,
                            longitude: coordinate.longitude
                        )
                    }
                }
            }
        )
    }

    private var currentSubscriptionSettings: MeguriSubscriptionPushSettingsInput {
        MeguriSubscriptionPushSettingsInput(
            groomOshiPushEnabled: appState.groomOshiPushNotificationsEnabled,
            groomNearbyPushEnabled: appState.groomNearbyPushNotificationsEnabled,
            chatroomOshiPushEnabled: appState.chatroomOshiPushNotificationsEnabled,
            chatroomNearbyPushEnabled: appState.chatroomNearbyPushNotificationsEnabled
        )
    }
}
