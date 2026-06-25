import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct SettingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onOpenNotificationDestination: (MegrumTab) -> Void = { _ in }
    var onOpenNotificationRouteIntent: (NotificationRouteIntent) -> Bool = { _ in false }
    var onSignOut: () async -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @StateObject private var securityAuthState: MegrumAuthState
    @State private var isSigningOut = false

    init(
        appState: MegrumAppState,
        onOpenNotificationDestination: @escaping (MegrumTab) -> Void = { _ in },
        onOpenNotificationRouteIntent: @escaping (NotificationRouteIntent) -> Bool = { _ in false },
        securityAuthState: MegrumAuthState? = nil,
        onSignOut: @escaping () async -> Void = {}
    ) {
        self.appState = appState
        self.onOpenNotificationDestination = onOpenNotificationDestination
        self.onOpenNotificationRouteIntent = onOpenNotificationRouteIntent
        self.onSignOut = onSignOut
        _securityAuthState = StateObject(wrappedValue: securityAuthState ?? MegrumAuthStateFactory.makeDefault())
    }

    var body: some View {
        List {
            SettingsPrimarySection(
                appState: appState,
                profileStatusText: profileStatusText,
                notificationStatusText: notificationStatusText,
                pushNotificationStatusText: pushNotificationStatusText,
                addressStatusText: addressStatusText,
                subscriptionStatusText: subscriptionStatusText,
                onOpenNotificationDestination: onOpenNotificationDestination,
                onOpenNotificationRouteIntent: onOpenNotificationRouteIntent,
                onSetPushNotificationsEnabled: setPushNotificationsEnabled
            )

            SettingsSupportAccountSection(
                appState: appState,
                securityAuthState: securityAuthState,
                isSigningOut: isSigningOut,
                accountSummary: accountSummary,
                loginSecuritySummary: loginSecuritySummary,
                onSignOut: {
                    await performSignOut(dismissSettings: true)
                }
            )

            SettingsDangerSection(
                isSigningOut: isSigningOut,
                onSignOut: startSignOut
            )
        }
        .navigationTitle("設定")
        .megrumInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .task {
            await loadInitialSettingsData()
        }
    }

    private var notificationStatusText: String {
        guard !appState.notifications.isEmpty else {
            return "未読なし"
        }
        if appState.unreadNotificationCount > 0 {
            return "未読 \(appState.unreadNotificationCount)件"
        }
        return "すべて既読"
    }

    private var pushNotificationStatusText: String {
        appState.pushNotificationsEnabled ? "端末に通知を届ける" : "端末通知はOFF"
    }

    private var profileStatusText: String {
        guard let viewer = appState.viewer else {
            return "未読み込み"
        }
        if let prefecture = viewer.prefecture, !prefecture.isEmpty {
            return "\(viewer.displayName) / \(prefecture)"
        }
        return viewer.displayName
    }

    private var addressStatusText: String {
        guard let address = appState.mailingAddress, address.isReady else {
            return "未登録"
        }
        return address.summary
    }

    private var subscriptionStatusText: String {
        appState.subscriptionState.isPremiumActive ? "有効" : "未加入"
    }

    private var accountSummary: SettingsAccountSummary {
        SettingsAccountSummary(
            viewer: appState.viewer,
            pushNotificationsEnabled: appState.pushNotificationsEnabled,
            mailingAddress: appState.mailingAddress
        )
    }

    private var loginSecuritySummary: LoginSecuritySummary {
        LoginSecuritySummary(
            authSession: securityAuthState.session,
            isAuthenticated: securityAuthState.isAuthenticated,
            isAuthConfigured: securityAuthState.isConfigured,
            accountSummary: accountSummary
        )
    }

    private func startSignOut() {
        Task {
            await performSignOut(dismissSettings: true)
        }
    }

    private func setPushNotificationsEnabled(_ enabled: Bool) {
        Task {
            await appState.setPushNotificationsEnabled(enabled)
        }
    }

    private func loadInitialSettingsData() async {
        if appState.mailingAddress == nil {
            await appState.loadMailingAddress()
        }
        if appState.notifications.isEmpty {
            await appState.loadNotifications()
        }
        await appState.loadPushNotificationSetting()
        await appState.loadSubscriptionState(reportsFailure: false)
    }

    private func performSignOut(dismissSettings: Bool) async {
        guard !isSigningOut else {
            return
        }

        isSigningOut = true
        await onSignOut()
        isSigningOut = false

        if dismissSettings {
            dismiss()
        }
    }
}
