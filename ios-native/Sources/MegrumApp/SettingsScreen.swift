import MegrumCore
import MegrumDesign
import SwiftUI

@MainActor
struct SettingsScreen: View {
    @ObservedObject var appState: MegrumAppState
    var onOpenNotificationDestination: (MegrumTab) -> Void = { _ in }
    var onOpenNotificationRouteIntent: (NotificationRouteIntent) -> Bool = { _ in false }
    var onClose: (() -> Void)?
    var onAccountDeletionCompleted: () -> Void = {}
    var onSignOut: () async -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @StateObject private var securityAuthState: MegrumAuthState
    @State private var isSigningOut = false
    @State private var navigationPath: [SettingsEssentialRoute] = []

    init(
        appState: MegrumAppState,
        onOpenNotificationDestination: @escaping (MegrumTab) -> Void = { _ in },
        onOpenNotificationRouteIntent: @escaping (NotificationRouteIntent) -> Bool = { _ in false },
        onClose: (() -> Void)? = nil,
        onAccountDeletionCompleted: @escaping () -> Void = {},
        securityAuthState: MegrumAuthState? = nil,
        onSignOut: @escaping () async -> Void = {}
    ) {
        self.appState = appState
        self.onOpenNotificationDestination = onOpenNotificationDestination
        self.onOpenNotificationRouteIntent = onOpenNotificationRouteIntent
        self.onClose = onClose
        self.onAccountDeletionCompleted = onAccountDeletionCompleted
        self.onSignOut = onSignOut
        _securityAuthState = StateObject(wrappedValue: securityAuthState ?? MegrumAuthStateFactory.makeDefault())
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                SettingsPrimarySection(
                    appState: appState,
                    profileStatusText: profileStatusText,
                    notificationStatusText: notificationStatusText,
                    pushNotificationStatusText: pushNotificationStatusText,
                    addressStatusText: addressStatusText,
                    subscriptionStatusText: subscriptionStatusText,
                    onOpenRoute: openRoute,
                    onSetPushNotificationsEnabled: setPushNotificationsEnabled
                )

                SettingsSupportAccountSection(
                    isSigningOut: isSigningOut,
                    accountSummary: accountSummary,
                    loginSecuritySummary: loginSecuritySummary,
                    onOpenRoute: openRoute
                )

                SettingsDangerSection(
                    isSigningOut: isSigningOut,
                    onSignOut: startSignOut,
                    onRequestAccountDeletion: {
                        openRoute(.accountDeletion)
                    }
                )
            }
            .navigationTitle("設定")
            .megrumInlineNavigationTitle()
            .navigationDestination(for: SettingsEssentialRoute.self) { route in
                destination(for: route)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        closeSettings()
                    }
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

    private func openRoute(_ route: SettingsEssentialRoute) {
        navigationPath.append(route)
    }

    @ViewBuilder
    private func destination(for route: SettingsEssentialRoute) -> some View {
        switch route {
        case .profile:
            OwnProfileScreen(appState: appState)
        case .notifications:
            NotificationCenterScreen(appState: appState) { tab in
                closeSettings()
                onOpenNotificationDestination(tab)
            } onOpenRouteIntent: { intent in
                if onOpenNotificationRouteIntent(intent) {
                    closeSettings()
                    return true
                }
                return false
            }
        case .mobilePush:
            EmptyView()
        case .address:
            AddressSettingsScreen(appState: appState)
        case .payment:
            PaymentSettingsScreen(appState: appState)
        case .premium:
            SubscriptionSettingsScreen(appState: appState)
        case .blockedUsers:
            BlockedUsersScreen(appState: appState)
        case .privacy:
            PrivacySettingsScreen(appState: appState)
        case .loginSecurity:
            LoginSecuritySettingsScreen(
                authState: securityAuthState,
                isSigningOut: isSigningOut,
                accountSummary: accountSummary,
                onSignOut: {
                    await performSignOut(dismissSettings: true)
                }
            )
        case .help:
            SettingsHelpScreen()
        case .terms:
            LegalDocumentScreen(kind: .terms)
        case .privacyPolicy:
            LegalDocumentScreen(kind: .privacy)
        case .commerceDisclosure:
            LegalDocumentScreen(kind: .commerce)
        case .account:
            AccountOverviewScreen(appState: appState)
        case .accountDeletion:
            AccountDeletionScreen(appState: appState) {
                onAccountDeletionCompleted()
                closeSettings()
            }
        case .logout:
            EmptyView()
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
            closeSettings()
        }
    }

    private func closeSettings() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}
